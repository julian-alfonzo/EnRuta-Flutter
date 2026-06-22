# API EnRuta — Especificación de Endpoints

## Base URL

```
https://api.enruta.app/v1
```

## Autenticación

Todos los endpoints (excepto login y refresh) requieren header:

```
Authorization: Bearer <jwt_token>
```

| Método | Endpoint | Body | Response |
|---|---|---|---|
| `POST` | `/auth/login` | `{ "usuario": "string", "password": "string" }` | `{ "accessToken": "string", "refreshToken": "string", "expiresIn": 3600 }` |
| `POST` | `/auth/refresh` | `{ "refreshToken": "string" }` | `{ "accessToken": "string", "expiresIn": 3600 }` |

### Errores de autenticación

| Código | Mensaje |
|---|---|
| `401` | Token inválido o expirado |
| `403` | Permisos insuficientes |

---

## Agentes

### Modelo

```json
{
  "id": 1,
  "legajo": "58318",
  "apellidoNombre": "Castillo Claudio Damian",
  "fechaIngreso": "02/03/20",
  "dependencia": "APOYO E INVESTIGACION POLICIAL",
  "cargo": "SUPERVISOR",
  "turno": "ROTATIVO",
  "createdAt": "2026-06-21T10:00:00Z",
  "updatedAt": "2026-06-21T10:00:00Z"
}
```

### Endpoints

| Método | Endpoint | Query Params | Body | Response |
|---|---|---|---|---|
| `GET` | `/agentes` | `?search=castillo` `?page=1&limit=20` | — | `{ "data": [Agente], "total": 635, "page": 1, "limit": 20 }` |
| `GET` | `/agentes/:id` | — | — | `Agente` |
| `GET` | `/agentes/legajo/:legajo` | — | — | `Agente` |
| `POST` | `/agentes` | — | Agente (sin id, createdAt, updatedAt) | `Agente` creado |
| `PUT` | `/agentes/:id` | — | Agente completo | `Agente` actualizado |
| `DELETE` | `/agentes/:id` | — | — | `{ "deleted": true }` |

### Validaciones

- `legajo`: requerido, único, string numérico, máximo 20 caracteres
- `apellidoNombre`: requerido, máximo 200 caracteres
- `fechaIngreso`: formato `dd/mm/aa`
- `turno`: valores aceptados: `ROTATIVO`, `MAÑANA`, `TARDE`, `NOCHE`, `FIJO`

### Reglas de negocio

- No se puede eliminar un agente si tiene controles de alcoholemia u observaciones asociadas (ON DELETE RESTRICT con opción de soft-delete)
- El `legajo` es inmutable una vez creado

---

## Controles de Alcoholemia

### Modelo

```json
{
  "id": 1,
  "agenteId": 1,
  "agente": {
    "legajo": "58318",
    "apellidoNombre": "Castillo Claudio Damian"
  },
  "fecha": "2026-06-21",
  "resultado": "Positivo",
  "graduacion": 0.85,
  "servicioExtra": "Hora extra",
  "observacion": "Control de rutina en operativo nocturno",
  "createdAt": "2026-06-21T22:30:00Z"
}
```

### Endpoints

| Método | Endpoint | Query Params | Body | Response |
|---|---|---|---|---|
| `GET` | `/agentes/:agenteId/alcoholemias` | — | — | `[ControlAlcoholemia]` |
| `GET` | `/alcoholemias` | `?fecha=2026-06-21` `?desde=2026-06-01&hasta=2026-06-30` | — | `[ControlAlcoholemia]` |
| `GET` | `/alcoholemias/reporte` | `?desde=2026-06-01&hasta=2026-06-30` | — | `[ControlAlcoholemiaConAgente]` |
| `POST` | `/agentes/:agenteId/alcoholemias` | — | ControlAlcoholemia (sin id, sin createdAt) | ControlAlcoholemia creado |
| `PUT` | `/alcoholemias/:id` | — | ControlAlcoholemia completo | ControlAlcoholemia actualizado |
| `DELETE` | `/alcoholemias/:id` | — | — | `{ "deleted": true }` |

### Validaciones

- `resultado`: requerido, valores: `Positivo` o `Negativo`
- `graduacion`: requerido **solo si** `resultado = Positivo`. Decimal positivo entre `0.01` y `9.99` g/l
- `servicioExtra`: valores aceptados: `Cumpliendo servicio`, `Hora extra`
- `fecha`: requerido, formato `YYYY-MM-DD`

### Reglas de negocio

- Si `resultado = Negativo`, `graduacion` debe ser `null`
- El endpoint `/alcoholemias/reporte` devuelve el JOIN con datos del agente (legajo, apellidoNombre)

---

## Observaciones / Reclamos

### Modelo

```json
{
  "id": 1,
  "agenteId": 1,
  "agente": {
    "legajo": "58318",
    "apellidoNombre": "Castillo Claudio Damian",
    "dependencia": "APOYO E INVESTIGACION POLICIAL",
    "cargo": "SUPERVISOR"
  },
  "tipo": "Reclamo",
  "descripcion": "Falta de documentación en el vehículo asignado",
  "fecha": "2026-06-21",
  "resuelto": false,
  "createdAt": "2026-06-21T14:15:00Z"
}
```

### Endpoints

| Método | Endpoint | Query Params | Body | Response |
|---|---|---|---|---|
| `GET` | `/agentes/:agenteId/observaciones` | — | — | `[ObservacionReclamo]` |
| `GET` | `/agentes/:agenteId/observaciones/reporte` | — | — | `[ObservacionReclamoConAgente]` |
| `POST` | `/agentes/:agenteId/observaciones` | — | ObservacionReclamo (sin id, sin createdAt) | ObservacionReclamo creada |
| `PUT` | `/observaciones/:id` | — | ObservacionReclamo completo | ObservacionReclamo actualizada |
| `DELETE` | `/observaciones/:id` | — | — | `{ "deleted": true }` |

### Validaciones

- `tipo`: requerido, valores: `Observación` o `Reclamo`
- `descripcion`: requerido, máximo 2000 caracteres
- `fecha`: requerido, formato `YYYY-MM-DD`
- `resuelto`: booleano, por defecto `false`

---

## Sincronización (offline-first)

Para soportar el modo offline con SQLite local y sincronización bidireccional:

| Método | Endpoint | Body | Response |
|---|---|---|---|
| `POST` | `/sync/pull` | `{ "lastSync": "2026-06-20T10:00:00Z" }` | `{ "agentes": [...], "alcoholemias": [...], "observaciones": [...], "deleted": { "agentes": [...], "alcoholemias": [...], "observaciones": [...] }, "serverTime": "2026-06-21T22:00:00Z" }` |
| `POST` | `/sync/push` | `{ "agentes": { "created": [...], "updated": [...] }, "alcoholemias": { "created": [...], "updated": [...] }, "observaciones": { "created": [...], "updated": [...] }, "lastLocalId": 12345 }` | `{ "conflicts": [...], "serverIds": { "agentes": { "localId": "serverId" }, ... } }` |

### Lógica de sincronización

- Cada registro tiene `createdAt` y `updatedAt` en UTC
- `pull`: el servidor devuelve todos los registros modificados después de `lastSync`
- `push`: el cliente envía los cambios locales desde la última sincronización exitosa
- Conflictos: última escritura gana (`updatedAt`), el servidor devuelve los registros en conflicto
- IDs locales (SQLite) se mapean a IDs del servidor en la respuesta del push

---

## Formato de respuestas

### Éxito

```json
{
  "data": { ... },
  "meta": {
    "total": 635,
    "page": 1,
    "limit": 20
  }
}
```

### Error

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "El legajo es obligatorio",
    "details": [
      { "field": "legajo", "message": "El legajo es obligatorio" }
    ]
  }
}
```

### Códigos de error HTTP

| Código | Uso |
|---|---|
| `200` | OK (GET, PUT) |
| `201` | Creado (POST) |
| `204` | Sin contenido (DELETE exitoso) |
| `400` | Error de validación |
| `401` | No autenticado |
| `403` | No autorizado |
| `404` | Recurso no encontrado |
| `409` | Conflicto (legajo duplicado) |
| `500` | Error interno |

---

## Estructura de base de datos (PostgreSQL / MySQL)

### Tabla `agentes`

| Columna | Tipo | Constraints |
|---|---|---|
| `id` | `SERIAL` / `INT AUTO_INCREMENT` | `PRIMARY KEY` |
| `legajo` | `VARCHAR(20)` | `UNIQUE NOT NULL` |
| `apellido_nombre` | `VARCHAR(200)` | `NOT NULL` |
| `fecha_ingreso` | `VARCHAR(10)` | — |
| `dependencia` | `VARCHAR(200)` | — |
| `cargo` | `VARCHAR(200)` | — |
| `turno` | `VARCHAR(50)` | — |
| `created_at` | `TIMESTAMPTZ` / `DATETIME` | `DEFAULT NOW()` |
| `updated_at` | `TIMESTAMPTZ` / `DATETIME` | `DEFAULT NOW()` |
| `deleted_at` | `TIMESTAMPTZ` / `DATETIME` | `NULL` (soft delete) |

Índices: `legajo` (UNIQUE), `apellido_nombre`, `dependencia`

### Tabla `controles_alcoholemia`

| Columna | Tipo | Constraints |
|---|---|---|
| `id` | `SERIAL` / `INT AUTO_INCREMENT` | `PRIMARY KEY` |
| `agente_id` | `INTEGER` | `FOREIGN KEY REFERENCES agentes(id)` |
| `fecha` | `DATE` | `NOT NULL` |
| `resultado` | `VARCHAR(20)` | `NOT NULL` |
| `graduacion` | `DECIMAL(4,2)` | `NULL` |
| `servicio_extra` | `VARCHAR(50)` | — |
| `observacion` | `TEXT` | — |
| `created_at` | `TIMESTAMPTZ` / `DATETIME` | `DEFAULT NOW()` |

Índices: `(agente_id, fecha)`, `fecha`

### Tabla `observaciones_reclamos`

| Columna | Tipo | Constraints |
|---|---|---|
| `id` | `SERIAL` / `INT AUTO_INCREMENT` | `PRIMARY KEY` |
| `agente_id` | `INTEGER` | `FOREIGN KEY REFERENCES agentes(id)` |
| `tipo` | `VARCHAR(50)` | `NOT NULL` |
| `descripcion` | `TEXT` | `NOT NULL` |
| `fecha` | `DATE` | `NOT NULL` |
| `resuelto` | `BOOLEAN` / `TINYINT(1)` | `DEFAULT FALSE` |
| `created_at` | `TIMESTAMPTZ` / `DATETIME` | `DEFAULT NOW()` |

Índices: `agente_id`

---

## Stack sugerido

| Capa | Tecnología |
|---|---|
| **Backend** | Node.js (Express / Fastify) o Spring Boot (Java/Kotlin) |
| **Base de datos** | PostgreSQL 16+ |
| **Autenticación** | JWT (access + refresh tokens) |
| **Cache** | Redis (opcional, para rate limiting y sesiones) |
| **Documentación** | Swagger / OpenAPI 3.0 |
| **Hosting** | AWS (RDS + EC2/ECS) o VPS con Docker |

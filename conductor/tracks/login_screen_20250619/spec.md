# Track: Implementar Login Screen con Sistema de Colores

## Overview
Implementar una pantalla de inicio de sesión con estilo moderno-minimalista (estilo banca móvil), utilizando la paleta de colores MSM parametrizada. Incluye un botón de acceso rápido para desarrolladores.

## Paleta de Colores (MSM)
| Color | Hex | Uso |
|-------|-----|-----|
| Primary | `#05C7F2` | Botones, acentos |
| Secondary | `#80DDF2` | Bordes, indicadores |
| Tertiary | `#BBE8F2` | Fondos de campos |
| Surface | `#F2F2F2` | Fondo general |
| On Surface | `#0D0D0D` | Texto principal |

## Sistema de Colores
- Definidos en `app_theme.dart` usando `ThemeData`
- Fácil modificación (un solo archivo)
- `useMaterial3: true`

## Functional Requirements
### Login Screen
- Campos: Usuario y Contraseña (con iconos y placeholder)
- Botón "Iniciar Sesión"
- Diseño centrado, minimalista, estilo banca

### Botón Acceso Dev
- Botón secundario al pie
- Texto "Acceso Dev"
- Auto-fill + login automático al tocarlo

### Validación (Mock)
- Credenciales: `admin` / `admin123`
- Correctas → navegar a Home
- Incorrectas → mostrar error (SnackBar)

### Home Screen
- "Bienvenido, {usuario}"
- Botón "Cerrar Sesión"

## Acceptance Criteria
1. Login con 2 inputs + botón login + botón dev
2. Credenciales correctas → Home con bienvenida
3. Credenciales incorrectas → error visible
4. Botón dev → auto-fill + login automático
5. Colores aplicados según paleta MSM
6. `flutter analyze` sin errores
7. Al menos 1 test widget

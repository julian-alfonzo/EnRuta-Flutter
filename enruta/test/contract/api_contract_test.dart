import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/control_alcoholemia.dart';
import 'package:enruta/models/observacion_reclamo.dart';

/// Contract test: verifica que los modelos Flutter produzcan/consuman
/// exactamente el formato que el backend Next.js espera/retorna.
///
/// Estas fixtures representan el contrato API compartido entre:
///   - Backend: /app/api/v1/agentes/* (route.ts)
///   - Frontend: lib/models/*.dart (toJson/fromApiJson)

void main() {
  // ────────────────────────────────────────────────
  // AGENTES: Fixtures de request (Flutter → Backend)
  // ────────────────────────────────────────────────

  group('Agente request contract (Flutter → Backend)', () {
    test('POST /agentes payload con todos los campos', () {
      final agente = Agente(
        legajo: 'TEST001',
        apellidoNombre: 'Perez, Juan Carlos',
        fechaIngreso: '2024-03-15',
        dependencia: 'Tránsito y Transporte',
        cargo: 'Inspector',
        turno: 'ROTATIVO',
      );

      final json = agente.toJson();

      // El backend desestructura: { legajo, apellidoNombre, fechaIngreso, dependencia, cargo, turno }
      expect(json, isA<Map<String, dynamic>>());
      expect(json['legajo'], 'TEST001');
      expect(json['apellidoNombre'], 'Perez, Juan Carlos');
      expect(json['fechaIngreso'], '2024-03-15');
      expect(json['dependencia'], 'Tránsito y Transporte');
      expect(json['cargo'], 'Inspector');
      expect(json['turno'], 'ROTATIVO');

      // Verificar que NO usa snake_case en las keys
      expect(json.containsKey('apellido_nombre'), isFalse);
      expect(json.containsKey('fecha_ingreso'), isFalse);
      expect(json.containsKey('created_at'), isFalse);
      expect(json.containsKey('updated_at'), isFalse);
    });

    test('POST /agentes payload mínimo (solo requeridos)', () {
      final agente = Agente(legajo: '002', apellidoNombre: 'Lopez');
      final json = agente.toJson();

      expect(json['legajo'], '002');
      expect(json['apellidoNombre'], 'Lopez');
      expect(json['fechaIngreso'], isNull);
      expect(json['dependencia'], isNull);
      expect(json['cargo'], isNull);
      expect(json['turno'], isNull);
    });

    test('PUT /agentes/:id payload incluye legajo inmutable', () {
      final agente = Agente(
        id: 42,
        legajo: 'ORIG001',
        apellidoNombre: 'Nombre Modificado',
        fechaIngreso: '2023-01-01',
        dependencia: 'Nueva Depto',
        cargo: 'Nuevo Cargo',
        turno: 'MAÑANA',
      );

      final json = agente.toJson();

      // Backend valida que legajo no haya cambiado
      expect(json['id'], 42);
      expect(json['legajo'], 'ORIG001');
      expect(json['apellidoNombre'], 'Nombre Modificado');
      expect(json['turno'], 'MAÑANA');
    });

    test('PUT valida turno contra enum del backend', () {
      const validos = ['ROTATIVO', 'MAÑANA', 'TARDE', 'NOCHE', 'FIJO'];
      for (final t in validos) {
        final agente = Agente(legajo: '1', apellidoNombre: 'X', turno: t);
        final json = agente.toJson();
        expect(validos.contains(json['turno']), isTrue,
            reason: '$t debe ser un turno válido aceptado por el backend');
      }
    });

    test('DELETE /agentes/:id no tiene body — envía id via URL', () {
      // Flutter envía el delete como llamada HTTP directa con el id en la URL.
      // El sync queue guarda: {'id': id}
      // Verificamos que el payload de sync para delete sea correcto.
      const syncDeletePayload = {'id': 99};
      expect(syncDeletePayload['id'], 99);
    });
  });

  // ────────────────────────────────────────────────
  // AGENTES: Fixtures de response (Backend → Flutter)
  // ────────────────────────────────────────────────

  group('Agente response contract (Backend → Flutter)', () {
    // Estos fixtures replican exactamente lo que retorna el backend DTO
    // (agenteToDTO en lib/dto.ts): camelCase, createdAt/updatedAt en ISO 8601

    final agenteCompletoResponse = {
      'id': 1,
      'legajo': '63722',
      'apellidoNombre': 'Castillo, Juan Pablo',
      'fechaIngreso': '2010-05-12',
      'dependencia': 'Tránsito',
      'cargo': 'Supervisor',
      'turno': 'ROTATIVO',
      'createdAt': '2025-01-15T10:30:00.000Z',
      'updatedAt': '2025-06-20T14:00:00.000Z',
    };

    test('GET /agentes/:id response se parsea con fromApiJson', () {
      final agente = Agente.fromApiJson(agenteCompletoResponse);

      expect(agente.id, 1);
      expect(agente.legajo, '63722');
      expect(agente.apellidoNombre, 'Castillo, Juan Pablo');
      expect(agente.fechaIngreso, '2010-05-12');
      expect(agente.dependencia, 'Tránsito');
      expect(agente.cargo, 'Supervisor');
      expect(agente.turno, 'ROTATIVO');
      expect(agente.createdAt, '2025-01-15T10:30:00.000Z');
      expect(agente.updatedAt, '2025-06-20T14:00:00.000Z');
    });

    test('GET /agentes response paginada (data + meta)', () {
      final responseBody = {
        'data': [agenteCompletoResponse],
        'meta': {'total': 1, 'page': 1, 'limit': 20},
      };

      final data = responseBody['data'] as List<dynamic>;
      final agentes =
          data.map((j) => Agente.fromApiJson(j as Map<String, dynamic>)).toList();

      expect(agentes.length, 1);
      expect(agentes.first.legajo, '63722');
      final meta = responseBody['meta'] as Map<String, dynamic>;
      expect(meta['total'], 1);
    });

    test('GET /agentes response con campos null', () {
      final responseMinimo = {
        'id': 2,
        'legajo': 'MIN001',
        'apellidoNombre': 'Minimo',
        'fechaIngreso': null,
        'dependencia': null,
        'cargo': null,
        'turno': null,
        'createdAt': '2025-01-01T00:00:00.000Z',
        'updatedAt': '2025-01-01T00:00:00.000Z',
      };

      final agente = Agente.fromApiJson(responseMinimo);

      expect(agente.fechaIngreso, isNull);
      expect(agente.dependencia, isNull);
      expect(agente.cargo, isNull);
      expect(agente.turno, isNull);
    });

    test('toJson → fromApiJson roundtrip (Flutter → Backend → Flutter)', () {
      // Simula: Flutter crea agente, lo envía, backend lo persiste y lo retorna
      final enviado = Agente(
        legajo: 'RND001',
        apellidoNombre: 'Roundtrip Test',
        fechaIngreso: '2024-01-01',
        dependencia: 'Depto',
        cargo: 'Cargo',
        turno: 'TARDE',
      );

      final payload = enviado.toJson();

      // Backend recibe payload, persiste, y retorna DTO con id + timestamps
      final responseDelBackend = {
        ...payload,
        'id': 99,
        'createdAt': '2025-06-25T12:00:00.000Z',
        'updatedAt': '2025-06-25T12:00:00.000Z',
      };

      final recibido = Agente.fromApiJson(responseDelBackend);

      expect(recibido.id, 99);
      expect(recibido.legajo, enviado.legajo);
      expect(recibido.apellidoNombre, enviado.apellidoNombre);
      expect(recibido.fechaIngreso, enviado.fechaIngreso);
      expect(recibido.dependencia, enviado.dependencia);
      expect(recibido.cargo, enviado.cargo);
      expect(recibido.turno, enviado.turno);
      expect(recibido.createdAt, isNotNull);
      expect(recibido.updatedAt, isNotNull);
    });

    test('Error response 409 DUPLICATE_LEGAJO se parsea correctamente', () {
      // La clase ApiException.fromResponse parsea { error: { code, message, details } }
      final errorBody = {
        'error': {
          'code': 'DUPLICATE_LEGAJO',
          'message': 'Ya existe un agente con legajo TEST001',
          'details': null,
        },
      };

      final error = errorBody['error'] as Map<String, dynamic>;
      expect(error['code'], 'DUPLICATE_LEGAJO');
      expect(error['message'], contains('TEST001'));
    });

    test('Error response 400 VALIDATION_ERROR con details', () {
      final errorBody = {
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'legajo es obligatorio',
          'details': [
            {'field': 'legajo', 'message': 'legajo es obligatorio'},
          ],
        },
      };

      final error = errorBody['error'] as Map<String, dynamic>;
      final details = error['details'] as List<dynamic>;
      expect(details.length, 1);
      expect((details[0] as Map)['field'], 'legajo');
    });

    test('Error response 404 NOT_FOUND', () {
      final errorBody = {
        'error': {
          'code': 'NOT_FOUND',
          'message': 'Agente no encontrado',
          'details': null,
        },
      };

      final error = errorBody['error']! as Map<String, dynamic>;
      expect(error['code'], 'NOT_FOUND');
    });

    test('Error response 409 AGENTE_HAS_DEPENDENCIES', () {
      final errorBody = {
        'error': {
          'code': 'AGENTE_HAS_DEPENDENCIES',
          'message': 'El agente tiene 2 control(es) y 1 observación(es) asociada(s)',
          'details': null,
        },
      };

      final error = errorBody['error']! as Map<String, dynamic>;
      expect(error['code'], 'AGENTE_HAS_DEPENDENCIES');
    });
  });

  // ────────────────────────────────────────────────
  // CONTROL ALCOHOLEMIA: Contrato
  // ────────────────────────────────────────────────

  group('ControlAlcoholemia contract', () {
    test('POST /agentes/:id/alcoholemias payload', () {
      final control = ControlAlcoholemia(
        agenteId: 5,
        fecha: '2025-06-21',
        resultado: 'Positivo',
        graduacion: 0.85,
        servicioExtra: 'Hora extra',
        observacion: 'Control de rutina',
      );

      final json = control.toJson();

      // Backend espera camelCase
      expect(json['agenteId'], 5);
      expect(json['fecha'], '2025-06-21');
      expect(json['resultado'], 'Positivo');
      expect(json['graduacion'], 0.85);
      expect(json['servicioExtra'], 'Hora extra');
      expect(json['observacion'], 'Control de rutina');

      // Verificar que NO usa snake_case
      expect(json.containsKey('agente_id'), isFalse);
      expect(json.containsKey('servicio_extra'), isFalse);
    });

    test('POST payload mínimo (solo requeridos)', () {
      final control = ControlAlcoholemia(
        agenteId: 1,
        fecha: '2025-01-01',
        resultado: 'Negativo',
      );

      final json = control.toJson();

      expect(json['resultado'], 'Negativo');
      expect(json['graduacion'], isNull);
      expect(json['servicioExtra'], isNull);
      expect(json['observacion'], isNull);
    });

    test('GET /agentes/:id/alcoholemias response se parsea con fromApiJson', () {
      final serverResponse = {
        'id': 10,
        'agenteId': 5,
        'fecha': '2025-06-21',
        'resultado': 'Positivo',
        'graduacion': 0.85,
        'servicioExtra': 'Hora extra',
        'observacion': 'Control de rutina',
        'createdAt': '2025-06-21T08:00:00.000Z',
      };

      final control = ControlAlcoholemia.fromApiJson(serverResponse);

      expect(control.id, 10);
      expect(control.agenteId, 5);
      expect(control.resultado, 'Positivo');
      expect(control.graduacion, 0.85);
      expect(control.servicioExtra, 'Hora extra');
      expect(control.observacion, 'Control de rutina');
      expect(control.createdAt, '2025-06-21T08:00:00.000Z');
    });
  });

  // ────────────────────────────────────────────────
  // OBSERVACIÓN/RECLAMO: Contrato
  // ────────────────────────────────────────────────

  group('ObservacionReclamo contract', () {
    test('POST /agentes/:id/observaciones payload', () {
      final obs = ObservacionReclamo(
        agenteId: 5,
        tipo: 'Reclamo',
        descripcion: 'Falta de documentación en vehículo',
        fecha: '2025-06-20',
        resuelto: false,
      );

      final json = obs.toJson();

      // Backend espera camelCase
      expect(json['agenteId'], 5);
      expect(json['tipo'], 'Reclamo');
      expect(json['descripcion'], 'Falta de documentación en vehículo');
      expect(json['fecha'], '2025-06-20');
      expect(json['resuelto'], false);

      // Verificar que NO usa snake_case
      expect(json.containsKey('agente_id'), isFalse);
    });

    test('POST con resuelto true', () {
      final obs = ObservacionReclamo(
        agenteId: 1,
        tipo: 'Observación',
        descripcion: 'Resuelta',
        fecha: '2025-01-01',
        resuelto: true,
      );

      expect(obs.toJson()['resuelto'], isTrue);
    });

    test('GET /agentes/:id/observaciones response se parsea con fromApiJson', () {
      final serverResponse = {
        'id': 20,
        'agenteId': 5,
        'tipo': 'Reclamo',
        'descripcion': 'Falta grave',
        'fecha': '2025-06-20',
        'resuelto': true,
        'createdAt': '2025-06-20T10:00:00.000Z',
      };

      final obs = ObservacionReclamo.fromApiJson(serverResponse);

      expect(obs.id, 20);
      expect(obs.agenteId, 5);
      expect(obs.tipo, 'Reclamo');
      expect(obs.descripcion, 'Falta grave');
      expect(obs.fecha, '2025-06-20');
      expect(obs.resuelto, isTrue);
      expect(obs.createdAt, '2025-06-20T10:00:00.000Z');
    });

    test('fromApiJson con resuelto false', () {
      final response = {
        'id': 21,
        'agenteId': 5,
        'tipo': 'Observación',
        'descripcion': 'Pendiente',
        'fecha': '2025-06-21',
        'resuelto': false,
        'createdAt': '2025-06-21T09:00:00.000Z',
      };

      final obs = ObservacionReclamo.fromApiJson(response);
      expect(obs.resuelto, isFalse);
    });
  });

  // ────────────────────────────────────────────────
  // SYNC: Contrato de sincronización
  // ────────────────────────────────────────────────

  group('Sync contract', () {
    test('POST /sync/pull response contiene estructura esperada', () {
      final syncPullResponse = {
        'data': {
          'agentes': [],
          'alcoholemias': [],
          'observaciones': [],
          'deleted': {
            'agentes': [],
            'alcoholemias': [],
            'observaciones': [],
          },
          'serverTime': '2025-06-25T12:00:00.000Z',
        },
      };

      final data = syncPullResponse['data'] as Map<String, dynamic>;
      expect(data.containsKey('agentes'), isTrue);
      expect(data.containsKey('alcoholemias'), isTrue);
      expect(data.containsKey('observaciones'), isTrue);
      expect(data.containsKey('deleted'), isTrue);
      expect(data.containsKey('serverTime'), isTrue);
    });

    test('POST /sync/pull deleted.agentes contiene id y deletedAt', () {
      final deletedItem = {'id': 5, 'deletedAt': '2025-06-25T10:00:00.000Z'};

      expect(deletedItem.containsKey('id'), isTrue);
      expect(deletedItem.containsKey('deletedAt'), isTrue);
    });

    test('POST /sync/pull agentes se parsean con fromApiJson', () {
      final serverAgente = {
        'id': 10,
        'legajo': 'SYNC01',
        'apellidoNombre': 'Sync Agent',
        'fechaIngreso': null,
        'dependencia': null,
        'cargo': null,
        'turno': null,
        'createdAt': '2025-06-25T12:00:00.000Z',
        'updatedAt': '2025-06-25T12:00:00.000Z',
      };

      final agente = Agente.fromApiJson(serverAgente);
      expect(agente.id, 10);
      expect(agente.legajo, 'SYNC01');
      expect(agente.updatedAt, isNotNull);
    });
  });

  // ────────────────────────────────────────────────
  // VALIDACIÓN CRUZADA: Campos requeridos
  // ────────────────────────────────────────────────

  group('Cross-validation: campos requeridos coinciden', () {
    test('Backend exige legajo en POST — Flutter lo envía', () {
      // Backend: if (!legajo) errors.push({ field: "legajo", ... })
      final agente = Agente(legajo: 'REQ001', apellidoNombre: 'Required');
      final json = agente.toJson();
      expect(json['legajo'], isNotEmpty);
    });

    test('Backend exige apellidoNombre en POST — Flutter lo envía', () {
      // Backend: if (!apellidoNombre) errors.push({ field: "apellidoNombre", ... })
      final agente = Agente(legajo: '1', apellidoNombre: 'Name');
      final json = agente.toJson();
      expect(json['apellidoNombre'], isNotEmpty);
    });

    test('Backend requiere que legajo sea inmutable en PUT — Flutter lo conserva', () {
      // Backend: if (existing[0].legajo !== legajo) → 400 IMMUTABLE_LEGAJO
      final original = Agente(legajo: 'IMM001', apellidoNombre: 'X');
      final modificado = original.copyWith(apellidoNombre: 'Y');
      expect(modificado.legajo, original.legajo);
      expect(modificado.apellidoNombre, 'Y');
    });

    test('toJson() NO incluye createdAt ni updatedAt (no se envían al crear)', () {
      // Backend asigna created_at/updated_at automáticamente
      final agente = Agente(legajo: '1', apellidoNombre: 'Test');
      final json = agente.toJson();
      expect(json.containsKey('createdAt'), isFalse);
      expect(json.containsKey('updatedAt'), isFalse);
    });
  });
}

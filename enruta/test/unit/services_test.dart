import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/main.dart';
import 'package:enruta/services/api_client.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/control_alcoholemia.dart';
import 'package:enruta/models/observacion_reclamo.dart';

void main() {
  group('Agente model', () {
    test('toMap snake_case', () {
      final a = Agente(legajo: '001', apellidoNombre: 'Test', dependencia: 'Dept');
      final map = a.toMap();
      expect(map['legajo'], '001');
      expect(map['apellido_nombre'], 'Test');
      expect(map['dependencia'], 'Dept');
    });

    test('fromMap snake_case', () {
      final a = Agente.fromMap({
        'id': 1, 'legajo': '001', 'apellido_nombre': 'Test',
        'fecha_ingreso': '2020-01-01', 'dependencia': 'Dept', 'cargo': 'C',
        'turno': 'T', 'created_at': '2025-01-01', 'updated_at': '2025-01-01',
      });
      expect(a.id, 1);
      expect(a.legajo, '001');
      expect(a.apellidoNombre, 'Test');
      expect(a.fechaIngreso, '2020-01-01');
    });

    test('toJson camelCase', () {
      final a = Agente(legajo: '001', apellidoNombre: 'Test', id: 1, fechaIngreso: '2020-01-01');
      final json = a.toJson();
      expect(json['id'], 1);
      expect(json['legajo'], '001');
      expect(json['apellidoNombre'], 'Test');
      expect(json['fechaIngreso'], '2020-01-01');
    });

    test('fromApiJson camelCase', () {
      final a = Agente.fromApiJson({
        'id': 1, 'legajo': '001', 'apellidoNombre': 'Test',
        'fechaIngreso': '2020-01-01', 'dependencia': 'Dept',
        'cargo': 'C', 'turno': 'T', 'createdAt': '2025-01-01', 'updatedAt': '2025-01-01',
      });
      expect(a.id, 1);
      expect(a.fechaIngreso, '2020-01-01');
      expect(a.createdAt, '2025-01-01');
    });

    test('copyWith returns new instance', () {
      final a = Agente(legajo: '001', apellidoNombre: 'A');
      final b = a.copyWith(apellidoNombre: 'B');
      expect(b.apellidoNombre, 'B');
      expect(a.apellidoNombre, 'A');
    });

    test('copyWith preserves unchanged', () {
      final a = Agente(legajo: '001', apellidoNombre: 'A', dependencia: 'D', id: 1);
      final b = a.copyWith(apellidoNombre: 'B');
      expect(b.id, 1);
      expect(b.legajo, '001');
      expect(b.dependencia, 'D');
    });
  });

  group('ControlAlcoholemia model', () {
    test('toMap', () {
      final c = ControlAlcoholemia(agenteId: 1, fecha: '2025-01-01', resultado: 'Negativo');
      final map = c.toMap();
      expect(map['agente_id'], 1);
      expect(map['resultado'], 'Negativo');
    });

    test('fromMap', () {
      final c = ControlAlcoholemia.fromMap({
        'id': 1, 'agente_id': 2, 'fecha': '2025-01-01',
        'resultado': 'Positivo', 'graduacion': 0.5, 'servicio_extra': 'Hora extra',
        'observacion': 'test', 'created_at': '2025-01-01',
      });
      expect(c.id, 1);
      expect(c.agenteId, 2);
      expect(c.graduacion, 0.5);
    });

    test('toJson camelCase', () {
      final c = ControlAlcoholemia(
        agenteId: 1, fecha: '2025-01-01', resultado: 'Positivo',
        graduacion: 0.5, servicioExtra: 'Hora extra', observacion: 'test', id: 10,
      );
      final json = c.toJson();
      expect(json['id'], 10);
      expect(json['agenteId'], 1);
      expect(json['resultado'], 'Positivo');
      expect(json['graduacion'], 0.5);
      expect(json['servicioExtra'], 'Hora extra');
    });

    test('fromApiJson camelCase', () {
      final c = ControlAlcoholemia.fromApiJson({
        'id': 1, 'agenteId': 2, 'fecha': '2025-01-01',
        'resultado': 'Negativo', 'graduacion': null,
        'servicioExtra': null, 'observacion': null, 'createdAt': '2025-01-01',
      });
      expect(c.id, 1);
      expect(c.agenteId, 2);
      expect(c.graduacion, isNull);
      expect(c.createdAt, '2025-01-01');
    });

    test('fromApiJson with positivo', () {
      final c = ControlAlcoholemia.fromApiJson({
        'id': 1, 'agenteId': 2, 'fecha': '2025-01-01',
        'resultado': 'Positivo', 'graduacion': 0.85,
        'servicioExtra': 'Cumpliendo servicio', 'observacion': 'obs',
        'createdAt': '2025-01-01',
      });
      expect(c.resultado, 'Positivo');
      expect(c.graduacion, 0.85);
      expect(c.servicioExtra, 'Cumpliendo servicio');
      expect(c.observacion, 'obs');
    });
  });

  group('ObservacionReclamo model', () {
    test('toMap', () {
      final o = ObservacionReclamo(
        agenteId: 1, tipo: 'Observación', descripcion: 'Test', fecha: '2025-01-01',
      );
      final map = o.toMap();
      expect(map['agente_id'], 1);
      expect(map['tipo'], 'Observación');
      expect(map['resuelto'], 0);
    });

    test('toMap with resuelto true', () {
      final o = ObservacionReclamo(
        agenteId: 1, tipo: 'Reclamo', descripcion: 'Test', fecha: '2025-01-01', resuelto: true,
      );
      final map = o.toMap();
      expect(map['resuelto'], 1);
    });

    test('fromMap', () {
      final o = ObservacionReclamo.fromMap({
        'id': 1, 'agente_id': 2, 'tipo': 'Reclamo', 'descripcion': 'test',
        'fecha': '2025-01-01', 'resuelto': 1, 'created_at': '2025-01-01',
      });
      expect(o.id, 1);
      expect(o.agenteId, 2);
      expect(o.resuelto, true);
    });

    test('fromMap with resuelto 0', () {
      final o = ObservacionReclamo.fromMap({
        'id': 1, 'agente_id': 2, 'tipo': 'Observación', 'descripcion': 'test',
        'fecha': '2025-01-01', 'resuelto': 0, 'created_at': null,
      });
      expect(o.resuelto, false);
      expect(o.createdAt, isNull);
    });

    test('toJson camelCase', () {
      final o = ObservacionReclamo(
        id: 1, agenteId: 2, tipo: 'Reclamo', descripcion: 'test',
        fecha: '2025-01-01', resuelto: true,
      );
      final json = o.toJson();
      expect(json['id'], 1);
      expect(json['agenteId'], 2);
      expect(json['tipo'], 'Reclamo');
      expect(json['descripcion'], 'test');
      expect(json['resuelto'], true);
    });

    test('fromApiJson camelCase', () {
      final o = ObservacionReclamo.fromApiJson({
        'id': 1, 'agenteId': 2, 'tipo': 'Observación',
        'descripcion': 'test', 'fecha': '2025-01-01',
        'resuelto': false, 'createdAt': '2025-01-01',
      });
      expect(o.id, 1);
      expect(o.agenteId, 2);
      expect(o.createdAt, '2025-01-01');
    });
  });

  group('ApiClient construction', () {
    test('has default path prefix', () {
      final client = ApiClient(baseUrl: 'http://test.com');
      expect(client.isAuthenticated, false);
    });

    test('setTokens and clearTokens', () {
      final client = ApiClient(baseUrl: 'http://test.com');
      client.setTokens(accessToken: 'at', refreshToken: 'rt');
      expect(client.isAuthenticated, true);
      client.clearTokens();
      expect(client.isAuthenticated, false);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/control_alcoholemia.dart';
import 'package:enruta/models/observacion_reclamo.dart';
import 'package:enruta/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  group('Agente model', () {
    test('fromMap/toMap roundtrip', () {
      final original = Agente(
        id: 1, legajo: '12345', apellidoNombre: 'Test',
        fechaIngreso: '01/01/20', dependencia: 'D1',
        cargo: 'C1', turno: 'T1',
      );
      final roundtrip = Agente.fromMap(original.toMap());
      expect(roundtrip.legajo, original.legajo);
      expect(roundtrip.apellidoNombre, original.apellidoNombre);
      expect(roundtrip.fechaIngreso, original.fechaIngreso);
      expect(roundtrip.dependencia, original.dependencia);
      expect(roundtrip.cargo, original.cargo);
      expect(roundtrip.turno, original.turno);
    });

    test('toJson has expected keys', () {
      final a = Agente(legajo: '1', apellidoNombre: 'Test');
      final json = a.toJson();
      expect(json.containsKey('id'), true);
      expect(json.containsKey('legajo'), true);
      expect(json.containsKey('apellidoNombre'), true);
    });

    test('copyWith preserves unchanged', () {
      final a = Agente(legajo: '1', apellidoNombre: 'Test');
      final b = a.copyWith(apellidoNombre: 'New');
      expect(b.legajo, '1');
      expect(b.apellidoNombre, 'New');
      expect(b.id, null);
    });
  });

  group('ControlAlcoholemia model', () {
    test('fromMap handles all nullables', () {
      final c = ControlAlcoholemia.fromMap({
        'id': null, 'agente_id': 1, 'fecha': '2026-01-01',
        'resultado': 'Negativo', 'graduacion': null,
        'servicio_extra': null, 'observacion': null,
        'created_at': null,
      });
      expect(c.graduacion, isNull);
      expect(c.servicioExtra, isNull);
      expect(c.observacion, isNull);
    });

    test('toMap/toJson consistency', () {
      final c = ControlAlcoholemia(
        agenteId: 10, fecha: '2026-01-01', resultado: 'Positivo',
        graduacion: 1.5, servicioExtra: 'Hora extra',
        observacion: 'Test',
      );
      expect(c.toJson()['graduacion'], 1.5);
      expect(c.toJson()['servicioExtra'], 'Hora extra');
    });
  });

  group('ObservacionReclamo model', () {
    test('resuelto mapping', () {
      final oTrue = ObservacionReclamo.fromMap({
        'id': 1, 'agente_id': 1, 'tipo': 'Reclamo',
        'descripcion': 'test', 'fecha': '2026-01-01',
        'resuelto': 1, 'created_at': null,
      });
      expect(oTrue.resuelto, true);
      expect(oTrue.toMap()['resuelto'], 1);
    });

    test('default resuelto false', () {
      final o = ObservacionReclamo(
        agenteId: 1, tipo: 'Obs', descripcion: 'd', fecha: '2026-01-01',
      );
      expect(o.resuelto, false);
    });
  });

  group('AppTheme', () {
    test('colors are correct', () {
      expect(AppColors.primary, const Color(0xFF05C7F2));
      expect(AppColors.secondary, const Color(0xFF80DDF2));
      expect(AppColors.tertiary, const Color(0xFFBBE8F2));
      expect(AppColors.surface, const Color(0xFFF2F2F2));
    });

    test('buildLightTheme works', () {
      final t = buildLightTheme();
      expect(t.useMaterial3, true);
      expect(t.scaffoldBackgroundColor, AppColors.surface);
      expect(t.elevatedButtonTheme, isNotNull);
      expect(t.inputDecorationTheme, isNotNull);
    });
  });
}

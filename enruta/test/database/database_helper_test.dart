import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/control_alcoholemia.dart';
import 'package:enruta/models/observacion_reclamo.dart';

void main() {
  group('DatabaseHelper Agentes', () {
    late DatabaseHelper db;

    setUp(() async {
      await DatabaseHelper.resetForTest();
      db = DatabaseHelper();
      await db.database;
    });

    test('insertAgente adds agent', () async {
      final id = await db.insertAgente(Agente(
        legajo: '99999', apellidoNombre: 'Test User',
      ));
      expect(id, greaterThan(0));
    });

    test('insertAgente with all fields', () async {
      final id = await db.insertAgente(Agente(
        legajo: 'FULL001', apellidoNombre: 'Full Name',
        fechaIngreso: '01/01/20', dependencia: 'Seguridad',
        cargo: 'Jefe', turno: 'Mañana',
      ));
      final a = await db.getAgenteById(id);
      expect(a!.fechaIngreso, '01/01/20');
      expect(a.dependencia, 'Seguridad');
      expect(a.cargo, 'Jefe');
      expect(a.turno, 'Mañana');
    });

    test('getAgentes returns list', () async {
      await db.insertAgente(Agente(legajo: '111', apellidoNombre: 'A'));
      await db.insertAgente(Agente(legajo: '222', apellidoNombre: 'B'));
      final list = await db.getAgentes();
      expect(list.length, 2);
    });

    test('getAgentes returns empty initially', () async {
      final list = await db.getAgentes();
      expect(list, isEmpty);
    });

    test('getAgenteById returns agent', () async {
      final id = await db.insertAgente(Agente(
        legajo: '333', apellidoNombre: 'Test',
      ));
      final a = await db.getAgenteById(id);
      expect(a!.legajo, '333');
    });

    test('getAgenteById returns null for invalid', () async {
      expect(await db.getAgenteById(99999), isNull);
    });

    test('getAgenteByLegajo finds agent', () async {
      await db.insertAgente(Agente(legajo: '555', apellidoNombre: 'Find'));
      final a = await db.getAgenteByLegajo('555');
      expect(a!.apellidoNombre, 'Find');
    });

    test('getAgenteByLegajo returns null for unknown', () async {
      expect(await db.getAgenteByLegajo('NOEXISTE'), isNull);
    });

    test('updateAgente changes fields', () async {
      final id = await db.insertAgente(Agente(
        legajo: '777', apellidoNombre: 'Old',
      ));
      await db.updateAgente(Agente(
        id: id, legajo: '777', apellidoNombre: 'New',
      ));
      final updated = await db.getAgenteById(id);
      expect(updated!.apellidoNombre, 'New');
    });

    test('deleteAgente removes agent', () async {
      final id = await db.insertAgente(Agente(
        legajo: '888', apellidoNombre: 'Del',
      ));
      await db.deleteAgente(id);
      expect(await db.getAgenteById(id), isNull);
    });

    test('buscarAgentes by name', () async {
      await db.insertAgente(Agente(legajo: '100', apellidoNombre: 'Perez Juan'));
      await db.insertAgente(Agente(legajo: '200', apellidoNombre: 'Lopez Pedro'));
      final results = await db.buscarAgentes('Perez');
      expect(results.length, 1);
    });

    test('buscarAgentes by legajo', () async {
      await db.insertAgente(Agente(legajo: '100', apellidoNombre: 'Perez Juan'));
      final results = await db.buscarAgentes('100');
      expect(results.length, 1);
    });

    test('buscarAgentes by dependencia', () async {
      await db.insertAgente(Agente(
        legajo: 'DEP001', apellidoNombre: 'Dep Agent',
        dependencia: 'Coordinacion',
      ));
      final results = await db.buscarAgentes('Coordinacion');
      expect(results.length, 1);
    });

    test('buscarAgentes no matches', () async {
      final results = await db.buscarAgentes('ZZZ_NOEXIST');
      expect(results, isEmpty);
    });
  });

  group('DatabaseHelper Controles', () {
    late DatabaseHelper db;
    late int agenteId;

    setUp(() async {
      await DatabaseHelper.resetForTest();
      db = DatabaseHelper();
      await db.database;
      agenteId = await db.insertAgente(Agente(
        legajo: 'CTRL_${DateTime.now().millisecondsSinceEpoch}',
        apellidoNombre: 'Control Agent',
      ));
    });

    test('insertControl adds', () async {
      final id = await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-06-21', resultado: 'Negativo',
      ));
      expect(id, greaterThan(0));
    });

    test('getControlesByAgente', () async {
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-06-21', resultado: 'Negativo',
      ));
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-06-22', resultado: 'Positivo',
        graduacion: 0.5,
      ));
      expect((await db.getControlesByAgente(agenteId)).length, 2);
    });

    test('getControlesByFecha', () async {
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-01-01', resultado: 'Negativo',
      ));
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-06-15', resultado: 'Positivo',
      ));
      expect((await db.getControlesByFecha('2026-01-01')).length, 1);
    });

    test('getControlesEntreFechas', () async {
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-05-01', resultado: 'Negativo',
      ));
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-06-15', resultado: 'Positivo',
      ));
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-08-01', resultado: 'Negativo',
      ));
      final results = await db.getControlesEntreFechas('2026-06-01', '2026-07-01');
      expect(results.length, 1);
    });

    test('getControlesEntreFechas empty', () async {
      final results = await db.getControlesEntreFechas('2099-01-01', '2099-12-31');
      expect(results, isEmpty);
    });

    test('updateControl', () async {
      final id = await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-06-21', resultado: 'Negativo',
      ));
      await db.updateControl(ControlAlcoholemia(
        id: id, agenteId: agenteId, fecha: '2026-06-21',
        resultado: 'Positivo', graduacion: 0.75,
      ));
      final list = await db.getControlesByAgente(agenteId);
      expect(list.first.resultado, 'Positivo');
      expect(list.first.graduacion, 0.75);
    });

    test('deleteControl', () async {
      final id = await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-06-21', resultado: 'Negativo',
      ));
      await db.deleteControl(id);
      expect(await db.getControlesByAgente(agenteId), isEmpty);
    });

    test('deleteAgente rejects when has dependencias', () async {
      await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2026-01-01', resultado: 'Negativo',
      ));
      expect(
        () => db.deleteAgente(agenteId),
        throwsA(isA<Exception>()),
      );
      expect(await db.getControlesByAgente(agenteId), isNotEmpty);
    });
  });

  group('DatabaseHelper Observaciones', () {
    late DatabaseHelper db;
    late int agenteId;

    setUp(() async {
      await DatabaseHelper.resetForTest();
      db = DatabaseHelper();
      await db.database;
      agenteId = await db.insertAgente(Agente(
        legajo: 'OBS_${DateTime.now().millisecondsSinceEpoch}',
        apellidoNombre: 'Obs Agent',
      ));
    });

    test('insertObservacionReclamo', () async {
      final id = await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agenteId, tipo: 'Observacion',
        descripcion: 'Test', fecha: '2026-06-21',
      ));
      expect(id, greaterThan(0));
    });

    test('insert with resuelto', () async {
      await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agenteId, tipo: 'Reclamo',
        descripcion: 'Resolved', fecha: '2026-06-01',
        resuelto: true,
      ));
      final list = await db.getObservacionesReclamosByAgente(agenteId);
      expect(list.first.resuelto, true);
    });

    test('getObservacionesReclamosByAgente', () async {
      await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agenteId, tipo: 'Observacion',
        descripcion: 'Obs 1', fecha: '2026-06-20',
      ));
      await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agenteId, tipo: 'Reclamo',
        descripcion: 'Reclamo 1', fecha: '2026-06-21', resuelto: true,
      ));
      expect((await db.getObservacionesReclamosByAgente(agenteId)).length, 2);
    });

    test('updateObservacionReclamo', () async {
      final id = await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agenteId, tipo: 'Reclamo',
        descripcion: 'test', fecha: '2026-06-20',
      ));
      await db.updateObservacionReclamo(ObservacionReclamo(
        id: id, agenteId: agenteId, tipo: 'Reclamo',
        descripcion: 'test', fecha: '2026-06-20', resuelto: true,
      ));
      final list = await db.getObservacionesReclamosByAgente(agenteId);
      expect(list.first.resuelto, true);
    });

    test('deleteObservacionReclamo', () async {
      final id = await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agenteId, tipo: 'Observacion',
        descripcion: 'test', fecha: '2026-06-20',
      ));
      await db.deleteObservacionReclamo(id);
      expect(await db.getObservacionesReclamosByAgente(agenteId), isEmpty);
    });

    test('deleteAgente rejects when has observaciones', () async {
      await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agenteId, tipo: 'Observacion',
        descripcion: 'test', fecha: '2026-01-01',
      ));
      expect(
        () => db.deleteAgente(agenteId),
        throwsA(isA<Exception>()),
      );
      expect(await db.getObservacionesReclamosByAgente(agenteId), isNotEmpty);
    });
  });

  group('DatabaseHelper Reportes', () {
    late DatabaseHelper db;

    setUp(() async {
      await DatabaseHelper.resetForTest();
      db = DatabaseHelper();
      await db.database;
    });

    test('getControlesReporteEntreFechas with JOIN', () async {
      final agId = await db.insertAgente(Agente(
        legajo: 'RP001', apellidoNombre: 'Report Agent',
      ));
      await db.insertControl(ControlAlcoholemia(
        agenteId: agId, fecha: '2026-07-01', resultado: 'Positivo',
        graduacion: 0.80, servicioExtra: 'Hora extra',
      ));
      final results = await db.getControlesReporteEntreFechas('2026-06-01', '2026-08-01');
      expect(results.length, 1);
      expect(results.first['legajo'], 'RP001');
      expect(results.first['apellido_nombre'], 'Report Agent');
      expect(results.first['graduacion'], 0.80);
      expect(results.first['servicio_extra'], 'Hora extra');
    });

    test('getControlesReporteEntreFechas multiple agents', () async {
      final ag1 = await db.insertAgente(Agente(
        legajo: 'JR001', apellidoNombre: 'Agent One',
      ));
      final ag2 = await db.insertAgente(Agente(
        legajo: 'JR002', apellidoNombre: 'Agent Two',
      ));
      await db.insertControl(ControlAlcoholemia(
        agenteId: ag1, fecha: '2026-06-01', resultado: 'Negativo',
      ));
      await db.insertControl(ControlAlcoholemia(
        agenteId: ag2, fecha: '2026-06-02', resultado: 'Positivo',
      ));
      final results = await db.getControlesReporteEntreFechas('2026-01-01', '2026-12-31');
      expect(results.length, 2);
    });

    test('getObservacionesReporteByAgente with JOIN', () async {
      final agId = await db.insertAgente(Agente(
        legajo: 'RP002', apellidoNombre: 'Obs Report',
        dependencia: 'Seguridad', cargo: 'Analista',
      ));
      await db.insertObservacionReclamo(ObservacionReclamo(
        agenteId: agId, tipo: 'Reclamo',
        descripcion: 'Reclamo grave', fecha: '2026-07-01',
        resuelto: false,
      ));
      final results = await db.getObservacionesReporteByAgente(agId);
      expect(results.length, 1);
      expect(results.first['legajo'], 'RP002');
      expect(results.first['dependencia'], 'Seguridad');
      expect(results.first['tipo'], 'Reclamo');
      expect(results.first['resuelto'], 0);
    });

    test('getObservacionesReporteByAgente empty', () async {
      final agId = await db.insertAgente(Agente(
        legajo: 'EMPTY001', apellidoNombre: 'Empty Obs',
      ));
      final results = await db.getObservacionesReporteByAgente(agId);
      expect(results, isEmpty);
    });
  });
}

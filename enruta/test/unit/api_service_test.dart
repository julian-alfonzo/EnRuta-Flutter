import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:enruta/services/api_client.dart';
import 'package:enruta/services/api_service.dart';
import 'package:enruta/services/sync_service.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/control_alcoholemia.dart';
import 'package:enruta/models/observacion_reclamo.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockApiClient mockApi;
  late ApiService apiService;
  late DatabaseHelper db;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() async {
    mockApi = MockApiClient();
    await DatabaseHelper.resetForTest();
    db = DatabaseHelper();
    apiService = ApiService(baseUrl: 'http://test.com', apiClient: mockApi);
  });

  group('ApiService - Agentes', () {
    test('fetchAgentes returns parsed list', () async {
      when(() => mockApi.getAgentes(search: any(named: 'search'), page: any(named: 'page')))
          .thenAnswer((_) async => {
            'data': [
              {'id': 1, 'legajo': '001', 'apellidoNombre': 'Test Agent', 'fechaIngreso': null, 'dependencia': null, 'cargo': null, 'turno': null, 'createdAt': '', 'updatedAt': ''}
            ],
            'meta': {'total': 1}
          });

      final agentes = await apiService.fetchAgentes();
      expect(agentes.length, 1);
      expect(agentes[0].legajo, '001');
    });

    test('createAgente inserts locally and calls API', () async {
      when(() => mockApi.createAgente(any()))
          .thenAnswer((_) async => {'data': {'id': 100}});

      final agente = Agente(legajo: 'L001', apellidoNombre: 'Test');
      final localId = await apiService.createAgente(agente);
      expect(localId, isPositive);

      final saved = await db.getAgenteByLegajo('L001');
      expect(saved, isNotNull);
    });

    test('updateAgente updates locally and calls API by legajo', () async {
      when(() => mockApi.updateAgenteByLegajo(any(), any()))
          .thenAnswer((_) async => {'data': {}});

      final localId = await db.insertAgente(Agente(legajo: 'L002', apellidoNombre: 'Old'));
      final agente = (await db.getAgenteById(localId))!.copyWith(apellidoNombre: 'New');
      await apiService.updateAgente(agente);

      final updated = await db.getAgenteById(localId);
      expect(updated!.apellidoNombre, 'New');
    });

    test('deleteAgente deletes locally and calls API by legajo', () async {
      when(() => mockApi.deleteAgenteByLegajo(any()))
          .thenAnswer((_) async => {});

      final localId = await db.insertAgente(Agente(legajo: 'L003', apellidoNombre: 'Del'));
      await apiService.deleteAgente(localId);

      final found = await db.getAgenteById(localId);
      expect(found, isNull);
    });
  });

  group('ApiService - Controles', () {
    test('createControl uses legajo for API call', () async {
      when(() => mockApi.createAlcoholemiaByLegajo(any(), any()))
          .thenAnswer((_) async => {'data': {'id': 200}});

      final agenteId = await db.insertAgente(Agente(legajo: 'C001', apellidoNombre: 'Ctrl'));
      final control = ControlAlcoholemia(
        agenteId: agenteId, fecha: '2025-06-21', resultado: 'Negativo',
      );
      final localId = await apiService.createControl(control);
      expect(localId, isPositive);

      verify(() => mockApi.createAlcoholemiaByLegajo('C001', any())).called(1);
    });

    test('updateControl calls API', () async {
      when(() => mockApi.updateAlcoholemia(any(), any()))
          .thenAnswer((_) async => {'data': {}});

      final agenteId = await db.insertAgente(Agente(legajo: 'C002', apellidoNombre: 'Upd'));
      final controlId = await db.insertControl(ControlAlcoholemia(
        agenteId: agenteId, fecha: '2025-06-21', resultado: 'Negativo',
      ));
      final controles = await db.getControlesByAgente(agenteId);
      final c = ControlAlcoholemia.fromMap({
        ...controles.first.toMap(), 'resultado': 'Positivo', 'graduacion': 0.5,
      });
      await apiService.updateControl(c);

      final updated = await db.getControlesByAgente(agenteId);
      expect(updated.first.resultado, 'Positivo');
    });
  });

  group('ApiService - Observaciones', () {
    test('createObservacion uses legajo for API call', () async {
      when(() => mockApi.createObservacionByLegajo(any(), any()))
          .thenAnswer((_) async => {'data': {'id': 300}});

      final agenteId = await db.insertAgente(Agente(legajo: 'O001', apellidoNombre: 'Obs'));
      final obs = ObservacionReclamo(
        agenteId: agenteId, tipo: 'Observación', descripcion: 'Test', fecha: '2025-06-21',
      );
      final localId = await apiService.createObservacion(obs);
      expect(localId, isPositive);

      verify(() => mockApi.createObservacionByLegajo('O001', any())).called(1);
    });

    test('fetchReporteAgente by legajo', () async {
      when(() => mockApi.getReporteAgenteByLegajo(any()))
          .thenAnswer((_) async => {'data': []});

      final reporte = await apiService.fetchReporteAgente('O001');
      expect(reporte, isEmpty);
    });
  });

  group('ApiService - Auth', () {
    test('login delegates to api client', () async {
      when(() => mockApi.login(any(), any()))
          .thenAnswer((_) async => {'data': {'accessToken': 'at'}});

      final result = await apiService.login('admin', 'admin123');
      expect(result, true);
    });

    test('login throws on failure', () async {
      when(() => mockApi.login(any(), any()))
          .thenThrow(ApiException(statusCode: 401, code: 'UNAUTHORIZED', message: 'Invalid'));

      expect(() => apiService.login('admin', 'wrong'), throwsA(isA<ApiException>()));
    });

    test('logout clears tokens', () {
      apiService.logout();
      // Verifies clearTokens was called
      verify(() => mockApi.clearTokens()).called(1);
    });
  });
}

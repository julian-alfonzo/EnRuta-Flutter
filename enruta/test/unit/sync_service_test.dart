import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:enruta/services/api_client.dart';
import 'package:enruta/services/sync_service.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/observacion_reclamo.dart';

class MockApiClient extends Mock implements ApiClient {}

class FakeUri extends Fake implements Uri {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockApiClient mockApi;
  late SyncService syncService;
  late DatabaseHelper db;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() async {
    mockApi = MockApiClient();
    syncService = SyncService();
    syncService.configure(mockApi);
    when(() => mockApi.isAuthenticated).thenReturn(true);
    await DatabaseHelper.resetForTest();
    db = DatabaseHelper();
  });

  group('SyncService - Queue', () {
    test('enqueue stores item', () async {
      await syncService.enqueue('agente', 'create', 1, {'legajo': 'TEST'});
      final count = await syncService.pendingCount;
      expect(count, 1);
    });

    test('enqueue multiple items', () async {
      await syncService.enqueue('agente', 'create', 1, {});
      await syncService.enqueue('alcoholemia', 'update', 2, {});
      final count = await syncService.pendingCount;
      expect(count, 2);
    });
  });

  group('SyncService - Pull', () {
    test('pullFromServer merges agents by legajo', () async {
      when(() => mockApi.syncPull(any())).thenAnswer((_) async => {
        'data': {
          'agentes': [
            {'id': 100, 'legajo': 'S001', 'apellidoNombre': 'Server Agent', 'fechaIngreso': null, 'dependencia': null, 'cargo': null, 'turno': null, 'createdAt': '2025-01-01T00:00:00Z', 'updatedAt': '2025-06-21T00:00:00Z'}
          ],
          'alcoholemias': [],
          'observaciones': [],
          'deleted': {'agentes': [], 'alcoholemias': [], 'observaciones': []},
          'serverTime': '2025-06-27T00:00:00Z',
        }
      });
      when(() => mockApi.isAuthenticated).thenReturn(true);

      await syncService.pullFromServer();
      final agent = await db.getAgenteByLegajo('S001');
      expect(agent, isNotNull);
      expect(agent!.apellidoNombre, 'Server Agent');
    });

    test('pullFromServer handles empty response', () async {
      when(() => mockApi.syncPull(any())).thenAnswer((_) async => {
        'data': null
      });
      when(() => mockApi.isAuthenticated).thenReturn(true);

      await syncService.pullFromServer();
    });

    test('pullFromServer merges controles with agenteLegajo', () async {
      await db.insertAgente(Agente(legajo: 'C001', apellidoNombre: 'Ctrl'));

      when(() => mockApi.syncPull(any())).thenAnswer((_) async => {
        'data': {
          'agentes': [],
          'alcoholemias': [
            {'id': 500, 'agenteId': 999, 'agenteLegajo': 'C001', 'fecha': '2025-06-21', 'resultado': 'Negativo', 'graduacion': null, 'servicioExtra': null, 'observacion': null, 'createdAt': '2025-06-21T00:00:00Z'}
          ],
          'observaciones': [],
          'deleted': {'agentes': [], 'alcoholemias': [], 'observaciones': []},
          'serverTime': '2025-06-27T00:00:00Z',
        }
      });
      when(() => mockApi.isAuthenticated).thenReturn(true);

      await syncService.pullFromServer();
      final agente = await db.getAgenteByLegajo('C001');
      final controles = await db.getControlesByAgente(agente!.id!);
      expect(controles.length, 1);
    });

    test('pullFromServer merges observaciones with agenteLegajo', () async {
      await db.insertAgente(Agente(legajo: 'O001', apellidoNombre: 'Obs'));

      when(() => mockApi.syncPull(any())).thenAnswer((_) async => {
        'data': {
          'agentes': [],
          'alcoholemias': [],
          'observaciones': [
            {'id': 600, 'agenteId': 999, 'agenteLegajo': 'O001', 'tipo': 'Observación', 'descripcion': 'Test', 'fecha': '2025-06-21', 'resuelto': false, 'createdAt': '2025-06-21T00:00:00Z'}
          ],
          'deleted': {'agentes': [], 'alcoholemias': [], 'observaciones': []},
          'serverTime': '2025-06-27T00:00:00Z',
        }
      });
      when(() => mockApi.isAuthenticated).thenReturn(true);

      await syncService.pullFromServer();
      final agente = await db.getAgenteByLegajo('O001');
      final obs = await db.getObservacionesReclamosByAgente(agente!.id!);
      expect(obs.length, 1);
    });
  });

  group('SyncService - Process queue', () {
    test('processPendingSyncs sends agent creates', () async {
      when(() => mockApi.createAgente(any()))
          .thenAnswer((_) async => {'data': {'id': 1}});

      await db.enqueueSync('agente', 'create', 1, '{"legajo":"Q001","apellidoNombre":"Queue"}');
      await syncService.processPendingSyncs();

      final count = await syncService.pendingCount;
      verify(() => mockApi.createAgente(any())).called(1);
    });

    test('processPendingSyncs stops on 400 client error', () async {
      when(() => mockApi.createAgente(any()))
          .thenThrow(ApiException(statusCode: 400, code: 'VALIDATION_ERROR', message: 'Invalid'));

      await db.enqueueSync('agente', 'create', 1, '{"legajo":"Q002","apellidoNombre":"Bad"}');
      await syncService.processPendingSyncs();

      final failed = await syncService.failedCount;
      expect(failed, 1);
    });

    test('processPendingSyncs retries on 500', () async {
      when(() => mockApi.createAgente(any()))
          .thenThrow(ApiException(statusCode: 500, code: 'INTERNAL_ERROR', message: 'Error'));

      await db.enqueueSync('agente', 'create', 1, '{"legajo":"Q003","apellidoNombre":"Retry"}');
      await syncService.processPendingSyncs();

      final pending = await syncService.pendingCount;
      expect(pending, 1);
    });

    test('retryAllFailed resets to pending', () async {
      when(() => mockApi.createAgente(any()))
          .thenThrow(ApiException(statusCode: 400, code: 'BAD', message: ''));

      await db.enqueueSync('agente', 'create', 1, '{"legajo":"Q004"}');
      await syncService.processPendingSyncs();
      expect(await syncService.failedCount, 1);

      await syncService.retryAllFailed();
      expect(await syncService.pendingCount, 1);
    });

    test('retryFailedItem resets single to pending', () async {
      when(() => mockApi.createAgente(any()))
          .thenThrow(ApiException(statusCode: 400, code: 'BAD', message: ''));

      await db.enqueueSync('agente', 'create', 1, '{"legajo":"Q005"}');
      await syncService.processPendingSyncs();

      final failed = await db.getFailedSyncIds();
      expect(failed.length, 1);

      await syncService.retryFailedItem(failed.first);
      expect(await syncService.pendingCount, 1);
    });
  });

  group('SyncService - Stop/Dispose', () {
    test('stop does not throw', () {
      syncService.stop();
    });
  });
}

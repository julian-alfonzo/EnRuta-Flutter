import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:enruta/di/injection.dart';
import 'package:enruta/screens/agente_detail_screen.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/control_alcoholemia.dart';
import 'package:enruta/models/observacion_reclamo.dart';
import 'package:enruta/core/interfaces/api_client_interface.dart';
import 'package:enruta/core/interfaces/sync_service_interface.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/services/api_service.dart';
import 'package:enruta/services/api_client.dart';

class MockApiClient extends Mock implements ApiClientInterface {}
class MockApiService extends Mock implements ApiService {}
class MockSyncService extends Mock implements SyncServiceInterface {}
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class FakeUri extends Fake implements Uri {}

void main() {
  late MockApiClient mockApiClient;
  late MockApiService mockApiService;
  late MockSyncService mockSyncService;
  late MockDatabaseHelper mockDb;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(<String, String>{});
  });

  setUp(() {
    getIt.reset();
    mockApiClient = MockApiClient();
    mockApiService = MockApiService();
    mockSyncService = MockSyncService();
    mockDb = MockDatabaseHelper();

    getIt.registerSingleton<ApiClientInterface>(mockApiClient);
    getIt.registerSingleton<ApiService>(mockApiService);
    getIt.registerSingleton<SyncServiceInterface>(mockSyncService);
    getIt.registerSingleton<DatabaseHelper>(mockDb);
  });

  tearDown(() {
    getIt.reset();
  });

  final testAgente = Agente(
    id: 1, legajo: 'D001', apellidoNombre: 'Detail Agent',
    dependencia: 'Dept', cargo: 'Cargo', turno: 'TARDE', fechaIngreso: '2020-01-01',
  );

  testWidgets('shows agent info and tabs', (t) async {
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Detail Agent'), findsAtLeast(1));
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Alcoholemia'), findsOneWidget);
    expect(find.text('Obs. / Reclamos'), findsOneWidget);
  });

  testWidgets('shows agent info tab content', (t) async {
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Legajo'), findsOneWidget);
    expect(find.text('D001'), findsOneWidget);
    expect(find.text('Dept'), findsOneWidget);
  });

  testWidgets('shows empty controls tab', (t) async {
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    await t.tap(find.text('Alcoholemia'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Sin controles registrados'), findsOneWidget);
  });

  testWidgets('shows controls from API', (t) async {
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenAnswer((_) async => {
          'data': [
            {'id': 1, 'agenteId': 1, 'fecha': '2025-06-21', 'resultado': 'Negativo',
             'graduacion': null, 'servicioExtra': null, 'observacion': null, 'createdAt': ''}
          ]
        });
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    await t.tap(find.text('Alcoholemia'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('2025-06-21'), findsOneWidget);
    expect(find.text('Negativo'), findsOneWidget);
  });

  testWidgets('shows empty observaciones tab', (t) async {
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    await t.tap(find.text('Obs. / Reclamos'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Sin observaciones ni reclamos'), findsOneWidget);
  });

  testWidgets('shows observaciones from API', (t) async {
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenAnswer((_) async => {
          'data': [
            {'id': 1, 'agenteId': 1, 'tipo': 'Observación', 'descripcion': 'Test obs',
             'fecha': '2025-06-21', 'resuelto': false, 'createdAt': ''}
          ]
        });

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    await t.tap(find.text('Obs. / Reclamos'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Test obs'), findsOneWidget);
  });

  testWidgets('has edit button', (t) async {
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenAnswer((_) async => {'data': []});

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.edit), findsOneWidget);
  });

  testWidgets('falls back to local DB when API fails', (t) async {
    final localControl = ControlAlcoholemia(
      id: 1, agenteId: 1, fecha: '2025-06-20', resultado: 'Positivo', graduacion: 0.5,
    );
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async => testAgente);
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => [localControl]);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);
    when(() => mockApiClient.getAlcoholemiasByLegajo('D001'))
        .thenThrow(ApiException(statusCode: 500, code: 'ERROR', message: 'fail'));
    when(() => mockApiClient.getObservacionesByLegajo('D001'))
        .thenThrow(ApiException(statusCode: 500, code: 'ERROR', message: 'fail'));

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: testAgente)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    await t.tap(find.text('Alcoholemia'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('2025-06-20'), findsOneWidget);
    expect(find.text('Positivo'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:enruta/di/injection.dart';
import 'package:enruta/screens/gestion_alcoholemia_screen.dart';
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

  testWidgets('shows title and search UI', (t) async {
    when(() => mockApiClient.getAlcoholemias(
      search: any(named: 'search'),
      desde: any(named: 'desde'),
      hasta: any(named: 'hasta'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {'data': [], 'meta': {'total': 0}});

    await t.pumpWidget(const MaterialApp(home: GestionAlcoholemiaScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Controles de Alcoholemia'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today), findsAtLeast(2));
  });

  testWidgets('shows results from API when search is triggered', (t) async {
    when(() => mockApiClient.getAlcoholemias(
      search: any(named: 'search'),
      desde: any(named: 'desde'),
      hasta: any(named: 'hasta'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {
      'data': [
        {
          'id': 1, 'agenteId': 1, 'fecha': '2025-06-21', 'resultado': 'Negativo',
          'graduacion': null, 'servicioExtra': null, 'observacion': null,
          'legajo': '001', 'apellidoNombre': 'Test Agent',
          'dependencia': 'Dept', 'cargo': 'Cargo', 'createdAt': ''
        }
      ],
      'meta': {'total': 1}
    });

    await t.pumpWidget(const MaterialApp(home: GestionAlcoholemiaScreen()));
    await t.pump();

    await t.tap(find.text('Buscar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.text('Test Agent'), findsOneWidget);
    expect(find.text('Negativo'), findsOneWidget);
  });

  testWidgets('falls back to local DB when API fails', (t) async {
    when(() => mockApiClient.getAlcoholemias(
      search: any(named: 'search'),
      desde: any(named: 'desde'),
      hasta: any(named: 'hasta'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenThrow(ApiException(statusCode: 500, code: 'ERROR', message: 'fail'));

    when(() => mockDb.getControlesReporteEntreFechas(any(), any()))
        .thenAnswer((_) async => [
      {'id': 1, 'legajo': '001', 'apellido_nombre': 'Local Agent', 'fecha': '2025-06-20',
       'resultado': 'Positivo', 'graduacion': 0.5, 'servicio_extra': null,
       'observacion': null, 'dependencia': 'Dept', 'cargo': 'Cargo'}
    ]);

    await t.pumpWidget(const MaterialApp(home: GestionAlcoholemiaScreen()));
    await t.pump();

    await t.tap(find.text('Buscar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.text('Local Agent'), findsOneWidget);
  });

  testWidgets('shows empty state when no results', (t) async {
    when(() => mockApiClient.getAlcoholemias(
      search: any(named: 'search'),
      desde: any(named: 'desde'),
      hasta: any(named: 'hasta'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {'data': [], 'meta': {'total': 0}});

    await t.pumpWidget(const MaterialApp(home: GestionAlcoholemiaScreen()));
    await t.pump();

    await t.tap(find.text('Buscar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.text('Sin resultados. Buscá por fecha o agente.'), findsOneWidget);
  });

  testWidgets('shows export buttons with results', (t) async {
    when(() => mockApiClient.getAlcoholemias(
      search: any(named: 'search'),
      desde: any(named: 'desde'),
      hasta: any(named: 'hasta'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {
      'data': [
        {
          'id': 1, 'agenteId': 1, 'fecha': '2025-06-21', 'resultado': 'Negativo',
          'graduacion': null, 'servicioExtra': null, 'observacion': null,
          'legajo': '001', 'apellidoNombre': 'Test Agent',
          'dependencia': 'Dept', 'cargo': 'Cargo', 'createdAt': ''
        }
      ],
      'meta': {'total': 1}
    });

    await t.pumpWidget(const MaterialApp(home: GestionAlcoholemiaScreen()));
    await t.pump();

    await t.tap(find.text('Buscar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    expect(find.byIcon(Icons.table_chart), findsOneWidget);
  });
}

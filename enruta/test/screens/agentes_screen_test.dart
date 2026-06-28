import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:enruta/di/injection.dart';
import 'package:enruta/screens/agentes_screen.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/core/interfaces/api_client_interface.dart';
import 'package:enruta/core/interfaces/sync_service_interface.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/services/api_service.dart';

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

  testWidgets('shows title and search', (t) async {
    when(() => mockDb.getAgentes()).thenAnswer((_) async => []);

    await t.pumpWidget(const MaterialApp(home: AgentesScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Agentes'), findsAtLeast(1));
    expect(find.byIcon(Icons.search), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('shows agentes from DB', (t) async {
    when(() => mockDb.getAgentes()).thenAnswer((_) async => [
      Agente(id: 1, legajo: 'A1', apellidoNombre: 'Test Agent', dependencia: 'Dept'),
      Agente(id: 2, legajo: 'B1', apellidoNombre: 'Another Agent', dependencia: 'Patrullas'),
    ]);
    when(() => mockDb.buscarAgentes(any())).thenAnswer((_) async => []);

    await t.pumpWidget(const MaterialApp(home: AgentesScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Test Agent'), findsOneWidget);
    expect(find.text('Legajo: A1'), findsOneWidget);
    expect(find.text('Another Agent'), findsOneWidget);
  });

  testWidgets('filters by search query', (t) async {
    when(() => mockDb.getAgentes()).thenAnswer((_) async => [
      Agente(id: 1, legajo: 'A1', apellidoNombre: 'Perez Juan', dependencia: 'Transito'),
      Agente(id: 2, legajo: 'B1', apellidoNombre: 'Gomez Maria', dependencia: 'Patrullas'),
    ]);
    when(() => mockDb.buscarAgentes('Perez')).thenAnswer((_) async => [
      Agente(id: 1, legajo: 'A1', apellidoNombre: 'Perez Juan', dependencia: 'Transito'),
    ]);

    await t.pumpWidget(const MaterialApp(home: AgentesScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    await t.enterText(find.byType(TextField), 'Perez');
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.text('Perez Juan'), findsOneWidget);
    expect(find.text('Gomez Maria'), findsNothing);
  });

  testWidgets('shows empty state', (t) async {
    when(() => mockDb.getAgentes()).thenAnswer((_) async => []);
    when(() => mockDb.buscarAgentes(any())).thenAnswer((_) async => []);

    await t.pumpWidget(const MaterialApp(home: AgentesScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('No se encontraron agentes'), findsOneWidget);
  });

  testWidgets('navigates to detail on tap', (t) async {
    when(() => mockDb.getAgentes()).thenAnswer((_) async => [
      Agente(id: 1, legajo: 'A1', apellidoNombre: 'Tap Agent', dependencia: 'Dept'),
    ]);
    when(() => mockDb.buscarAgentes(any())).thenAnswer((_) async => []);
    when(() => mockDb.getAgenteById(1)).thenAnswer((_) async =>
      Agente(id: 1, legajo: 'A1', apellidoNombre: 'Tap Agent', dependencia: 'Dept'));
    when(() => mockApiClient.getAlcoholemiasByLegajo('A1'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockApiClient.getObservacionesByLegajo('A1'))
        .thenAnswer((_) async => {'data': []});
    when(() => mockDb.getControlesByAgente(1)).thenAnswer((_) async => []);
    when(() => mockDb.getObservacionesReclamosByAgente(1)).thenAnswer((_) async => []);

    await t.pumpWidget(const MaterialApp(home: AgentesScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    await t.tap(find.text('Tap Agent'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Alcoholemia'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:enruta/di/injection.dart';
import 'package:enruta/screens/home_screen.dart';
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

  testWidgets('shows welcome message and menu', (t) async {
    when(() => mockApiClient.getAgentes(
      search: any(named: 'search'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {'data': [], 'meta': {'total': 0}});
    when(() => mockSyncService.pendingCount).thenAnswer((_) async => 0);
    when(() => mockSyncService.failedCount).thenAnswer((_) async => 0);

    await t.pumpWidget(const MaterialApp(home: HomeScreen(username: 'admin')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.text('Bienvenido, admin'), findsOneWidget);
    expect(find.text('Agentes'), findsOneWidget);
    expect(find.text('Alcoholemia'), findsOneWidget);
    expect(find.text('Observaciones'), findsOneWidget);
    expect(find.text('Estadísticas'), findsOneWidget);
  });

  testWidgets('has logout icon', (t) async {
    when(() => mockApiClient.getAgentes(
      search: any(named: 'search'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {'data': [], 'meta': {'total': 0}});
    when(() => mockSyncService.pendingCount).thenAnswer((_) async => 0);
    when(() => mockSyncService.failedCount).thenAnswer((_) async => 0);

    await t.pumpWidget(const MaterialApp(home: HomeScreen(username: 'admin')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('shows connected status', (t) async {
    when(() => mockApiClient.getAgentes(
      search: any(named: 'search'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {'data': [], 'meta': {'total': 0}});
    when(() => mockSyncService.pendingCount).thenAnswer((_) async => 0);
    when(() => mockSyncService.failedCount).thenAnswer((_) async => 0);

    await t.pumpWidget(const MaterialApp(home: HomeScreen(username: 'admin')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.cloud_done), findsOneWidget);
  });

  testWidgets('shows disconnected status when API fails', (t) async {
    when(() => mockApiClient.getAgentes(
      search: any(named: 'search'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenThrow(Exception('No connection'));
    when(() => mockSyncService.pendingCount).thenAnswer((_) async => 0);
    when(() => mockSyncService.failedCount).thenAnswer((_) async => 0);

    await t.pumpWidget(const MaterialApp(home: HomeScreen(username: 'admin')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });

  testWidgets('shows sync pending when there are pending items', (t) async {
    when(() => mockApiClient.getAgentes(
      search: any(named: 'search'),
      dependencia: any(named: 'dependencia'),
      cargo: any(named: 'cargo'),
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    )).thenAnswer((_) async => {'data': [], 'meta': {'total': 0}});
    when(() => mockSyncService.pendingCount).thenAnswer((_) async => 3);
    when(() => mockSyncService.failedCount).thenAnswer((_) async => 0);

    await t.pumpWidget(const MaterialApp(home: HomeScreen(username: 'admin')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

    expect(find.byIcon(Icons.sync), findsOneWidget);
  });
}

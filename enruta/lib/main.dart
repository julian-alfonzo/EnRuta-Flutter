import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'database/database_helper.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/api_service.dart';
import 'services/sync_service.dart';

class AppServices {
  final ApiClient apiClient;
  final ApiService apiService;
  final SyncService syncService;

  AppServices._({
    required this.apiClient,
    required this.apiService,
    required this.syncService,
  });

  static AppServices? _instance;

  static AppServices init({required String baseUrl}) {
    if (_instance != null) return _instance!;
    final apiClient = ApiClient(baseUrl: baseUrl);
    final apiService = ApiService(baseUrl: baseUrl, apiClient: apiClient);
    final syncService = SyncService();
    syncService.configure(apiClient);
    _instance = AppServices._(
      apiClient: apiClient,
      apiService: apiService,
      syncService: syncService,
    );
    return _instance!;
  }

  static AppServices get instance => _instance!;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHelper();
  await db.seedIfEmpty();

  AppServices.init(baseUrl: 'https://enruta-msm.vercel.app');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EnRuta',
      theme: buildLightTheme(),
      home: const LoginScreen(),
    );
  }
}

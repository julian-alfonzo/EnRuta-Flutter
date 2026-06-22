import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'database/database_helper.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = DatabaseHelper();
  await db.seedIfEmpty();
  runApp(const MyApp());
}

class ServicesProvider extends InheritedWidget {
  final ApiClient apiClient;
  final SyncService syncService;

  const ServicesProvider({
    super.key,
    required this.apiClient,
    required this.syncService,
    required super.child,
  });

  static ServicesProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ServicesProvider>();
  }

  @override
  bool updateShouldNotify(ServicesProvider oldWidget) => false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient(baseUrl: 'https://api.enruta.app/v1');
    SyncService().configure(apiClient);

    return ServicesProvider(
      apiClient: apiClient,
      syncService: SyncService(),
      child: MaterialApp(
        title: 'EnRuta',
        theme: buildLightTheme(),
        home: const LoginScreen(),
      ),
    );
  }
}

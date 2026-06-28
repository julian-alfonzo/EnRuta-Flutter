import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'database/database_helper.dart';
import 'screens/login_screen.dart';
import 'di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DI container
  setupDependencyInjection();

  // Seed database if empty
  await databaseHelper.seedIfEmpty();

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

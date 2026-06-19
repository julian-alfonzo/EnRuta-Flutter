import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'screens/login_screen.dart';

void main() {
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

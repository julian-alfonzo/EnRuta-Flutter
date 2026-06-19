import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enruta/screens/home_screen.dart';

void main() {
  testWidgets('Home screen shows welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(username: 'admin')),
    );

    expect(find.text('Bienvenido, admin'), findsOneWidget);
  });

  testWidgets('Home screen has logout button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen(username: 'admin')),
    );

    expect(find.text('Cerrar Sesión'), findsOneWidget);
  });
}

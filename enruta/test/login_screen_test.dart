import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enruta/main.dart';

void main() {
  testWidgets('Login screen has username and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('Login screen has login button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });

  testWidgets('Login screen has dev access button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Acceso Dev'), findsOneWidget);
  });
}

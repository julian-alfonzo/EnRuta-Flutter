import 'package:flutter/material.dart';
import 'package:enruta/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/screens/reportes_screen.dart';
import 'package:enruta/main.dart';

void main() {
  testWidgets('shows initial render of reportes', (t) async {
    setupDependencyInjection(baseUrl: 'http://test.com');
    await t.pumpWidget(const MaterialApp(home: ReportesScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Alcoholemia'), findsAtLeast(1));
    expect(find.text('Por Agente'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));
}

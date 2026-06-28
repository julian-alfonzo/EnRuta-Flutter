import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/screens/agentes_screen.dart';
import 'package:enruta/main.dart';

void main() {
  testWidgets('shows initial render of agentes', (t) async {
    AppServices.init(baseUrl: 'http://test.com');
    await t.pumpWidget(const MaterialApp(home: AgentesScreen()));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));

    expect(find.text('Agentes'), findsAtLeast(1));
  }, timeout: const Timeout(Duration(seconds: 30)));
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/screens/seleccion_agente_screen.dart';

void main() {
  testWidgets('shows search and title', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: SeleccionAgenteScreen(destino: 'alcoholemia'),
    ));
    await t.pump();

    expect(find.text('Nuevo Control de Alcoholemia'), findsOneWidget);
    expect(find.text('Buscar agente...'), findsOneWidget);
    expect(find.text('Seleccione un agente'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 15)));

  testWidgets('shows observacion title for observaciones', (t) async {
    await t.pumpWidget(const MaterialApp(
      home: SeleccionAgenteScreen(destino: 'observaciones'),
    ));
    await t.pump();

    expect(find.text('Nueva Observación / Reclamo'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 15)));
}

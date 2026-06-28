import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/screens/agente_detail_screen.dart';
import 'package:enruta/main.dart';
import 'package:enruta/database/database_helper.dart';
import 'package:enruta/models/agente.dart';

void main() {
  testWidgets('shows initial render of agente detail', (t) async {
    AppServices.init(baseUrl: 'http://test.com');
    final db = DatabaseHelper();
    await db.insertAgente(Agente(legajo: 'D001', apellidoNombre: 'Detail'));
    final agent = (await db.getAgentes()).first;

    await t.pumpWidget(MaterialApp(home: AgenteDetailScreen(agente: agent)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));

    expect(find.text('Detail'), findsAtLeast(1));
  }, timeout: const Timeout(Duration(seconds: 30)));
}

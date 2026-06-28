import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/screens/reporte_alcoholemia_view.dart';

void main() {
  group('ReporteAlcoholemiaView', () {
    final datos = [
      {
        'legajo': '001',
        'apellido_nombre': 'Perez, Juan',
        'fecha': '2025-06-01',
        'resultado': 'Negativo',
        'graduacion': null,
        'servicio_extra': null,
        'dependencia': 'Transito',
        'cargo': 'Supervisor',
      },
      {
        'legajo': '002',
        'apellido_nombre': 'Gomez, Maria',
        'fecha': '2025-06-02',
        'resultado': 'Positivo',
        'graduacion': 0.85,
        'servicio_extra': 'Hora extra',
        'dependencia': 'Patrullas',
        'cargo': 'Conductor',
      },
    ];

    testWidgets('shows report with data', (t) async {
      await t.pumpWidget(
        MaterialApp(home: ReporteAlcoholemiaView(datos: datos, desde: '2025-06-01', hasta: '2025-06-30')),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Reporte de Alcoholemia'), findsOneWidget);
      expect(find.text('Perez, Juan'), findsOneWidget);
      expect(find.text('Gomez, Maria'), findsOneWidget);
    });

    testWidgets('shows empty state', (t) async {
      await t.pumpWidget(
        MaterialApp(home: ReporteAlcoholemiaView(datos: const [], desde: '2025-01-01', hasta: '2025-01-31')),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Sin controles en este período'), findsOneWidget);
    });
  });
}

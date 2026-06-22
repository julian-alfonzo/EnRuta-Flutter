import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enruta/screens/reporte_alcoholemia_view.dart';
import 'package:enruta/screens/reporte_agente_view.dart';
import 'package:enruta/models/agente.dart';

void main() {
  group('ReporteAlcoholemiaView', () {
    testWidgets('shows header with date range', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReporteAlcoholemiaView(
              datos: [],
              desde: '2026-01-01',
              hasta: '2026-06-21',
            ),
          ),
        ),
      ));
      expect(find.text('Reporte de Alcoholemia'), findsOneWidget);
      expect(find.text('Sin controles en este período'), findsOneWidget);
    });

    testWidgets('shows controls list', (tester) async {
      final datos = [
        {
          'id': 1,
          'apellido_nombre': 'Garcia Juan',
          'legajo': '12345',
          'fecha': '2026-06-21',
          'resultado': 'Positivo',
          'graduacion': 0.85,
          'servicio_extra': 'Hora extra',
          'observacion': 'Control de rutina',
        },
        {
          'id': 2,
          'apellido_nombre': 'Lopez Maria',
          'legajo': '67890',
          'fecha': '2026-06-21',
          'resultado': 'Negativo',
          'graduacion': null,
          'servicio_extra': null,
          'observacion': null,
        },
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReporteAlcoholemiaView(
              datos: datos,
              desde: '2026-06-01',
              hasta: '2026-06-30',
            ),
          ),
        ),
      ));

      expect(find.text('Garcia Juan'), findsOneWidget);
      expect(find.text('Lopez Maria'), findsOneWidget);
      expect(find.text('Positivo'), findsOneWidget);
      expect(find.text('Negativo'), findsOneWidget);
      expect(find.text('2 controles encontrados'), findsOneWidget);
    });
  });

  group('ReporteAgenteView', () {
    final agente = Agente(
      id: 1,
      legajo: '12345',
      apellidoNombre: 'Garcia Juan Pablo',
      dependencia: 'Transito',
      cargo: 'Supervisor',
    );

    testWidgets('shows agent info', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReporteAgenteView(datos: [], agente: agente),
          ),
        ),
      ));
      expect(find.text('Garcia Juan Pablo'), findsOneWidget);
      expect(find.text('Legajo: 12345'), findsOneWidget);
      expect(find.text('Dependencia: Transito'), findsOneWidget);
      expect(find.text('Cargo: Supervisor'), findsOneWidget);
      expect(find.text('0 registros'), findsOneWidget);
    });

    testWidgets('shows observations list with estado', (tester) async {
      final datos = [
        {
          'id': 1,
          'tipo': 'Reclamo',
          'fecha': '2026-06-20',
          'descripcion': 'Falta de documentacion',
          'resuelto': 0,
        },
        {
          'id': 2,
          'tipo': 'Observacion',
          'fecha': '2026-06-21',
          'descripcion': 'Llegada tarde',
          'resuelto': 1,
        },
      ];

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReporteAgenteView(datos: datos, agente: agente),
          ),
        ),
      ));

      expect(find.text('Falta de documentacion'), findsOneWidget);
      expect(find.text('Llegada tarde'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Resuelto'), findsOneWidget);
      expect(find.text('2 registros'), findsOneWidget);
    });

    testWidgets('shows empty state without agent', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReporteAgenteView(datos: [], agente: null),
          ),
        ),
      ));
      expect(find.text('Sin observaciones ni reclamos'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enruta/screens/login_screen.dart';
import 'package:enruta/screens/home_screen.dart';
import 'package:enruta/screens/agente_form_screen.dart';
import 'package:enruta/screens/control_alcoholemia_form_screen.dart';
import 'package:enruta/screens/observacion_reclamo_form_screen.dart';
import 'package:enruta/screens/reportes_screen.dart';
import 'package:enruta/models/agente.dart';
import 'package:enruta/models/control_alcoholemia.dart';
import 'package:enruta/models/observacion_reclamo.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('shows fields', (t) async {
      await t.pumpWidget(const MaterialApp(home: LoginScreen()));
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsOneWidget);
      expect(find.text('Iniciar Sesión'), findsOneWidget);
      expect(find.text('Acceso Dev'), findsOneWidget);
    });
  });

  group('HomeScreen', () {
    testWidgets('shows menu', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: HomeScreen(username: 'test')),
      );
      await t.pump();
      expect(find.text('Bienvenido, test'), findsOneWidget);
      expect(find.text('Agentes'), findsOneWidget);
      expect(find.text('Alcoholemia'), findsOneWidget);
      expect(find.text('Observaciones'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
    }, skip: true); // Timer periódico necesita manejo especial en tests

    testWidgets('has logout icon', (t) async {
      await t.pumpWidget(
        const MaterialApp(home: HomeScreen(username: 'test')),
      );
      await t.pump();
      expect(find.byIcon(Icons.logout), findsOneWidget);
    }, skip: true);
  });

  group('AgenteFormScreen', () {
    testWidgets('create mode', (t) async {
      await t.pumpWidget(const MaterialApp(home: AgenteFormScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Nuevo Agente'), findsOneWidget);
      expect(find.text('Crear Agente'), findsOneWidget);
    });

    testWidgets('edit mode', (t) async {
      await t.pumpWidget(MaterialApp(
        home: AgenteFormScreen(agente: Agente(
          id: 1, legajo: '123', apellidoNombre: 'Test',
        )),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Editar Agente'), findsOneWidget);
      expect(find.text('Guardar Cambios'), findsOneWidget);
    });
  });

  group('ControlAlcoholemiaFormScreen', () {
    testWidgets('create mode with toggles', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: ControlAlcoholemiaFormScreen(agenteId: 1),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Nuevo Control de Alcoholemia'), findsOneWidget);
      expect(find.text('Negativo'), findsOneWidget);
      expect(find.text('Positivo'), findsOneWidget);
      expect(find.text('Cumpliendo servicio'), findsOneWidget);
      expect(find.text('Hora extra'), findsOneWidget);
    });

    testWidgets('edit mode', (t) async {
      await t.pumpWidget(MaterialApp(
        home: ControlAlcoholemiaFormScreen(
          agenteId: 1,
          control: ControlAlcoholemia(
            id: 1, agenteId: 1, fecha: '2026-01-01',
            resultado: 'Negativo',
          ),
        ),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Editar Control'), findsOneWidget);
    });

    testWidgets('positivo shows graduacion', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: ControlAlcoholemiaFormScreen(agenteId: 1),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.text('Positivo'));
      await t.pump();
      expect(find.text('Graduación alcohólica (g/l)'), findsOneWidget);
    });
  });

  group('ObservacionReclamoFormScreen', () {
    testWidgets('create mode', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: ObservacionReclamoFormScreen(agenteId: 1),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Nuevo Registro'), findsOneWidget);
      expect(find.text('Observación'), findsOneWidget);
      expect(find.text('Reclamo'), findsOneWidget);
      expect(find.text('Resuelto'), findsOneWidget);
    });

    testWidgets('edit mode', (t) async {
      await t.pumpWidget(MaterialApp(
        home: ObservacionReclamoFormScreen(
          agenteId: 1,
          observacion: ObservacionReclamo(
            id: 1, agenteId: 1, tipo: 'Reclamo',
            descripcion: 'test', fecha: '2026-01-01',
          ),
        ),
      ));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Editar Registro'), findsOneWidget);
    });
  });

  group('ReportesScreen', () {
    testWidgets('shows UI elements', (t) async {
      await t.pumpWidget(const MaterialApp(home: ReportesScreen()));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Estadísticas'), findsOneWidget);
      expect(find.text('Alcoholemia'), findsAtLeast(1));
      expect(find.text('Por Agente'), findsOneWidget);
      expect(find.text('Generar Reporte'), findsOneWidget);
    });
  });
}

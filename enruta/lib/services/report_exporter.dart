import 'dart:io';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ReportExporter {
  static Future<Directory> _getDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final reportDir = Directory('${dir.path}/reportes');
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }
    return reportDir;
  }

  static Future<void> _share(BuildContext context, String filePath) async {
    final xFile = XFile(filePath);
    final box = context.findRenderObject() as RenderBox?;
    final rect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 0, 0);
    await Share.shareXFiles(
      [xFile],
      text: 'Reporte',
      sharePositionOrigin: rect,
    );
  }

  static List<xls.CellValue> _row(List<String> values) {
    return values.map((v) => xls.TextCellValue(v)).toList();
  }

  static Future<void> exportAlcoholemiaPdf({
    required BuildContext context,
    required List<Map<String, dynamic>> datos,
    required String desde,
    required String hasta,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('Reporte de Alcoholemia',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Periodo: $desde - $hasta',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.Text('Total: ${datos.length} controles',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 16),
          if (datos.isEmpty)
            pw.Center(
                child: pw.Text('Sin datos en este periodo',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey)))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              headers: [
                'Agente',
                'Legajo',
                'Dependencia',
                'Cargo',
                'Turno',
                'Fecha',
                'Resultado',
                'Graduacion',
                'Servicio',
                'Observacion'
              ],
              data: datos.map((d) {
                return [
                  d['apellido_nombre']?.toString() ?? '',
                  d['legajo']?.toString() ?? '',
                  d['dependencia']?.toString() ?? '',
                  d['cargo']?.toString() ?? '',
                  d['turno']?.toString() ?? '',
                  d['fecha']?.toString() ?? '',
                  d['resultado']?.toString() ?? '',
                  d['graduacion'] != null
                      ? '${d['graduacion']} g/l'
                      : '-',
                  d['servicio_extra']?.toString() ?? '',
                  d['observacion']?.toString() ?? '',
                ];
              }).toList(),
            ),
        ],
      ),
    );

    final dir = await _getDir();
    final file =
        File('${dir.path}/alcoholemia_$desde-$hasta.pdf');
    await file.writeAsBytes(await pdf.save());
    await _share(context, file.path);
  }

  static Future<void> exportAlcoholemiaExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> datos,
    required String desde,
    required String hasta,
  }) async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Alcoholemia'];

    sheet.appendRow(_row(['Reporte de Alcoholemia']));
    sheet.appendRow(_row(['Periodo: $desde - $hasta']));
    sheet.appendRow(_row(['Total: ${datos.length} controles']));
    sheet.appendRow(_row([]));

    sheet.appendRow(_row([
      'Agente', 'Legajo', 'Dependencia', 'Cargo', 'Turno',
      'Fecha', 'Resultado', 'Graduacion (g/l)',
      'Servicio / Extra', 'Observacion',
    ]));

    for (final d in datos) {
      sheet.appendRow(_row([
        d['apellido_nombre']?.toString() ?? '',
        d['legajo']?.toString() ?? '',
        d['dependencia']?.toString() ?? '',
        d['cargo']?.toString() ?? '',
        d['turno']?.toString() ?? '',
        d['fecha']?.toString() ?? '',
        d['resultado']?.toString() ?? '',
        d['graduacion']?.toString() ?? '',
        d['servicio_extra']?.toString() ?? '',
        d['observacion']?.toString() ?? '',
      ]));
    }

    final dir = await _getDir();
    final file =
        File('${dir.path}/alcoholemia_$desde-$hasta.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await _share(context, file.path);
  }

  static Future<void> exportAgentePdf({
    required BuildContext context,
    required List<Map<String, dynamic>> datos,
    String? agenteNombre,
    String? agenteLegajo,
    String? dependencia,
    String? cargo,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (ctx) => [
          pw.Header(
            level: 0,
            child: pw.Text('Reporte por Agente',
                style: pw.TextStyle(
                    fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 8),
          pw.Text('$agenteNombre',
              style: pw.TextStyle(
                  fontSize: 14, fontWeight: pw.FontWeight.bold)),
          if (agenteLegajo != null)
            pw.Text('Legajo: $agenteLegajo',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey)),
          if (dependencia != null && dependencia.isNotEmpty)
            pw.Text('Dependencia: $dependencia',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey)),
          if (cargo != null && cargo.isNotEmpty)
            pw.Text('Cargo: $cargo',
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 4),
          pw.Text('Total: ${datos.length} registros',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
          pw.SizedBox(height: 16),
          if (datos.isEmpty)
            pw.Center(
                child: pw.Text('Sin observaciones ni reclamos',
                    style: const pw.TextStyle(
                        fontSize: 12, color: PdfColors.grey)))
          else
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 9),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              headers: ['Tipo', 'Fecha', 'Descripcion', 'Estado'],
              data: datos.map((d) {
                return [
                  d['tipo']?.toString() ?? '',
                  d['fecha']?.toString() ?? '',
                  d['descripcion']?.toString() ?? '',
                  (d['resuelto'] == 1) ? 'Resuelto' : 'Pendiente',
                ];
              }).toList(),
            ),
        ],
      ),
    );

    final dir = await _getDir();
    final sanitized =
        (agenteNombre ?? 'agente').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${dir.path}/agente_$sanitized.pdf');
    await file.writeAsBytes(await pdf.save());
    await _share(context, file.path);
  }

  static Future<void> exportAgenteExcel({
    required BuildContext context,
    required List<Map<String, dynamic>> datos,
    String? agenteNombre,
    String? agenteLegajo,
    String? dependencia,
    String? cargo,
  }) async {
    final excel = xls.Excel.createExcel();
    final sheet = excel['Observaciones'];

    sheet.appendRow(_row(['Reporte por Agente']));
    sheet.appendRow(_row(['$agenteNombre']));
    if (agenteLegajo != null) {
      sheet.appendRow(_row(['Legajo: $agenteLegajo']));
    }
    if (dependencia != null && dependencia.isNotEmpty) {
      sheet.appendRow(_row(['Dependencia: $dependencia']));
    }
    if (cargo != null && cargo.isNotEmpty) {
      sheet.appendRow(_row(['Cargo: $cargo']));
    }
    sheet.appendRow(_row(['Total: ${datos.length} registros']));
    sheet.appendRow(_row([]));

    sheet.appendRow(_row(['Tipo', 'Fecha', 'Descripcion', 'Estado']));

    for (final d in datos) {
      sheet.appendRow(_row([
        d['tipo']?.toString() ?? '',
        d['fecha']?.toString() ?? '',
        d['descripcion']?.toString() ?? '',
        (d['resuelto'] == 1) ? 'Resuelto' : 'Pendiente',
      ]));
    }

    final dir = await _getDir();
    final sanitized =
        (agenteNombre ?? 'agente').replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file =
        File('${dir.path}/agente_$sanitized.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await _share(context, file.path);
  }
}

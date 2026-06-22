import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../database/database_helper.dart';
import '../models/agente.dart';
import '../services/report_exporter.dart';
import 'reporte_alcoholemia_view.dart';
import 'reporte_agente_view.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _db = DatabaseHelper();
  String _tipoReporte = 'alcoholemia';
  String _fechaDesde = DateTime.now().toIso8601String().substring(0, 10);
  String _fechaHasta = DateTime.now().toIso8601String().substring(0, 10);
  int? _agenteSeleccionadoId;
  String? _agenteSeleccionadoNombre;
  Widget? _reporteGenerado;
  List<Map<String, dynamic>>? _reporteDatos;
  Agente? _reporteAgente;
  bool _exportando = false;

  Future<void> _seleccionarAgente() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SeleccionAgenteReporteScreen(),
      ),
    );

    if (resultado != null && mounted) {
      setState(() {
        _agenteSeleccionadoId = resultado['id'] as int;
        _agenteSeleccionadoNombre = resultado['nombre'] as String;
        _reporteGenerado = null;
      });
    }
  }

  Future<void> _seleccionarFechaDesde() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_fechaDesde) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Fecha desde',
    );
    if (picked != null) {
      setState(() {
        _fechaDesde = picked.toIso8601String().substring(0, 10);
        _reporteGenerado = null;
      });
    }
  }

  Future<void> _seleccionarFechaHasta() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_fechaHasta) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Fecha hasta',
    );
    if (picked != null) {
      setState(() {
        _fechaHasta = picked.toIso8601String().substring(0, 10);
        _reporteGenerado = null;
      });
    }
  }

  Future<void> _generarReporte() async {
    final desde = _fechaDesde;
    final hasta = _fechaHasta;

    if (_tipoReporte == 'alcoholemia') {
      final datos = await _db.getControlesReporteEntreFechas(desde, hasta);
      if (!mounted) return;
      setState(() {
        _reporteDatos = datos;
        _reporteAgente = null;
        _reporteGenerado = ReporteAlcoholemiaView(
          datos: datos,
          desde: desde,
          hasta: hasta,
        );
      });
    } else {
      if (_agenteSeleccionadoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seleccione un agente'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final datos =
          await _db.getObservacionesReporteByAgente(_agenteSeleccionadoId!);
      final agente = await _db.getAgenteById(_agenteSeleccionadoId!);
      if (!mounted) return;
      setState(() {
        _reporteDatos = datos;
        _reporteAgente = agente;
        _reporteGenerado = ReporteAgenteView(
          datos: datos,
          agente: agente,
        );
      });
    }
  }

  Future<void> _exportarPdf() async {
    if (_reporteDatos == null) return;
    setState(() => _exportando = true);
    try {
      if (_tipoReporte == 'alcoholemia') {
        await ReportExporter.exportAlcoholemiaPdf(
          context: context,
          datos: _reporteDatos!,
          desde: _fechaDesde,
          hasta: _fechaHasta,
        );
      } else {
        final a = _reporteAgente;
        await ReportExporter.exportAgentePdf(
          context: context,
          datos: _reporteDatos!,
          agenteNombre: a?.apellidoNombre,
          agenteLegajo: a?.legajo,
          dependencia: a?.dependencia,
          cargo: a?.cargo,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _exportando = false);
  }

  Future<void> _exportarExcel() async {
    if (_reporteDatos == null) return;
    setState(() => _exportando = true);
    try {
      if (_tipoReporte == 'alcoholemia') {
        await ReportExporter.exportAlcoholemiaExcel(
          context: context,
          datos: _reporteDatos!,
          desde: _fechaDesde,
          hasta: _fechaHasta,
        );
      } else {
        final a = _reporteAgente;
        await ReportExporter.exportAgenteExcel(
          context: context,
          datos: _reporteDatos!,
          agenteNombre: a?.apellidoNombre,
          agenteLegajo: a?.legajo,
          dependencia: a?.dependencia,
          cargo: a?.cargo,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _exportando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tipo de reporte',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TipoReporteCard(
                    label: 'Alcoholemia',
                    icon: Icons.air,
                    selected: _tipoReporte == 'alcoholemia',
                    onTap: () =>
                        setState(() => _tipoReporte = 'alcoholemia'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TipoReporteCard(
                    label: 'Por Agente',
                    icon: Icons.person_search,
                    selected: _tipoReporte == 'agente',
                    onTap: () =>
                        setState(() => _tipoReporte = 'agente'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Rango de fechas',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FechaButton(
                    label: 'Desde',
                    fecha: _fechaDesde,
                    onTap: _seleccionarFechaDesde,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FechaButton(
                    label: 'Hasta',
                    fecha: _fechaHasta,
                    onTap: _seleccionarFechaHasta,
                  ),
                ),
              ],
            ),
            if (_tipoReporte == 'agente') ...[
              const SizedBox(height: 16),
              const Text('Agente',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _seleccionarAgente,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person,
                          color: _agenteSeleccionadoNombre != null
                              ? AppColors.primary
                              : Colors.grey),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _agenteSeleccionadoNombre ??
                              'Seleccionar agente...',
                          style: TextStyle(
                            color: _agenteSeleccionadoNombre != null
                                ? AppColors.onSurface
                                : Colors.grey,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generarReporte,
              icon: const Icon(Icons.description, color: Colors.white),
              label: const Text('Generar Reporte'),
            ),
            if (_reporteGenerado != null) ...[
              const SizedBox(height: 20),
              _reporteGenerado!,
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportando ? null : _exportarPdf,
                      icon: _exportando
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.picture_as_pdf, color: Colors.red),
                      label: const Text('PDF',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportando ? null : _exportarExcel,
                      icon: _exportando
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : const Icon(Icons.table_chart,
                              color: Colors.green),
                      label: const Text('Excel',
                          style: TextStyle(color: Colors.green)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipoReporteCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TipoReporteCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? AppColors.primary : Colors.grey, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: selected
                    ? AppColors.primary
                    : AppColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FechaButton extends StatelessWidget {
  final String label;
  final String fecha;
  final VoidCallback onTap;

  const _FechaButton({
    required this.label,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(fecha,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SeleccionAgenteReporteScreen extends StatefulWidget {
  const SeleccionAgenteReporteScreen({super.key});

  @override
  State<SeleccionAgenteReporteScreen> createState() =>
      _SeleccionAgenteReporteScreenState();
}

class _SeleccionAgenteReporteScreenState
    extends State<SeleccionAgenteReporteScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _agentes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    _agentes = await _db.getAgentes().then(
        (list) => list.map((a) => {'id': a.id, 'nombre': a.apellidoNombre, 'legajo': a.legajo}).toList());
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Agente')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _agentes.length,
              itemBuilder: (context, index) {
                final a = _agentes[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.tertiary,
                    child: Text(
                      (a['nombre'] as String)
                          .split(' ')
                          .take(2)
                          .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                          .join(),
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                  title: Text(a['nombre'] as String),
                  subtitle: Text('Legajo: ${a['legajo']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, a),
                );
              },
            ),
    );
  }
}

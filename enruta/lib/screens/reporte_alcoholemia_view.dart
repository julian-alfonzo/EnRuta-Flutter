import 'package:flutter/material.dart';

import '../app_theme.dart';

class ReporteAlcoholemiaView extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final String desde;
  final String hasta;

  const ReporteAlcoholemiaView({
    super.key,
    required this.datos,
    required this.desde,
    required this.hasta,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reporte de Alcoholemia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Período: $desde — $hasta',
                  style: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                      fontSize: 13)),
              Text('${datos.length} controles encontrados',
                  style: TextStyle(
                      color: AppColors.onSurface.withValues(alpha: 0.5),
                      fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (datos.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('Sin controles en este período',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...datos.map((d) => _ControlCard(d: d)),
      ],
    );
  }
}

class _ControlCard extends StatelessWidget {
  final Map<String, dynamic> d;

  const _ControlCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final esPositivo = (d['resultado'] as String).toLowerCase() == 'positivo';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.tertiary,
                  child: Text(
                    (d['apellido_nombre'] as String)
                        .split(' ')
                        .take(2)
                        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                        .join(),
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d['apellido_nombre'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('Legajo: ${d['legajo']}',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.onSurface
                                  .withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: esPositivo
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d['resultado'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: esPositivo ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _ReporteRow('Fecha', d['fecha'] as String),
            if (esPositivo && d['graduacion'] != null)
              _ReporteRow('Graduación', '${d['graduacion']} g/l'),
            if (d['servicio_extra'] != null &&
                (d['servicio_extra'] as String).isNotEmpty)
              _ReporteRow('Situación', d['servicio_extra'] as String),
            if (d['observacion'] != null &&
                (d['observacion'] as String).isNotEmpty)
              _ReporteRow('Observación', d['observacion'] as String),
          ],
        ),
      ),
    );
  }
}

class _ReporteRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReporteRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
              child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

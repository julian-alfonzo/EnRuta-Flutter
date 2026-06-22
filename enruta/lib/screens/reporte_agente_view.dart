import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/agente.dart';

class ReporteAgenteView extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  final Agente? agente;

  const ReporteAgenteView({
    super.key,
    required this.datos,
    this.agente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (agente != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(agente!.apellidoNombre,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('Legajo: ${agente!.legajo}',
                    style: TextStyle(
                        color: AppColors.onSurface.withValues(alpha: 0.5),
                        fontSize: 13)),
                if (agente!.dependencia != null &&
                    agente!.dependencia!.isNotEmpty)
                  Text('Dependencia: ${agente!.dependencia}',
                      style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                          fontSize: 13)),
                if (agente!.cargo != null && agente!.cargo!.isNotEmpty)
                  Text('Cargo: ${agente!.cargo}',
                      style: TextStyle(
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                          fontSize: 13)),
                const SizedBox(height: 6),
                Text('${datos.length} registros',
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
              child: Text('Sin observaciones ni reclamos',
                  style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          ...datos.map((d) => _ObservacionCard(d: d)),
      ],
    );
  }
}

class _ObservacionCard extends StatelessWidget {
  final Map<String, dynamic> d;

  const _ObservacionCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final esReclamo = (d['tipo'] as String).toLowerCase() == 'reclamo';
    final resuelto = (d['resuelto'] as int) == 1;

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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: esReclamo
                        ? Colors.orange.withValues(alpha: 0.15)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d['tipo'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: esReclamo
                          ? Colors.orange.shade800
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: resuelto
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    resuelto ? 'Resuelto' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: resuelto ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  d['fecha'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(d['descripcion'] as String,
                style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

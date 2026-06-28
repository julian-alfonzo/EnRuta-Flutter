import 'package:flutter/material.dart';

import '../main.dart';
import '../app_theme.dart';
import '../database/database_helper.dart';
import '../models/agente.dart';
import '../models/control_alcoholemia.dart';
import '../models/observacion_reclamo.dart';
import '../services/api_client.dart';
import '../di/injection.dart';
import 'agente_form_screen.dart';
import 'control_alcoholemia_form_screen.dart';
import 'observacion_reclamo_form_screen.dart';

class AgenteDetailScreen extends StatefulWidget {
  final Agente agente;

  const AgenteDetailScreen({super.key, required this.agente});

  @override
  State<AgenteDetailScreen> createState() => _AgenteDetailScreenState();
}

class _AgenteDetailScreenState extends State<AgenteDetailScreen>
    with SingleTickerProviderStateMixin {
  final _db = databaseHelper;
  late TabController _tabController;
  late Agente _agente;
  List<ControlAlcoholemia> _controles = [];
  List<ObservacionReclamo> _observaciones = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _agente = widget.agente;
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    final agente = await _db.getAgenteById(_agente.id!);
    if (agente != null) _agente = agente;

    try {
      final result = await Future.wait([
        apiClient.getAlcoholemiasByLegajo(_agente.legajo),
        apiClient.getObservacionesByLegajo(_agente.legajo),
      ]);
      final controlesData = result[0]['data'] as List<dynamic>? ?? [];
      final observacionesData = result[1]['data'] as List<dynamic>? ?? [];
      _controles = controlesData
          .map((j) => ControlAlcoholemia.fromApiJson(j as Map<String, dynamic>))
          .toList();
      _observaciones = observacionesData
          .map((j) => ObservacionReclamo.fromApiJson(j as Map<String, dynamic>))
          .toList();
    } on ApiException {
      final controles = await _db.getControlesByAgente(_agente.id!);
      final observaciones = await _db.getObservacionesReclamosByAgente(_agente.id!);
      _controles = controles;
      _observaciones = observaciones;
    } catch (_) {
      final controles = await _db.getControlesByAgente(_agente.id!);
      final observaciones = await _db.getObservacionesReclamosByAgente(_agente.id!);
      _controles = controles;
      _observaciones = observaciones;
    }

    setState(() => _loading = false);
  }

  Future<void> _irAEditarAgente() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AgenteFormScreen(agente: _agente),
      ),
    );
    if (result == true) _cargarDatos();
  }

  Future<void> _irAFormAlcoholemia({ControlAlcoholemia? control}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ControlAlcoholemiaFormScreen(
          agenteId: _agente.id!,
          control: control,
        ),
      ),
    );
    if (result == true) _cargarDatos();
  }

  Future<void> _irAFormObservacion({ObservacionReclamo? obs}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ObservacionReclamoFormScreen(
          agenteId: _agente.id!,
          observacion: obs,
        ),
      ),
    );
    if (result == true) _cargarDatos();
  }

  Future<void> _eliminarControl(ControlAlcoholemia c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar control'),
        content: Text('¿Eliminar control del ${c.fecha}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await apiService.deleteControl(c.id!);
      _cargarDatos();
    }
  }

  Future<void> _eliminarObservacion(ObservacionReclamo o) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: Text('¿Eliminar ${o.tipo.toLowerCase()} del ${o.fecha}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await apiService.deleteObservacion(o.id!);
      _cargarDatos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_agente.apellidoNombre),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar agente',
            onPressed: _irAEditarAgente,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurface.withValues(alpha: 0.5),
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Perfil'),
            Tab(text: 'Alcoholemia'),
            Tab(text: 'Obs. / Reclamos'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPerfilTab(),
                _buildAlcoholemiaTab(),
                _buildObservacionesTab(),
              ],
            ),
    );
  }

  Widget _buildPerfilTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.tertiary,
            child: Text(
              _agente.apellidoNombre
                  .split(' ')
                  .take(2)
                  .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                  .join(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _agente.apellidoNombre,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Legajo: ${_agente.legajo}',
            style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.5),
                fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildInfoCard([
            _InfoItem('Legajo', _agente.legajo),
            _InfoItem('Fecha Ingreso', _agente.fechaIngreso ?? '-'),
            _InfoItem('Dependencia', _agente.dependencia ?? '-'),
            _InfoItem('Cargo', _agente.cargo ?? '-'),
            _InfoItem('Turno', _agente.turno ?? '-'),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoItem> items) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item.value,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlcoholemiaTab() {
    if (_controles.isEmpty) {
      return Center(
        child: Text(
          'Sin controles registrados',
          style:
              TextStyle(color: AppColors.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _controles.length,
      itemBuilder: (context, index) {
        final c = _controles[index];
        final esPositivo = c.resultado.toLowerCase() == 'positivo';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _irAFormAlcoholemia(control: c),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14,
                          color: AppColors.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 6),
                      Text(
                        c.fecha,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: esPositivo
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          c.resultado,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: esPositivo ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _eliminarControl(c),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  if (esPositivo && c.graduacion != null) ...[
                    const SizedBox(height: 6),
                    Text('Graduación: ${c.graduacion} g/l',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                  if (c.servicioExtra != null && c.servicioExtra!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(c.servicioExtra!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        )),
                  ],
                  if (c.observacion != null && c.observacion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(c.observacion!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildObservacionesTab() {
    if (_observaciones.isEmpty) {
      return Center(
        child: Text(
          'Sin observaciones ni reclamos',
          style:
              TextStyle(color: AppColors.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _observaciones.length,
      itemBuilder: (context, index) {
        final o = _observaciones[index];
        final esReclamo = o.tipo.toLowerCase() == 'reclamo';
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _irAFormObservacion(obs: o),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: esReclamo
                              ? Colors.orange.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          o.tipo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                esReclamo ? Colors.orange.shade800 : AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.calendar_today,
                          size: 13,
                          color: AppColors.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        o.fecha,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => _eliminarObservacion(o),
                        child: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.redAccent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    o.descripcion,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

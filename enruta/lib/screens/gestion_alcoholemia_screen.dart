import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../database/database_helper.dart';
import '../main.dart';
import '../models/control_alcoholemia.dart';
import '../services/api_client.dart';
import 'control_alcoholemia_form_screen.dart';
import 'seleccion_agente_screen.dart';

class GestionAlcoholemiaScreen extends StatefulWidget {
  const GestionAlcoholemiaScreen({super.key});

  @override
  State<GestionAlcoholemiaScreen> createState() =>
      _GestionAlcoholemiaScreenState();
}

class _GestionAlcoholemiaScreenState extends State<GestionAlcoholemiaScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  final _desdeController = TextEditingController();
  final _hastaController = TextEditingController();

  List<Map<String, dynamic>> _resultados = [];
  bool _loading = false;
  bool _offline = false;

  @override
  void dispose() {
    _searchController.dispose();
    _desdeController.dispose();
    _hastaController.dispose();
    super.dispose();
  }

  Future<void> _buscar() async {
    final search = _searchController.text.trim();
    final desde = _desdeController.text.trim();
    final hasta = _hastaController.text.trim();

    setState(() {
      _loading = true;
      _offline = false;
    });

    try {
      final api = AppServices.instance.apiClient;
      final response = await api.getAlcoholemias(
        search: search.isNotEmpty ? search : null,
        desde: desde.isNotEmpty ? desde : null,
        hasta: hasta.isNotEmpty ? hasta : null,
      );
      final data = response['data'] as List<dynamic>? ?? [];
      final resultados = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      await _enriquecerConAgenteLocal(resultados);
      setState(() {
        _resultados = resultados;
        _loading = false;
      });
    } on ApiException {
      await _buscarLocal(desde, hasta, search);
    } catch (_) {
      await _buscarLocal(desde, hasta, search);
    }
  }

  Future<void> _buscarLocal(String desde, String hasta, String search) async {
    List<Map<String, dynamic>> results;
    if (desde.isNotEmpty && hasta.isNotEmpty) {
      results = await _db.getControlesReporteEntreFechas(desde, hasta);
    } else {
      results = await _db.getControlesReporteEntreFechas('2000-01-01', '2099-12-31');
    }

    if (search.isNotEmpty) {
      final q = search.toLowerCase();
      results = results.where((r) {
        final nombre = (r['apellido_nombre'] as String? ?? '').toLowerCase();
        final legajo = (r['legajo'] as String? ?? '').toLowerCase();
        return nombre.contains(q) || legajo.contains(q);
      }).toList();
    }

    setState(() {
      _resultados = results;
      _loading = false;
      _offline = true;
    });
  }

  Future<void> _enriquecerConAgenteLocal(List<Map<String, dynamic>> resultados) async {
    for (final item in resultados) {
      final tieneNombre = (item['apellidoNombre'] ?? item['apellido_nombre']) != null;
      final tieneLegajo = item['legajo'] != null;
      if (tieneNombre && tieneLegajo) continue;

      final agenteId = item['agenteId'] as int? ?? item['agente_id'] as int?;
      if (agenteId == null) continue;

      final agente = await _db.getAgenteById(agenteId);
      if (agente != null) {
        if (!tieneNombre) {
          item['apellido_nombre'] = agente.apellidoNombre;
        }
        if (!tieneLegajo) {
          item['legajo'] = agente.legajo;
        }
      }
    }
  }

  Future<void> _seleccionarFecha(bool esDesde) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      helpText: esDesde ? 'Fecha desde' : 'Fecha hasta',
    );
    if (picked != null) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      if (esDesde) {
        _desdeController.text = formatted;
      } else {
        _hastaController.text = formatted;
      }
    }
  }

  Future<void> _irAFormulario({ControlAlcoholemia? control}) async {
    if (control != null) {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ControlAlcoholemiaFormScreen(
            agenteId: control.agenteId,
            control: control,
          ),
        ),
      );
      if (result == true) _buscar();
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SeleccionAgenteScreen(destino: 'alcoholemia'),
        ),
      );
      _buscar();
    }
  }

  Future<void> _eliminarControl(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    final nombre = item['apellidoNombre'] as String? ??
        item['apellido_nombre'] as String? ??
        'Desconocido';
    final fecha = item['fecha'] as String? ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar control'),
        content: Text('¿Eliminar control de $nombre del $fecha?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await AppServices.instance.apiService.deleteControl(id);
      _buscar();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Controles de Alcoholemia')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irAFormulario(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_offline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.orange.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Text(
                    'Resultados locales (sin conexión)',
                    style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Text(
                  '${_resultados.length} controles encontrados',
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                    ? Center(
                        child: Text(
                          'Sin resultados. Buscá por fecha o agente.',
                          style: TextStyle(
                            color: AppColors.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _buscar,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _resultados.length,
                          itemBuilder: (context, index) {
                            final item = _resultados[index];
                            return _ControlCard(
                              item: item,
                              onEdit: () {
                                final agenteId = item['agenteId'] as int? ??
                                    item['agente_id'] as int?;
                                if (agenteId == null) return;
                                final control = ControlAlcoholemia(
                                  id: item['id'] as int?,
                                  agenteId: agenteId,
                                  fecha: item['fecha'] as String? ?? '',
                                  resultado: item['resultado'] as String? ?? 'Negativo',
                                  graduacion: (item['graduacion'] as num?)?.toDouble(),
                                  servicioExtra: item['servicioExtra'] as String? ??
                                      item['servicio_extra'] as String?,
                                  observacion: item['observacion'] as String?,
                                );
                                _irAFormulario(control: control);
                              },
                              onDelete: () => _eliminarControl(item),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Buscar por agente (nombre o legajo)',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onSubmitted: (_) => _buscar(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: TextField(
                  controller: _desdeController,
                  decoration: const InputDecoration(
                    hintText: 'Desde',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                    isDense: true,
                  ),
                  onTap: () => _seleccionarFecha(true),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: TextField(
                  controller: _hastaController,
                  decoration: const InputDecoration(
                    hintText: 'Hasta',
                    prefixIcon: Icon(Icons.calendar_today, size: 18),
                    isDense: true,
                  ),
                  onTap: () => _seleccionarFecha(false),
                  readOnly: true,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                height: 40,
                child: ElevatedButton(
                  onPressed: _loading ? null : _buscar,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Buscar', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ControlCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nombre = item['apellidoNombre'] as String? ??
        item['apellido_nombre'] as String? ??
        'Desconocido';
    final legajo = item['legajo'] as String? ?? '-';
    final fecha = item['fecha'] as String? ?? '';
    final resultado = item['resultado'] as String? ?? 'Negativo';
    final graduacion = item['graduacion'];
    final esPositivo = resultado.toLowerCase() == 'positivo';
    final servicio = item['servicioExtra'] as String? ??
        item['servicio_extra'] as String?;
    final observacion = item['observacion'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Legajo: $legajo',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                      resultado,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: esPositivo ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.delete_outline,
                          size: 20, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
              if (fecha.isNotEmpty || graduacion != null || servicio != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (fecha.isNotEmpty) ...[
                      Icon(Icons.calendar_today,
                          size: 13,
                          color: AppColors.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        fecha,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    if (graduacion != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.science,
                          size: 13,
                          color: AppColors.onSurface.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        '$graduacion g/l',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (servicio != null && servicio.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          servicio,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              if (observacion != null && observacion.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  observacion,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

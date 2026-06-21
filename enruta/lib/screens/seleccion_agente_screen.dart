import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../database/database_helper.dart';
import '../models/agente.dart';
import 'control_alcoholemia_form_screen.dart';
import 'observacion_reclamo_form_screen.dart';

class SeleccionAgenteScreen extends StatefulWidget {
  final String destino;

  const SeleccionAgenteScreen({super.key, required this.destino});

  @override
  State<SeleccionAgenteScreen> createState() => _SeleccionAgenteScreenState();
}

class _SeleccionAgenteScreenState extends State<SeleccionAgenteScreen> {
  final _db = DatabaseHelper();
  final _searchController = TextEditingController();
  List<Agente> _agentes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarAgentes();
  }

  Future<void> _cargarAgentes() async {
    setState(() => _loading = true);
    final agentes = await _db.getAgentes();
    setState(() {
      _agentes = agentes;
      _loading = false;
    });
  }

  Future<void> _buscar(String query) async {
    setState(() => _loading = true);
    final agentes = query.isEmpty
        ? await _db.getAgentes()
        : await _db.buscarAgentes(query);
    setState(() {
      _agentes = agentes;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esAlcoholemia = widget.destino == 'alcoholemia';
    return Scaffold(
      appBar: AppBar(
        title: Text(esAlcoholemia
            ? 'Nuevo Control de Alcoholemia'
            : 'Nueva Observación / Reclamo'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar agente...',
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _buscar,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Seleccione un agente',
              style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _agentes.isEmpty
                    ? Center(
                        child: Text(
                          'No se encontraron agentes',
                          style: TextStyle(
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _agentes.length,
                        itemBuilder: (context, index) {
                          final a = _agentes[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.tertiary,
                                child: Text(
                                  a.apellidoNombre
                                      .split(' ')
                                      .take(2)
                                      .map((e) => e.isNotEmpty
                                          ? e[0].toUpperCase()
                                          : '')
                                      .join(),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              title: Text(a.apellidoNombre,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('Legajo: ${a.legajo}'),
                              trailing: const Icon(Icons.chevron_right),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              onTap: () {
                                final destino = esAlcoholemia
                                    ? MaterialPageRoute(
                                        builder: (_) =>
                                            ControlAlcoholemiaFormScreen(
                                              agenteId: a.id!,
                                            ),
                                      )
                                    : MaterialPageRoute(
                                        builder: (_) =>
                                            ObservacionReclamoFormScreen(
                                              agenteId: a.id!,
                                            ),
                                      );
                                Navigator.push(context, destino);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

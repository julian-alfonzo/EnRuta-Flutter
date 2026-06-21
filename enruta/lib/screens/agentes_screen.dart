import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../database/database_helper.dart';
import '../models/agente.dart';
import 'agente_detail_screen.dart';
import 'agente_form_screen.dart';

class AgentesScreen extends StatefulWidget {
  const AgentesScreen({super.key});

  @override
  State<AgentesScreen> createState() => _AgentesScreenState();
}

class _AgentesScreenState extends State<AgentesScreen> {
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

  Future<void> _eliminarAgente(Agente agente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Agente'),
        content: Text('¿Eliminar a ${agente.apellidoNombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _db.deleteAgente(agente.id!);
      _cargarAgentes();
    }
  }

  Future<void> _irADetalle(Agente agente) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AgenteDetailScreen(agente: agente),
      ),
    );
    _cargarAgentes();
  }

  Future<void> _irAFormulario({Agente? agente}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AgenteFormScreen(agente: agente),
      ),
    );

    if (resultado == true) {
      _cargarAgentes();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentes'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por legajo, nombre o dependencia',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _buscar,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '${_agentes.length} agentes',
                  style: TextStyle(
                    color: AppColors.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
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
                    : RefreshIndicator(
                        onRefresh: _cargarAgentes,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: _agentes.length,
                          itemBuilder: (context, index) {
                            return _AgenteCard(
                              agente: _agentes[index],
                              onTap: () => _irADetalle(_agentes[index]),
                              onDelete: () =>
                                  _eliminarAgente(_agentes[index]),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _irAFormulario(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _AgenteCard extends StatelessWidget {
  final Agente agente;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AgenteCard({
    required this.agente,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.tertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        agente.apellidoNombre
                            .split(' ')
                            .take(2)
                            .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
                            .join(),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agente.apellidoNombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Legajo: ${agente.legajo}',
                          style: TextStyle(
                            color: AppColors.onSurface.withValues(alpha: 0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent, size: 20),
                    onPressed: onDelete,
                  ),
                ],
              ),
              if (agente.dependencia != null &&
                  agente.dependencia!.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                _InfoRow(
                    icon: Icons.business, text: agente.dependencia!),
              ],
              if (agente.cargo != null && agente.cargo!.isNotEmpty)
                _InfoRow(icon: Icons.badge, text: agente.cargo!),
              if (agente.turno != null && agente.turno!.isNotEmpty)
                _InfoRow(
                    icon: Icons.schedule, text: agente.turno!),
              if (agente.fechaIngreso != null &&
                  agente.fechaIngreso!.isNotEmpty)
                _InfoRow(
                    icon: Icons.calendar_today,
                    text: 'Ingreso: ${agente.fechaIngreso}'),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurface.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

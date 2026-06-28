import 'dart:async';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../main.dart';
import '../di/injection.dart';
import '../services/api_client.dart';
import 'agentes_screen.dart';
import 'gestion_alcoholemia_screen.dart';
import 'login_screen.dart';
import 'reportes_screen.dart';
import 'seleccion_agente_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;

  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _statusTimer;
  bool _conectado = false;
  int _pendientes = 0;
  int _fallidos = 0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkStatus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      await apiClient.getAgentes(limit: 1);
      _conectado = true;
    } on ApiException catch (e) {
      _conectado = e.statusCode >= 400 && e.statusCode < 500;
    } catch (_) {
      _conectado = false;
    }
    _pendientes = await syncService.pendingCount;
    _fallidos = await syncService.failedCount;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EnRuta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido, ${widget.username}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _StatusBar(
              conectado: _conectado,
              pendientes: _pendientes,
              fallidos: _fallidos,
            ),
            const SizedBox(height: 16),
            Text(
              'Seleccione una opción',
              style: TextStyle(
                color: AppColors.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _MenuCard(
                    icon: Icons.people,
                    label: 'Agentes',
                    subtitle: 'Gestión de agentes',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AgentesScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.air,
                    label: 'Alcoholemia',
                    subtitle: 'Buscar y gestionar',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const GestionAlcoholemiaScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.feedback,
                    label: 'Observaciones',
                    subtitle: 'Reclamos y notas',
                    color: const Color(0xFFF2A20C),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SeleccionAgenteScreen(
                              destino: 'observaciones'),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.assessment,
                    label: 'Estadísticas',
                    subtitle: 'Alcoholemia y agentes',
                    color: const Color(0xFF7B1FA2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReportesScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final bool conectado;
  final int pendientes;
  final int fallidos;

  const _StatusBar({
    required this.conectado,
    required this.pendientes,
    required this.fallidos,
  });

  Color get _color {
    if (!conectado) return Colors.red;
    if (pendientes > 0 || fallidos > 0) return Colors.orange;
    return Colors.green;
  }

  String get _texto {
    if (!conectado) return 'Offline — datos locales';
    final parts = <String>[];
    if (pendientes > 0) parts.add('$pendientes pendientes');
    if (fallidos > 0) parts.add('$fallidos fallidos');
    if (parts.isEmpty) return 'Conectado — sincronizado';
    return 'Conectado — ${parts.join(', ')}';
  }

  IconData get _icon {
    if (!conectado) return Icons.cloud_off;
    if (pendientes > 0 || fallidos > 0) return Icons.sync;
    return Icons.cloud_done;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: _color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _texto,
              style: TextStyle(
                fontSize: 12,
                color: _color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.onSurface.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

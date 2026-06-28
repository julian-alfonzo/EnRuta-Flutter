import 'package:flutter/material.dart';

import '../main.dart';
import '../app_theme.dart';
import '../models/observacion_reclamo.dart';
import '../di/injection.dart';

class ObservacionReclamoFormScreen extends StatefulWidget {
  final int agenteId;
  final ObservacionReclamo? observacion;

  const ObservacionReclamoFormScreen({
    super.key,
    required this.agenteId,
    this.observacion,
  });

  @override
  State<ObservacionReclamoFormScreen> createState() =>
      _ObservacionReclamoFormScreenState();
}

class _ObservacionReclamoFormScreenState
    extends State<ObservacionReclamoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _tipo;
  late bool _resuelto;
  late final TextEditingController _fechaController;
  late final TextEditingController _descripcionController;
  bool _guardando = false;

  bool get _esEdicion => widget.observacion != null;

  @override
  void initState() {
    super.initState();
    final o = widget.observacion;
    _tipo = o?.tipo ?? 'Observación';
    _resuelto = o?.resuelto ?? false;
    _fechaController = TextEditingController(
        text: o?.fecha ??
            DateTime.now().toIso8601String().substring(0, 10));
    _descripcionController =
        TextEditingController(text: o?.descripcion ?? '');
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final or = ObservacionReclamo(
      id: widget.observacion?.id,
      agenteId: widget.agenteId,
      tipo: _tipo,
      descripcion: _descripcionController.text.trim(),
      fecha: _fechaController.text.trim(),
      resuelto: _resuelto,
    );

    try {
      if (_esEdicion) {
        await apiService.updateObservacion(or);
      } else {
        await apiService.createObservacion(or);
      }
      if (mounted) Navigator.pop(context, true);
    } on Exception catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Registro' : 'Nuevo Registro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tipo',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TipoToggleButton(
                      label: 'Observación',
                      selected: _tipo == 'Observación',
                      selectedColor: AppColors.primary,
                      icon: Icons.visibility,
                      onTap: () =>
                          setState(() => _tipo = 'Observación'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TipoToggleButton(
                      label: 'Reclamo',
                      selected: _tipo == 'Reclamo',
                      selectedColor: Colors.orange.shade800,
                      icon: Icons.report_problem,
                      onTap: () => setState(() => _tipo = 'Reclamo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: 'AAAA-MM-DD',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'La fecha es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: _tipo == 'Reclamo'
                      ? 'Descripción del reclamo'
                      : 'Descripción de la observación',
                  prefixIcon: Icon(_tipo == 'Reclamo'
                      ? Icons.report_problem
                      : Icons.visibility),
                  hintText: 'Escriba los detalles...',
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'La descripción es obligatoria';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _resuelto ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: _resuelto ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text('Resuelto',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Switch(
                    value: _resuelto,
                    activeThumbColor: Colors.green,
                    onChanged: (v) => setState(() => _resuelto = v),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_esEdicion
                        ? 'Guardar Cambios'
                        : 'Registrar ${_tipo == "Reclamo" ? "Reclamo" : "Observación"}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipoToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final IconData icon;
  final VoidCallback onTap;

  const _TipoToggleButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.icon,
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
              ? selectedColor.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? selectedColor : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
                color: selected
                    ? selectedColor
                    : AppColors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

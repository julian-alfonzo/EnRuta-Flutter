import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../database/database_helper.dart';
import '../models/agente.dart';
import '../models/control_alcoholemia.dart';

class ControlAlcoholemiaFormScreen extends StatefulWidget {
  final int agenteId;
  final ControlAlcoholemia? control;

  const ControlAlcoholemiaFormScreen({
    super.key,
    required this.agenteId,
    this.control,
  });

  @override
  State<ControlAlcoholemiaFormScreen> createState() =>
      _ControlAlcoholemiaFormScreenState();
}

class _ControlAlcoholemiaFormScreenState
    extends State<ControlAlcoholemiaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late String _resultado;
  late String _servicioExtra;
  late final TextEditingController _fechaController;
  late final TextEditingController _graduacionController;
  late final TextEditingController _observacionController;
  Agente? _agente;
  bool _guardando = false;

  bool get _esEdicion => widget.control != null;
  bool get _esPositivo => _resultado == 'Positivo';

  @override
  void initState() {
    super.initState();
    _cargarAgente();
    final c = widget.control;
    _resultado = c?.resultado ?? 'Negativo';
    _servicioExtra = c?.servicioExtra ?? 'Cumpliendo servicio';
    _fechaController = TextEditingController(
        text: c?.fecha ??
            DateTime.now().toIso8601String().substring(0, 10));
    _graduacionController = TextEditingController(
        text: c?.graduacion?.toString() ?? '');
    _observacionController = TextEditingController(
        text: c?.observacion ?? '');
  }

  Future<void> _cargarAgente() async {
    _agente = await _db.getAgenteById(widget.agenteId);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _fechaController.dispose();
    _graduacionController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final control = ControlAlcoholemia(
      id: widget.control?.id,
      agenteId: widget.agenteId,
      fecha: _fechaController.text.trim(),
      resultado: _resultado,
      graduacion:
          _esPositivo && _graduacionController.text.trim().isNotEmpty
              ? double.tryParse(_graduacionController.text.trim())
              : null,
      servicioExtra: _servicioExtra,
      observacion: _observacionController.text.trim(),
    );

    try {
      if (_esEdicion) {
        await _db.updateControl(control);
      } else {
        await _db.insertControl(control);
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
        title:
            Text(_esEdicion ? 'Editar Control' : 'Nuevo Control de Alcoholemia'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_agente != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                      Text(
                        _agente!.apellidoNombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Legajo: ${_agente!.legajo}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              const Text('Resultado',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Negativo',
                      selected: _resultado == 'Negativo',
                      selectedColor: Colors.green,
                      onTap: () => setState(() => _resultado = 'Negativo'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Positivo',
                      selected: _resultado == 'Positivo',
                      selectedColor: Colors.red,
                      onTap: () => setState(() => _resultado = 'Positivo'),
                    ),
                  ),
                ],
              ),
              if (_esPositivo) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _graduacionController,
                  decoration: const InputDecoration(
                    labelText: 'Graduación alcohólica (g/l)',
                    prefixIcon: Icon(Icons.science),
                    hintText: '0.50',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (_esPositivo &&
                        (v == null || v.trim().isEmpty)) {
                      return 'Ingrese la graduación';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              const Text('Situación de servicio',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Cumpliendo servicio',
                      selected: _servicioExtra == 'Cumpliendo servicio',
                      selectedColor: AppColors.primary,
                      onTap: () => setState(
                          () => _servicioExtra = 'Cumpliendo servicio'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Hora extra',
                      selected: _servicioExtra == 'Hora extra',
                      selectedColor: Colors.orange,
                      onTap: () => setState(
                          () => _servicioExtra = 'Hora extra'),
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
                controller: _observacionController,
                decoration: const InputDecoration(
                  labelText: 'Observación',
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Observaciones del control...',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
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
                        : 'Registrar Control'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? selectedColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
              color: selected
                  ? selectedColor
                  : AppColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}

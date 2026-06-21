import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../models/agente.dart';

class AgenteFormScreen extends StatefulWidget {
  final Agente? agente;

  const AgenteFormScreen({super.key, this.agente});

  @override
  State<AgenteFormScreen> createState() => _AgenteFormScreenState();
}

class _AgenteFormScreenState extends State<AgenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseHelper();

  late final TextEditingController _legajoController;
  late final TextEditingController _nombreController;
  late final TextEditingController _fechaIngresoController;
  late final TextEditingController _dependenciaController;
  late final TextEditingController _cargoController;
  late final TextEditingController _turnoController;

  bool _guardando = false;

  bool get _esEdicion => widget.agente != null;

  @override
  void initState() {
    super.initState();
    final a = widget.agente;
    _legajoController = TextEditingController(text: a?.legajo ?? '');
    _nombreController =
        TextEditingController(text: a?.apellidoNombre ?? '');
    _fechaIngresoController =
        TextEditingController(text: a?.fechaIngreso ?? '');
    _dependenciaController =
        TextEditingController(text: a?.dependencia ?? '');
    _cargoController = TextEditingController(text: a?.cargo ?? '');
    _turnoController = TextEditingController(text: a?.turno ?? '');
  }

  @override
  void dispose() {
    _legajoController.dispose();
    _nombreController.dispose();
    _fechaIngresoController.dispose();
    _dependenciaController.dispose();
    _cargoController.dispose();
    _turnoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    final legajo = _legajoController.text.trim();
    final agente = Agente(
      id: widget.agente?.id,
      legajo: legajo,
      apellidoNombre: _nombreController.text.trim(),
      fechaIngreso: _fechaIngresoController.text.trim(),
      dependencia: _dependenciaController.text.trim(),
      cargo: _cargoController.text.trim(),
      turno: _turnoController.text.trim(),
    );

    try {
      if (_esEdicion) {
        await _db.updateAgente(agente);
      } else {
        await _db.insertAgente(agente);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Agente' : 'Nuevo Agente'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _legajoController,
                decoration: const InputDecoration(
                  labelText: 'Legajo',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El legajo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Apellido y Nombres',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El nombre es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fechaIngresoController,
                decoration: const InputDecoration(
                  labelText: 'Fecha de Ingreso (dd/mm/aa)',
                  prefixIcon: Icon(Icons.calendar_today),
                  hintText: '01/01/25',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dependenciaController,
                decoration: const InputDecoration(
                  labelText: 'Dependencia',
                  prefixIcon: Icon(Icons.business),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cargoController,
                decoration: const InputDecoration(
                  labelText: 'Cargo',
                  prefixIcon: Icon(Icons.work),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _turnoController,
                decoration: const InputDecoration(
                  labelText: 'Turno',
                  prefixIcon: Icon(Icons.schedule),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_esEdicion ? 'Guardar Cambios' : 'Crear Agente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import '../database/database_helper.dart';
import '../models/agente.dart';
import '../models/control_alcoholemia.dart';
import '../models/observacion_reclamo.dart';
import 'api_client.dart';
import 'sync_service.dart';

class ApiService {
  final ApiClient _api;
  final DatabaseHelper _db;
  final SyncService _sync;
  final Map<int, int> _localToServerId = {};

  ApiService({
    required String baseUrl,
    ApiClient? apiClient,
    SyncService? syncService,
  })  : _api = apiClient ?? ApiClient(baseUrl: baseUrl),
        _db = DatabaseHelper(),
        _sync = syncService ?? SyncService();

  ApiClient get client => _api;

  Future<void> dispose() {
    _api.dispose();
    return Future.value();
  }

  // ── Auth ──

  Future<int?> _resolveServerAgentId(int localId) async {
    if (_localToServerId.containsKey(localId)) {
      return _localToServerId[localId];
    }
    try {
      final local = await _db.getAgenteById(localId);
      if (local == null) return null;
      final response = await _api.getAgenteByLegajo(local.legajo);
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        final serverId = data['id'] as int;
        _localToServerId[localId] = serverId;
        return serverId;
      }
    } on ApiException {
      // sin conexión
    }
    return null;
  }

  Future<bool> login(String usuario, String password) async {
    try {
      await _api.login(usuario, password);
      return true;
    } on ApiException {
      rethrow;
    }
  }

  void logout() {
    _api.clearTokens();
  }

  bool get isAuthenticated => _api.isAuthenticated;

  // ── Agentes (online) ──

  Future<List<Agente>> fetchAgentes({String? search, int page = 1}) async {
    final response = await _api.getAgentes(search: search, page: page);
    final data = response['data'] as List<dynamic>;
    return data.map((json) => Agente.fromMap(_fromApiAgente(json))).toList();
  }

  Map<String, dynamic> _fromApiAgente(dynamic json) {
    final map = json is Map<String, dynamic> ? json : jsonDecode(jsonEncode(json)) as Map<String, dynamic>;
    return {
      'id': map['id'] as int?,
      'legajo': map['legajo'] as String,
      'apellido_nombre': map['apellidoNombre'] as String,
      'fecha_ingreso': map['fechaIngreso'] as String?,
      'dependencia': map['dependencia'] as String?,
      'cargo': map['cargo'] as String?,
      'turno': map['turno'] as String?,
      'created_at': map['createdAt'] as String?,
      'updated_at': map['updatedAt'] as String?,
    };
  }

  Map<String, dynamic> _toApiAgente(Agente a) {
    return {
      'legajo': a.legajo,
      'apellidoNombre': a.apellidoNombre,
      'fechaIngreso': a.fechaIngreso,
      'dependencia': a.dependencia,
      'cargo': a.cargo,
      'turno': a.turno,
    };
  }

  Map<String, dynamic> _toApiAlcoholemia(ControlAlcoholemia c) {
    return {
      'fecha': c.fecha,
      'resultado': c.resultado,
      'graduacion': c.graduacion,
      'servicioExtra': c.servicioExtra,
      'observacion': c.observacion,
    };
  }

  Map<String, dynamic> _toApiObservacion(ObservacionReclamo o) {
    return {
      'tipo': o.tipo,
      'descripcion': o.descripcion,
      'fecha': o.fecha,
      'resuelto': o.resuelto,
    };
  }

  Future<void> createAgenteOnline(Agente agente) async {
    await _api.createAgente(_toApiAgente(agente));
  }

  Future<void> updateAgenteOnline(Agente agente) async {
    await _api.updateAgente(agente.id!, _toApiAgente(agente));
  }

  Future<void> deleteAgenteOnline(int id) async {
    await _api.deleteAgente(id);
  }

  // ── Controles Alcoholemia (online) ──

  Future<List<Map<String, dynamic>>> fetchReporteAlcoholemia({
    required String desde,
    required String hasta,
  }) async {
    final response =
        await _api.getReporteAlcoholemia(desde: desde, hasta: hasta);
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createAlcoholemiaOnline(
      int agenteId, ControlAlcoholemia control) async {
    await _api.createAlcoholemia(agenteId, _toApiAlcoholemia(control));
  }

  Future<void> updateAlcoholemiaOnline(ControlAlcoholemia control) async {
    await _api.updateAlcoholemia(control.id!, _toApiAlcoholemia(control));
  }

  Future<void> deleteAlcoholemiaOnline(int id) async {
    await _api.deleteAlcoholemia(id);
  }

  // ── Observaciones (online) ──

  Future<List<Map<String, dynamic>>> fetchReporteAgente(int agenteId) async {
    final response = await _api.getReporteAgente(agenteId);
    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> createObservacionOnline(
      int agenteId, ObservacionReclamo o) async {
    await _api.createObservacion(agenteId, _toApiObservacion(o));
  }

  Future<void> updateObservacionOnline(ObservacionReclamo o) async {
    await _api.updateObservacion(o.id!, _toApiObservacion(o));
  }

  Future<void> deleteObservacionOnline(int id) async {
    await _api.deleteObservacion(id);
  }

  // ── CRUD local + remoto ──

  Future<int> createAgente(Agente agente) async {
    final localId = await _db.insertAgente(agente);
    try {
      await _api.createAgente(_toApiAgente(agente));
    } on ApiException {
      await _sync.enqueue(
          'agente', 'create', localId, _toApiAgente(agente));
    }
    return localId;
  }

  Future<void> updateAgente(Agente agente) async {
    await _db.updateAgente(agente);
    try {
      await _api.updateAgente(agente.id!, _toApiAgente(agente));
    } on ApiException {
      await _sync.enqueue(
          'agente', 'update', agente.id, _toApiAgente(agente));
    }
  }

  Future<void> deleteAgente(int id) async {
    await _db.deleteAgente(id);
    try {
      await _api.deleteAgente(id);
    } on ApiException {
      await _sync.enqueue(
          'agente', 'delete', id, {'id': id});
    }
  }

  Future<int> createControl(ControlAlcoholemia control) async {
    final localId = await _db.insertControl(control);
    final serverAgenteId = await _resolveServerAgentId(control.agenteId);
    if (serverAgenteId != null) {
      try {
        await _api.createAlcoholemia(
            serverAgenteId, _toApiAlcoholemia(control));
      } on ApiException {
        await _sync.enqueue('alcoholemia', 'create', localId,
            {..._toApiAlcoholemia(control), 'agenteId': serverAgenteId});
      }
    }
    return localId;
  }

  Future<void> updateControl(ControlAlcoholemia control) async {
    await _db.updateControl(control);
    try {
      await _api.updateAlcoholemia(
          control.id!, _toApiAlcoholemia(control));
    } on ApiException {
      await _sync.enqueue('alcoholemia', 'update', control.id,
          {..._toApiAlcoholemia(control), 'id': control.id});
    }
  }

  Future<void> deleteControl(int id) async {
    await _db.deleteControl(id);
    try {
      await _api.deleteAlcoholemia(id);
    } on ApiException {
      await _sync.enqueue(
          'alcoholemia', 'delete', id, {'id': id});
    }
  }

  Future<int> createObservacion(ObservacionReclamo o) async {
    final localId = await _db.insertObservacionReclamo(o);
    final serverAgenteId = await _resolveServerAgentId(o.agenteId);
    if (serverAgenteId != null) {
      try {
        await _api.createObservacion(
            serverAgenteId, _toApiObservacion(o));
      } on ApiException {
        await _sync.enqueue('observacion', 'create', localId,
            {..._toApiObservacion(o), 'agenteId': serverAgenteId});
      }
    }
    return localId;
  }

  Future<void> updateObservacion(ObservacionReclamo o) async {
    await _db.updateObservacionReclamo(o);
    try {
      await _api.updateObservacion(o.id!, _toApiObservacion(o));
    } on ApiException {
      await _sync.enqueue('observacion', 'update', o.id,
          {..._toApiObservacion(o), 'id': o.id});
    }
  }

  Future<void> deleteObservacion(int id) async {
    await _db.deleteObservacionReclamo(id);
    try {
      await _api.deleteObservacion(id);
    } on ApiException {
      await _sync.enqueue(
          'observacion', 'delete', id, {'id': id});
    }
  }
}

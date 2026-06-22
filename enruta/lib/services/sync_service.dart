import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/agente.dart';
import '../models/control_alcoholemia.dart';
import '../models/observacion_reclamo.dart';
import 'api_client.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  ApiClient? _api;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _debounceTimer;
  Timer? _retryTimer;
  bool _processing = false;
  bool _wasOffline = false;
  DateTime? _lastFullSync;

  static const _lastSyncKey = 'last_sync_timestamp';
  static const _backoffDelays = [5, 15, 60];
  static const _syncThrottleSeconds = 30;
  static const _connectivityDebounceMs = 2000;
  static const _queueBatchSize = 5;

  void configure(ApiClient api) {
    _api = api;
  }

  // ── Inicio ──

  Future<void> start() async {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        const Duration(milliseconds: _connectivityDebounceMs),
        () {
          final hasConnection =
              results.any((r) => r != ConnectivityResult.none);
          if (hasConnection && _wasOffline) {
            _tryFullSync();
          }
          _wasOffline = !hasConnection;
        },
      );
    });

    final current = await Connectivity().checkConnectivity();
    _wasOffline = current.every((r) => r == ConnectivityResult.none);

    if (!_wasOffline) {
      _tryFullSync();
    }
  }

  void stop() {
    _connectivitySub?.cancel();
    _debounceTimer?.cancel();
    _retryTimer?.cancel();
  }

  // ── Throttled Full Sync ──

  Future<void> fullSync() async {
    _tryFullSync();
  }

  void _tryFullSync() {
    if (_processing) return;
    if (_api == null || !_api!.isAuthenticated) return;

    final now = DateTime.now();
    if (_lastFullSync != null &&
        now.difference(_lastFullSync!).inSeconds < _syncThrottleSeconds) {
      return;
    }
    _lastFullSync = now;
    _executeFullSync();
  }

  Future<void> _executeFullSync() async {
    _processing = true;
    try {
      final pending = await _db.getPendingSyncCount();
      final prefs = await SharedPreferences.getInstance();
      final lastPull = prefs.getString(_lastSyncKey) ?? '2000-01-01T00:00:00Z';
      final needsPull = DateTime.now()
              .difference(DateTime.tryParse(lastPull) ?? DateTime(2000))
              .inMinutes >=
          5;

      if (pending > 0) {
        await _processQueue();
      }

      if (needsPull || pending > 0) {
        await pullFromServer();
      }
    } catch (_) {
      // error no fatal, se reintentará
    } finally {
      _processing = false;
    }
  }

  // ── Enqueue ──

  Future<void> enqueue(String entidad, String operacion,
      int? registroId, Map<String, dynamic> payload) async {
    await _db.enqueueSync(
        entidad, operacion, registroId, jsonEncode(payload));
  }

  // ── Process Queue ──

  Future<void> processPendingSyncs() async {
    if (_processing || _api == null || !_api!.isAuthenticated) return;
    _processing = true;
    try {
      await _processQueue();
    } finally {
      _processing = false;
    }
  }

  Future<void> _processQueue() async {
    var hasMore = true;
    while (hasMore) {
      final batch = await _db.getPendingSyncs();
      if (batch.isEmpty) {
        hasMore = false;
        break;
      }
      hasMore = batch.length >= _queueBatchSize;

      final futures = batch.map((item) => _processItem(item));
      final results = await Future.wait(futures);

      if (results.any((r) => r == false)) break;
    }
  }

  Future<bool> _processItem(Map<String, dynamic> item) async {
    final id = item['id'] as int;
    final entidad = item['entidad'] as String;
    final operacion = item['operacion'] as String;
    final payload =
        jsonDecode(item['payload'] as String) as Map<String, dynamic>;

    try {
      switch (entidad) {
        case 'agente':
          await _executeAgenteSync(operacion, payload);
        case 'alcoholemia':
          await _executeAlcoholemiaSync(operacion, payload);
        case 'observacion':
          await _executeObservacionSync(operacion, payload);
      }
      await _db.deleteSyncItem(id);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode >= 400 && e.statusCode < 500) {
        await _db.markSyncFailed(id);
        return true;
      }
      final intentos = (item['intentos'] as int) + 1;
      await _db.incrementSyncIntentos(id);
      if (intentos >= 3) {
        await _db.markSyncFailed(id);
        return true;
      }
      _scheduleRetry(
          id: id, intentos: intentos);
      return false;
    } on Exception {
      final intentos = (item['intentos'] as int) + 1;
      await _db.incrementSyncIntentos(id);
      if (intentos >= 3) {
        await _db.markSyncFailed(id);
      }
      _scheduleRetry(
          id: id, intentos: intentos);
      return false;
    }
  }

  void _scheduleRetry({required int id, required int intentos}) {
    _retryTimer?.cancel();
    final delayIdx = (intentos - 1).clamp(0, _backoffDelays.length - 1);
    _retryTimer = Timer(Duration(seconds: _backoffDelays[delayIdx]), () {
      processPendingSyncs();
    });
  }

  Future<void> _executeAgenteSync(
      String operacion, Map<String, dynamic> payload) async {
    switch (operacion) {
      case 'create':
        await _api!.createAgente(payload);
      case 'update':
        await _api!.updateAgente(payload['id'] as int, payload);
      case 'delete':
        await _api!.deleteAgente(payload['id'] as int);
    }
  }

  Future<void> _executeAlcoholemiaSync(
      String operacion, Map<String, dynamic> payload) async {
    switch (operacion) {
      case 'create':
        await _api!.createAlcoholemia(payload['agenteId'] as int, payload);
      case 'update':
        await _api!.updateAlcoholemia(payload['id'] as int, payload);
      case 'delete':
        await _api!.deleteAlcoholemia(payload['id'] as int);
    }
  }

  Future<void> _executeObservacionSync(
      String operacion, Map<String, dynamic> payload) async {
    switch (operacion) {
      case 'create':
        await _api!.createObservacion(payload['agenteId'] as int, payload);
      case 'update':
        await _api!.updateObservacion(payload['id'] as int, payload);
      case 'delete':
        await _api!.deleteObservacion(payload['id'] as int);
    }
  }

  // ── Pull from Server ──

  Future<void> pullFromServer() async {
    if (_api == null || !_api!.isAuthenticated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync =
          prefs.getString(_lastSyncKey) ?? '2000-01-01T00:00:00Z';
      final response = await _api!.syncPull(lastSync);

      final agentes = (response['agentes'] as List<dynamic>?) ?? [];
      for (final a in agentes) {
        final serverMap = a as Map<String, dynamic>;
        await _mergeAgente(serverMap);
      }

      final controles =
          (response['alcoholemias'] as List<dynamic>?) ?? [];
      for (final c in controles) {
        final serverMap = c as Map<String, dynamic>;
        await _mergeControl(serverMap);
      }

      final observaciones =
          (response['observaciones'] as List<dynamic>?) ?? [];
      for (final o in observaciones) {
        final serverMap = o as Map<String, dynamic>;
        await _mergeObservacion(serverMap);
      }

      final deleted = response['deleted'] as Map<String, dynamic>?;
      if (deleted != null) {
        for (final id in (deleted['agentes'] as List<dynamic>?) ?? []) {
          await _deleteLocalIfNotPending('agente', id as int);
        }
        for (final id
            in (deleted['alcoholemias'] as List<dynamic>?) ?? []) {
          await _deleteLocalIfNotPending('alcoholemia', id as int);
        }
        for (final id
            in (deleted['observaciones'] as List<dynamic>?) ?? []) {
          await _deleteLocalIfNotPending('observacion', id as int);
        }
      }

      final serverTime = response['serverTime'] as String?;
      if (serverTime != null) {
        await prefs.setString(_lastSyncKey, serverTime);
      }
    } on ApiException {
      // sin conexión, se reintentará
    }
  }

  // ── Merge con detección de conflictos ──

  Future<void> _mergeAgente(Map<String, dynamic> serverMap) async {
    final serverUpdatedAt = serverMap['updatedAt'] as String?;
    final legajo = serverMap['legajo'] as String;
    final local = await _db.getAgenteByLegajo(legajo);

    if (local == null) {
      await _db.insertAgente(
          Agente.fromMap(_fromServerAgente(serverMap)));
      return;
    }

    final hasPending =
        await _db.hasPendingSyncForRecord('agente', local.id!);
    if (!hasPending) {
      await _db.updateAgente(
          Agente.fromMap({..._fromServerAgente(serverMap), 'id': local.id}));
      return;
    }

    final localUpdatedAt = local.updatedAt;
    if (serverUpdatedAt == null || localUpdatedAt == null) {
      await _db.updateAgente(
          Agente.fromMap({..._fromServerAgente(serverMap), 'id': local.id}));
      return;
    }

    if (serverUpdatedAt.compareTo(localUpdatedAt) > 0) {
      await _db.updateAgente(
          Agente.fromMap({..._fromServerAgente(serverMap), 'id': local.id}));
    }
  }

  Future<void> _mergeControl(Map<String, dynamic> serverMap) async {
    final serverId = serverMap['id'] as int?;
    if (serverId != null) {
      final existing = await _db.getControlesByAgente(serverId);
      if (existing.isNotEmpty) {
        final hasPending = await _db.hasPendingSyncForRecord(
            'alcoholemia', serverId);
        if (!hasPending) {
          await _db.updateControl(ControlAlcoholemia(
            id: serverId,
            agenteId: serverMap['agenteId'] as int,
            fecha: serverMap['fecha'] as String,
            resultado: serverMap['resultado'] as String,
            graduacion: (serverMap['graduacion'] as num?)?.toDouble(),
            servicioExtra: serverMap['servicioExtra'] as String?,
            observacion: serverMap['observacion'] as String?,
            createdAt: serverMap['createdAt'] as String?,
          ));
        }
        return;
      }
    }
    await _db.insertControl(ControlAlcoholemia(
      id: serverMap['id'] as int?,
      agenteId: serverMap['agenteId'] as int,
      fecha: serverMap['fecha'] as String,
      resultado: serverMap['resultado'] as String,
      graduacion: (serverMap['graduacion'] as num?)?.toDouble(),
      servicioExtra: serverMap['servicioExtra'] as String?,
      observacion: serverMap['observacion'] as String?,
      createdAt: serverMap['createdAt'] as String?,
    ));
  }

  Future<void> _mergeObservacion(Map<String, dynamic> serverMap) async {
    final serverId = serverMap['id'] as int?;
    if (serverId != null) {
      final existing =
          await _db.getObservacionesReclamosByAgente(serverId);
      if (existing.isNotEmpty) {
        final hasPending = await _db.hasPendingSyncForRecord(
            'observacion', serverId);
        if (!hasPending) {
          await _db.updateObservacionReclamo(ObservacionReclamo(
            id: serverId,
            agenteId: serverMap['agenteId'] as int,
            tipo: serverMap['tipo'] as String,
            descripcion: serverMap['descripcion'] as String,
            fecha: serverMap['fecha'] as String,
            resuelto: serverMap['resuelto'] == true,
            createdAt: serverMap['createdAt'] as String?,
          ));
        }
        return;
      }
    }
    await _db.insertObservacionReclamo(ObservacionReclamo(
      id: serverMap['id'] as int?,
      agenteId: serverMap['agenteId'] as int,
      tipo: serverMap['tipo'] as String,
      descripcion: serverMap['descripcion'] as String,
      fecha: serverMap['fecha'] as String,
      resuelto: serverMap['resuelto'] == true,
      createdAt: serverMap['createdAt'] as String?,
    ));
  }

  Future<void> _deleteLocalIfNotPending(String entidad, int id) async {
    final hasPending = await _db.hasPendingSyncForRecord(entidad, id);
    if (hasPending) return;
    switch (entidad) {
      case 'agente':
        await _db.deleteAgente(id);
      case 'alcoholemia':
        await _db.deleteControl(id);
      case 'observacion':
        await _db.deleteObservacionReclamo(id);
    }
  }

  Map<String, dynamic> _fromServerAgente(Map<String, dynamic> map) {
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

  Future<int> get pendingCount => _db.getPendingSyncCount();
  Future<int> get failedCount => _db.getFailedSyncCount();

  Future<void> retryFailedItem(int id) async {
    await _db.markSyncPending(id);
    processPendingSyncs();
  }

  Future<void> retryAllFailed() async {
    final failed = await _db.getFailedSyncIds();
    for (final id in failed) {
      await _db.markSyncPending(id);
    }
    processPendingSyncs();
  }
}

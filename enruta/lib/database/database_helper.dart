import 'dart:collection';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:csv/csv.dart';

import '../models/agente.dart';
import '../models/control_alcoholemia.dart';
import '../models/observacion_reclamo.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  static Future<void> resetForTest() async {
    final db = _database;
    _database = null;
    if (db != null) {
      final path = db.path;
      await db.close();
      await deleteDatabase(path);
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'enruta.db');
    return await openDatabase(
      path,
      version: 4,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE agentes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        legajo TEXT UNIQUE NOT NULL,
        apellido_nombre TEXT NOT NULL,
        fecha_ingreso TEXT,
        dependencia TEXT,
        cargo TEXT,
        turno TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE controles_alcoholemia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agente_id INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        resultado TEXT NOT NULL,
        graduacion REAL,
        servicio_extra TEXT,
        observacion TEXT,
        created_at TEXT,
        FOREIGN KEY (agente_id) REFERENCES agentes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE observaciones_reclamos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        agente_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL,
        resuelto INTEGER NOT NULL DEFAULT 0,
        created_at TEXT,
        FOREIGN KEY (agente_id) REFERENCES agentes(id) ON DELETE CASCADE
      )
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_controles_agente_fecha ON controles_alcoholemia(agente_id, fecha)');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_observaciones_agente ON observaciones_reclamos(agente_id)');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        entidad TEXT NOT NULL,
        operacion TEXT NOT NULL,
        registro_id INTEGER,
        payload TEXT NOT NULL,
        intentos INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE observaciones_reclamos ADD COLUMN resuelto INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          entidad TEXT NOT NULL,
          operacion TEXT NOT NULL,
          registro_id INTEGER,
          payload TEXT NOT NULL,
          intentos INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
            "ALTER TABLE sync_queue ADD COLUMN status TEXT NOT NULL DEFAULT 'pending'");
      } on Exception {
        // columna ya existe, migración previa parcial
      }
    }
  }

  Future<void> seedIfEmpty() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM agentes'));

    if (count == 0) {
      final csvData = await rootBundle.loadString('assets/data/agentes.csv');
      final rows =
          const CsvToListConverter(eol: '\n').convert(csvData);

      final now = DateTime.now().toIso8601String();
      final legajosVistos = HashSet<String>();
      final batch = db.batch();

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 6) continue;

        final legajo = row[0].toString().trim();
        if (legajo.isEmpty || legajosVistos.contains(legajo)) continue;
        legajosVistos.add(legajo);

        batch.insert(
          'agentes',
          {
            'legajo': legajo,
            'apellido_nombre': row[1].toString().trim(),
            'fecha_ingreso': row[2].toString().trim(),
            'dependencia': row[3].toString().trim(),
            'cargo': row[4].toString().trim(),
            'turno': row[5].toString().trim(),
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      await batch.commit(noResult: true);
    }
  }

  Future<int> insertAgente(Agente agente) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('agentes', {
      'legajo': agente.legajo,
      'apellido_nombre': agente.apellidoNombre,
      'fecha_ingreso': agente.fechaIngreso,
      'dependencia': agente.dependencia,
      'cargo': agente.cargo,
      'turno': agente.turno,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> updateAgente(Agente agente) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.update(
      'agentes',
      {
        'legajo': agente.legajo,
        'apellido_nombre': agente.apellidoNombre,
        'fecha_ingreso': agente.fechaIngreso,
        'dependencia': agente.dependencia,
        'cargo': agente.cargo,
        'turno': agente.turno,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [agente.id],
    );
  }

  Future<int> deleteAgente(int id) async {
    final db = await database;
    final controles = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM controles_alcoholemia WHERE agente_id = ?',
        [id]));
    final observaciones = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM observaciones_reclamos WHERE agente_id = ?',
        [id]));
    if ((controles ?? 0) > 0 || (observaciones ?? 0) > 0) {
      throw Exception(
          'El agente tiene $controles control(es) y $observaciones observación(es) asociada(s)');
    }
    return await db.delete('agentes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Agente>> getAgentes() async {
    final db = await database;
    final maps = await db.query('agentes', orderBy: 'apellido_nombre ASC');
    return maps.map((map) => Agente.fromMap(map)).toList();
  }

  Future<Agente?> getAgenteById(int id) async {
    final db = await database;
    final maps = await db.query('agentes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Agente.fromMap(maps.first);
  }

  Future<Agente?> getAgenteByLegajo(String legajo) async {
    final db = await database;
    final maps =
        await db.query('agentes', where: 'legajo = ?', whereArgs: [legajo]);
    if (maps.isEmpty) return null;
    return Agente.fromMap(maps.first);
  }

  Future<List<Agente>> buscarAgentes(String query) async {
    final db = await database;
    final maps = await db.query(
      'agentes',
      where:
          'apellido_nombre LIKE ? OR legajo LIKE ? OR dependencia LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'apellido_nombre ASC',
    );
    return maps.map((map) => Agente.fromMap(map)).toList();
  }

  Future<int> insertControl(ControlAlcoholemia control) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('controles_alcoholemia', {
      'agente_id': control.agenteId,
      'fecha': control.fecha,
      'resultado': control.resultado,
      'graduacion': control.graduacion,
      'servicio_extra': control.servicioExtra,
      'observacion': control.observacion,
      'created_at': now,
    });
  }

  Future<int> updateControl(ControlAlcoholemia control) async {
    final db = await database;
    return await db.update(
      'controles_alcoholemia',
      {
        'fecha': control.fecha,
        'resultado': control.resultado,
        'graduacion': control.graduacion,
        'servicio_extra': control.servicioExtra,
        'observacion': control.observacion,
      },
      where: 'id = ?',
      whereArgs: [control.id],
    );
  }

  Future<int> deleteControl(int id) async {
    final db = await database;
    return await db.delete('controles_alcoholemia',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ControlAlcoholemia>> getControlesByAgente(int agenteId) async {
    final db = await database;
    final maps = await db.query(
      'controles_alcoholemia',
      where: 'agente_id = ?',
      whereArgs: [agenteId],
      orderBy: 'fecha DESC',
    );
    return maps.map((map) => ControlAlcoholemia.fromMap(map)).toList();
  }

  Future<List<ControlAlcoholemia>> getControlesByFecha(String fecha) async {
    final db = await database;
    final maps = await db.query(
      'controles_alcoholemia',
      where: 'fecha = ?',
      whereArgs: [fecha],
      orderBy: 'agente_id ASC',
    );
    return maps.map((map) => ControlAlcoholemia.fromMap(map)).toList();
  }

  Future<List<ControlAlcoholemia>> getControlesEntreFechas(
      String desde, String hasta) async {
    final db = await database;
    final maps = await db.query(
      'controles_alcoholemia',
      where: 'fecha BETWEEN ? AND ?',
      whereArgs: [desde, hasta],
      orderBy: 'fecha DESC',
    );
    return maps.map((map) => ControlAlcoholemia.fromMap(map)).toList();
  }

  Future<int> insertObservacionReclamo(ObservacionReclamo or) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return await db.insert('observaciones_reclamos', {
      'agente_id': or.agenteId,
      'tipo': or.tipo,
      'descripcion': or.descripcion,
      'fecha': or.fecha,
      'resuelto': or.resuelto ? 1 : 0,
      'created_at': now,
    });
  }

  Future<int> updateObservacionReclamo(ObservacionReclamo or) async {
    final db = await database;
    return await db.update(
      'observaciones_reclamos',
      {
        'tipo': or.tipo,
        'descripcion': or.descripcion,
        'fecha': or.fecha,
        'resuelto': or.resuelto ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [or.id],
    );
  }

  Future<int> deleteObservacionReclamo(int id) async {
    final db = await database;
    return await db.delete('observaciones_reclamos',
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ObservacionReclamo>> getObservacionesReclamosByAgente(
      int agenteId) async {
    final db = await database;
    final maps = await db.query(
      'observaciones_reclamos',
      where: 'agente_id = ?',
      whereArgs: [agenteId],
      orderBy: 'fecha DESC',
    );
    return maps.map((map) => ObservacionReclamo.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> getControlesReporteEntreFechas(
      String desde, String hasta) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.*, a.legajo, a.apellido_nombre, a.dependencia, a.cargo, a.turno
      FROM controles_alcoholemia c
      JOIN agentes a ON c.agente_id = a.id
      WHERE c.fecha BETWEEN ? AND ?
      ORDER BY c.fecha DESC, a.apellido_nombre ASC
    ''', [desde, hasta]);
  }

  Future<List<Map<String, dynamic>>> getObservacionesReporteByAgente(
      int agenteId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT o.*, a.legajo, a.apellido_nombre, a.dependencia, a.cargo
      FROM observaciones_reclamos o
      JOIN agentes a ON o.agente_id = a.id
      WHERE o.agente_id = ?
      ORDER BY o.fecha DESC
    ''', [agenteId]);
  }

  // ── Sync Queue ──

  Future<int> enqueueSync(String entidad, String operacion,
      int? registroId, String payload) async {
    final db = await database;
    return await db.insert('sync_queue', {
      'entidad': entidad,
      'operacion': operacion,
      'registro_id': registroId,
      'payload': payload,
      'intentos': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncs() async {
    final db = await database;
    return await db.query(
      'sync_queue',
      where: "status = 'pending'",
      orderBy: 'id ASC',
      limit: 50,
    );
  }

  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'pending'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getFailedSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT COUNT(*) as count FROM sync_queue WHERE status = 'failed'");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> incrementSyncIntentos(int id) async {
    final db = await database;
    await db.rawUpdate(
        'UPDATE sync_queue SET intentos = intentos + 1 WHERE id = ?', [id]);
  }

  Future<void> markSyncFailed(int id) async {
    final db = await database;
    await db.rawUpdate(
        "UPDATE sync_queue SET status = 'failed' WHERE id = ?", [id]);
  }

  Future<void> markSyncPending(int id) async {
    final db = await database;
    await db.rawUpdate(
        "UPDATE sync_queue SET status = 'pending', intentos = 0 WHERE id = ?", [id]);
  }

  Future<List<int>> getFailedSyncIds() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT id FROM sync_queue WHERE status = 'failed'");
    return result.map((r) => r['id'] as int).toList();
  }

  Future<void> deleteSyncItem(int id) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> hasPendingSyncForRecord(String entidad, int registroId) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE entidad = ? AND registro_id = ? AND status = 'pending'",
      [entidad, registroId],
    );
    return (Sqflite.firstIntValue(result) ?? 0) > 0;
  }

  Future<void> clearSyncQueue() async {
    final db = await database;
    await db.delete('sync_queue');
  }
}

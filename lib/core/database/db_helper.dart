import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../features/rq_urgente/models/rq_local_model.dart';

class DBHelper {
  static Database? _db;
  static final List<RQLocal> _webRqs = <RQLocal>[];
  static int _nextWebId = 1;

  static RQLocal _copy(RQLocal rq) => RQLocal.fromMap(rq.toMap());

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'sistema_ocs.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) {
        return db.execute(
            "CREATE TABLE requerimientos(id INTEGER PRIMARY KEY AUTOINCREMENT, servicio TEXT, productos TEXT, fecha TEXT, enviado INTEGER, obra_id INTEGER, obra_codigo TEXT, obra_descripcion TEXT, servidor_id INTEGER, numero TEXT, estado_servidor TEXT DEFAULT 'BORRADOR')");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db
              .execute('ALTER TABLE requerimientos ADD COLUMN obra_id INTEGER');
          await db.execute(
              'ALTER TABLE requerimientos ADD COLUMN servidor_id INTEGER');
          await db.execute('ALTER TABLE requerimientos ADD COLUMN numero TEXT');
          await db.execute(
              "ALTER TABLE requerimientos ADD COLUMN estado_servidor TEXT DEFAULT 'BORRADOR'");
        }
        if (oldVersion < 3) {
          await db.execute(
              'ALTER TABLE requerimientos ADD COLUMN obra_codigo TEXT');
          await db.execute(
              'ALTER TABLE requerimientos ADD COLUMN obra_descripcion TEXT');
        }
      },
    );
  }

  static Future<int> insertarRQ(RQLocal rq) async {
    if (kIsWeb) {
      rq.id = _nextWebId++;
      _webRqs.insert(0, _copy(rq));
      return rq.id!;
    }
    final db = await database;
    return await db.insert('requerimientos', rq.toMap());
  }

  static Future<int> actualizarRQ(RQLocal rq) async {
    if (kIsWeb) {
      final index = _webRqs.indexWhere((item) => item.id == rq.id);
      if (index == -1) return 0;
      _webRqs[index] = _copy(rq);
      return 1;
    }
    final db = await database;
    return await db.update('requerimientos', rq.toMap(),
        where: 'id = ?', whereArgs: [rq.id]);
  }

  static Future<List<RQLocal>> obtenerRQs() async {
    if (kIsWeb) return _webRqs.map(_copy).toList();
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('requerimientos', orderBy: 'id DESC');
    return List.generate(maps.length, (i) => RQLocal.fromMap(maps[i]));
  }

  static Future<void> eliminarRQ(int id) async {
    if (kIsWeb) {
      _webRqs.removeWhere((rq) => rq.id == id);
      return;
    }
    final db = await database;
    await db.delete('requerimientos', where: 'id = ?', whereArgs: [id]);
  }
}

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:book_manager/datos/base_datos/esquema_base_datos.dart';

class CompleteDatabaseConnection {
  CompleteDatabaseConnection._();

  static final CompleteDatabaseConnection instance =
      CompleteDatabaseConnection._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final path = kIsWeb
        ? DatabaseSchema.databaseName
        : join(await getDatabasesPath(), DatabaseSchema.databaseName);

    _database = await openDatabase(
      path,
      version: DatabaseSchema.version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createSchema(db);
        await _seedCatalogs(db);
      },
    );

    return _database!;
  }

  Future<void> close() async {
    final db = _database;
    if (db == null) return;

    await db.close();
    _database = null;
  }

  Future<int> insert(
    String table,
    Map<String, Object?> values, {
    ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.abort,
  }) async {
    final db = await database;
    return db.insert(
      table,
      values,
      conflictAlgorithm: conflictAlgorithm,
    );
  }

  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final db = await database;
    return db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return db.transaction(action);
  }

  Future<void> _createSchema(Database db) async {
    for (final statement in DatabaseSchema.createStatements) {
      await db.execute(statement);
    }
    for (final statement in DatabaseSchema.indexStatements) {
      await db.execute(statement);
    }
  }

  Future<void> _seedCatalogs(Database db) async {
    final batch = db.batch();

    batch.insert(DbTables.roles, {
      'nombre': 'Administrador',
      'descripcion': 'Acceso completo a configuracion, usuarios e inventario.',
    });
    batch.insert(DbTables.roles, {
      'nombre': 'Vendedor',
      'descripcion': 'Gestiona pedidos, catalogo y clientes/colegios.',
    });
    batch.insert(DbTables.roles, {
      'nombre': 'Bodeguero',
      'descripcion': 'Gestiona stock, escaneos y operaciones de bodega.',
    });
    batch.insert(DbTables.bodegas, {
      'nombre': 'Bodega principal',
      'ubicacion': 'Principal',
    });

    await batch.commit(noResult: true);
  }
}

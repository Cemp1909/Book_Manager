import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:book_manager/caracteristicas/inventario/modelos/book.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const _databaseName = 'editorial_manager.db';
  static const _databaseVersion = 1;
  static const booksTable = 'books';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    }

    final path =
        kIsWeb ? _databaseName : join(await getDatabasesPath(), _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );

    return _database!;
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $booksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        isbn TEXT NOT NULL UNIQUE,
        price INTEGER NOT NULL,
        stock INTEGER NOT NULL,
        genre TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    final batch = db.batch();
    for (final book in _initialBooks) {
      batch.insert(booksTable, book.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<Book>> getBooks() async {
    final db = await database;
    final rows =
        await db.query(booksTable, orderBy: 'title COLLATE NOCASE ASC');

    return rows.map(Book.fromMap).toList();
  }

  Future<int> insertBook(Book book) async {
    final db = await database;

    return db.insert(
      booksTable,
      book.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateBook(Book book) async {
    final db = await database;

    return db.update(
      booksTable,
      book.toMap(),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<int> deleteBook(int id) async {
    final db = await database;

    return db.delete(booksTable, where: 'id = ?', whereArgs: [id]);
  }

  static const List<Book> _initialBooks = [
    Book(
      title: 'Cien anos de soledad',
      author: 'Gabriel Garcia Marquez',
      isbn: '978-84-376-0494-7',
      price: 45000,
      stock: 50,
      genre: 'Novela',
      description:
          'Una de las obras mas importantes de la literatura universal.',
    ),
    Book(
      title: '1984',
      author: 'George Orwell',
      isbn: '978-84-9759-329-4',
      price: 38000,
      stock: 5,
      genre: 'Ciencia ficcion',
      description: 'Una distopia que sigue siendo relevante.',
    ),
    Book(
      title: 'El principito',
      author: 'Antoine de Saint-Exupery',
      isbn: '978-84-376-0494-8',
      price: 25000,
      stock: 0,
      genre: 'Infantil',
      description: 'Un clasico de la literatura infantil.',
    ),
    Book(
      title: 'Fahrenheit 451',
      author: 'Ray Bradbury',
      isbn: '978-84-9759-329-5',
      price: 32000,
      stock: 12,
      genre: 'Ciencia ficcion',
      description: 'Un mundo donde los libros estan prohibidos.',
    ),
  ];
}

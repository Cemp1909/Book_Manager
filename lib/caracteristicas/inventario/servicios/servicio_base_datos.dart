import 'package:book_manager/datos/api/api_client.dart';
import 'package:book_manager/datos/modelos/libro.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  final ApiClient _api = ApiClient.instance;

  Future<List<Book>> getBooks() async {
    final response = await _api.get('/api/v1/libros?limit=200');
    final rows = response['data'] as List<dynamic>? ?? const [];
    final books =
        rows.whereType<Map<String, dynamic>>().map(Book.fromApiMap).toList();
    books
        .sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return books;
  }

  Future<int> insertBook(Book book) async {
    final response = await _api.post('/api/v1/libros', book.toApiMap());
    return _asInt(response['id']) ?? 0;
  }

  Future<int> updateBook(Book book) async {
    final id = book.id;
    if (id == null) return 0;

    await _api.put('/api/v1/libros/$id', book.toApiMap());
    return 1;
  }

  Future<int> deleteBook(int id) async {
    await _api.delete('/api/v1/libros/$id');
    return 1;
  }

  int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

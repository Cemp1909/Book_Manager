class Book {
  final int? id;
  final String title;
  final String author;
  final String isbn;
  final int price;
  final int stock;
  final String genre;
  final String grade;
  final String description;
  final String coverUrl;

  const Book({
    this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.price,
    required this.stock,
    required this.genre,
    this.grade = 'General',
    required this.description,
    this.coverUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'author': author,
      'isbn': isbn,
      'price': price,
      'stock': stock,
      'genre': genre,
      'grade': grade,
      'description': description,
      'coverUrl': coverUrl,
    };
  }

  Map<String, dynamic> toApiMap() {
    return {
      'titulo': title,
      'isbn': isbn,
      'grado': grade.trim().isEmpty ? 'General' : grade.trim(),
      'area': genre,
      'stock': stock,
      'codigo_qr': isbn,
      'autor': author,
      'descripcion': description,
      'precio_base': price,
      'foto_portada': _coverStorageValue(),
    };
  }

  String _coverStorageValue() {
    final cleanCover = coverUrl.trim();
    if (cleanCover.isEmpty) return 'sin_portada';
    if (cleanCover.startsWith('data:image')) return 'portada_capturada';
    if (cleanCover.length > 1000) return 'portada_externa';
    return cleanCover;
  }

  Book copyWith({
    int? id,
    String? title,
    String? author,
    String? isbn,
    int? price,
    int? stock,
    String? genre,
    String? grade,
    String? description,
    String? coverUrl,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      isbn: isbn ?? this.isbn,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      genre: genre ?? this.genre,
      grade: grade ?? this.grade,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
    );
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int?,
      title: map['title'] as String,
      author: map['author'] as String,
      isbn: map['isbn'] as String,
      price: map['price'] as int,
      stock: map['stock'] as int,
      genre: map['genre'] as String,
      grade: map['grade'] as String? ?? 'General',
      description: map['description'] as String,
      coverUrl: map['coverUrl'] as String? ?? '',
    );
  }

  factory Book.fromApiMap(Map<String, dynamic> map) {
    int? asInt(Object? value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    String asString(Object? value) => value?.toString() ?? '';

    return Book(
      id: asInt(map['ID_LIBRO'] ?? map['id_libro']),
      title: asString(map['TITULO'] ?? map['titulo']),
      author: asString(map['AUTOR'] ?? map['autor']),
      isbn: asString(map['ISBN'] ?? map['isbn']),
      price: asInt(map['PRECIO_BASE'] ?? map['precio_base']) ?? 0,
      stock: asInt(map['STOCK'] ?? map['stock']) ?? 0,
      genre: asString(map['AREA'] ?? map['area']),
      grade: asString(map['GRADO'] ?? map['grado']).trim().isEmpty
          ? 'General'
          : asString(map['GRADO'] ?? map['grado']),
      description: asString(map['DESCRIPCION'] ?? map['descripcion']),
      coverUrl: asString(map['FOTO_PORTADA'] ?? map['foto_portada']),
    );
  }
}

class Book {
  final int? id;
  final String title;
  final String author;
  final String isbn;
  final int price;
  final int stock;
  final String genre;
  final String description;

  const Book({
    this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.price,
    required this.stock,
    required this.genre,
    required this.description,
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
      'description': description,
    };
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
      description: map['description'] as String,
    );
  }
}

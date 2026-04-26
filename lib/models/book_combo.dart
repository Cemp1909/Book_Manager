import 'book.dart';

class BookCombo {
  final String id;
  final String name;
  final String audience;
  final List<Book> books;
  final int discountPercent;

  const BookCombo({
    required this.id,
    required this.name,
    required this.audience,
    required this.books,
    required this.discountPercent,
  });

  int get subtotal => books.fold(0, (sum, book) => sum + book.price);

  int get total => (subtotal * (100 - discountPercent) / 100).round();

  int get stock => books.isEmpty
      ? 0
      : books.map((book) => book.stock).reduce((a, b) => a < b ? a : b);

  BookCombo copyWith({
    String? id,
    String? name,
    String? audience,
    List<Book>? books,
    int? discountPercent,
  }) {
    return BookCombo(
      id: id ?? this.id,
      name: name ?? this.name,
      audience: audience ?? this.audience,
      books: books ?? this.books,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}

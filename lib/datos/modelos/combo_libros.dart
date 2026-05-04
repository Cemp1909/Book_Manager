import 'package:book_manager/datos/modelos/libro.dart';

class BookCombo {
  final String id;
  final String name;
  final String audience;
  final String cityId;
  final String cityName;
  final String schoolId;
  final String schoolName;
  final List<Book> books;
  final int discountPercent;
  final int? customPrice;

  const BookCombo({
    required this.id,
    required this.name,
    required this.audience,
    required this.cityId,
    required this.cityName,
    required this.schoolId,
    required this.schoolName,
    required this.books,
    required this.discountPercent,
    this.customPrice,
  });

  int get subtotal => books.fold(0, (sum, book) => sum + book.price);

  int get total =>
      customPrice ?? (subtotal * (100 - discountPercent) / 100).round();

  int get stock => books.isEmpty
      ? 0
      : books.map((book) => book.stock).reduce((a, b) => a < b ? a : b);

  BookCombo copyWith({
    String? id,
    String? name,
    String? audience,
    String? cityId,
    String? cityName,
    String? schoolId,
    String? schoolName,
    List<Book>? books,
    int? discountPercent,
    int? customPrice,
    bool clearCustomPrice = false,
  }) {
    return BookCombo(
      id: id ?? this.id,
      name: name ?? this.name,
      audience: audience ?? this.audience,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      books: books ?? this.books,
      discountPercent: discountPercent ?? this.discountPercent,
      customPrice: clearCustomPrice ? null : customPrice ?? this.customPrice,
    );
  }
}

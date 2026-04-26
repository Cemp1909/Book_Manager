import 'package:flutter/material.dart';
import 'package:book_manager/caracteristicas/inventario/modelos/book.dart';
import 'package:book_manager/compartido/servicios/temporary_data_service.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final bool showPrice;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    final lowStockLimit = TemporaryDataService.instance.settings.lowStockLimit;
    final isLowStock = book.stock <= lowStockLimit && book.stock > 0;
    final isOutOfStock = book.stock == 0;

    Color stockColor;
    String stockText;

    if (isOutOfStock) {
      stockColor = Colors.red;
      stockText = 'Agotado';
    } else if (isLowStock) {
      stockColor = Colors.orange;
      stockText = 'Stock bajo: ${book.stock}';
    } else {
      stockColor = Colors.green;
      stockText = 'Stock: ${book.stock}';
    }

    final currency = TemporaryDataService.instance.settings.currencySymbol;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.menu_book, size: 40, color: Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ISBN: ${book.isbn}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showPrice)
                    Text(
                      '$currency${book.price}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.blue,
                      ),
                    ),
                  SizedBox(height: showPrice ? 4 : 0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: stockColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      stockText,
                      style: TextStyle(
                        fontSize: 12,
                        color: stockColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

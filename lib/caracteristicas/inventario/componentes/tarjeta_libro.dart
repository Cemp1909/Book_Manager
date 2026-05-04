import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final bool showPrice;
  final int animationIndex;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.showPrice = true,
    this.animationIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final lowStockLimit = TemporaryDataService.instance.settings.lowStockLimit;
    final currency = TemporaryDataService.instance.settings.currencySymbol;
    final isOutOfStock = book.stock == 0;
    final isLowStock = book.stock <= lowStockLimit && book.stock > 0;
    final statusColor = isOutOfStock
        ? AppColors.coral
        : isLowStock
            ? AppColors.amber
            : AppColors.leaf;
    final statusText = isOutOfStock
        ? 'Agotado'
        : isLowStock
            ? 'Stock bajo'
            : 'Disponible';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
        boxShadow: AppShadows.crisp(statusColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: AppShadows.soft(AppColors.navy),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: BookCoverImage(coverUrl: book.coverUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.author,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book.genre,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MiniPill(
                            label: statusText,
                            icon: isOutOfStock
                                ? Icons.remove_shopping_cart_outlined
                                : isLowStock
                                    ? Icons.warning_amber_outlined
                                    : Icons.check_circle_outline,
                            color: statusColor,
                          ),
                          _MiniPill(
                            label: 'Stock ${book.stock}',
                            icon: Icons.inventory_2_outlined,
                            color: AppColors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showPrice)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          CurrencyFormatService.money(book.price, currency),
                          style: const TextStyle(
                            color: AppColors.tealDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (45 * animationIndex).ms).fadeIn().slideY(
          begin: 0.08,
          duration: 360.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class BookCoverImage extends StatelessWidget {
  final String coverUrl;
  final double iconSize;

  const BookCoverImage({
    super.key,
    required this.coverUrl,
    this.iconSize = 38,
  });

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeDataImage(coverUrl);
    if (imageBytes != null) {
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CoverPlaceholder(iconSize: iconSize),
      );
    }

    if (coverUrl.startsWith('http') || coverUrl.startsWith('blob:')) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _CoverPlaceholder(iconSize: iconSize),
      );
    }

    return _CoverPlaceholder(iconSize: iconSize);
  }

  Uint8List? _decodeDataImage(String value) {
    if (!value.startsWith('data:image')) return null;
    final commaIndex = value.indexOf(',');
    if (commaIndex == -1) return null;

    try {
      return base64Decode(value.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final double iconSize;

  const _CoverPlaceholder({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.navy,
      child: Center(
        child: Icon(Icons.menu_book, size: iconSize, color: Colors.white),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MiniPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

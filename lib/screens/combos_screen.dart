import 'package:flutter/material.dart';

import '../models/book_combo.dart';
import '../services/database_service.dart';
import '../services/temporary_data_service.dart';
import '../theme/app_theme.dart';

class CombosScreen extends StatefulWidget {
  const CombosScreen({super.key});

  @override
  State<CombosScreen> createState() => _CombosScreenState();
}

class _CombosScreenState extends State<CombosScreen> {
  final _databaseService = DatabaseService.instance;
  final _dataService = TemporaryDataService.instance;

  List<BookCombo> _combos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCombos();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_combos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Agrega mas libros al inventario para armar combos temporales.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Combos listos para vender',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'Estos combos salen del inventario local y luego se conectan a la base de datos.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        for (final combo in _combos) ...[
          _ComboCard(
            combo: combo,
            currency: _dataService.settings.currencySymbol,
            onTap: () => _showComboDetail(combo),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _loadCombos() async {
    try {
      final books = await _databaseService.getBooks();
      if (!mounted) return;
      setState(() {
        _combos = _dataService.buildCombos(books);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showComboDetail(BookCombo combo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            combo.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(combo.audience, style: const TextStyle(color: AppColors.muted)),
          const Divider(height: 28),
          for (final book in combo.books)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(book.title),
              subtitle: Text(book.author),
              trailing:
                  Text('${_dataService.settings.currencySymbol}${book.price}'),
            ),
          const Divider(height: 28),
          Text(
            'Precio combo: ${_dataService.settings.currencySymbol}${combo.total}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _ComboCard extends StatelessWidget {
  final BookCombo combo;
  final String currency;
  final VoidCallback onTap;

  const _ComboCard({
    required this.combo,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.violet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.grid_view, color: AppColors.violet),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          combo.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          combo.audience,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ChipText('${combo.books.length} libros'),
                  _ChipText('${combo.discountPercent}% descuento'),
                  _ChipText('Stock ${combo.stock}'),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$currency${combo.total}',
                style: const TextStyle(
                  color: AppColors.tealDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipText extends StatelessWidget {
  final String text;

  const _ChipText(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.tealDark,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

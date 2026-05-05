import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/caracteristicas/inventario/componentes/tarjeta_libro.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';

class LibraryHomeScreen extends StatefulWidget {
  final VoidCallback? onOpenLibrary;
  final ValueChanged<Book>? onOpenBook;
  final VoidCallback? onAddBook;
  final VoidCallback? onOpenStats;

  const LibraryHomeScreen({
    super.key,
    this.onOpenLibrary,
    this.onOpenBook,
    this.onAddBook,
    this.onOpenStats,
  });

  @override
  State<LibraryHomeScreen> createState() => _LibraryHomeScreenState();
}

class _LibraryHomeScreenState extends State<LibraryHomeScreen> {
  late Future<List<Book>> _booksFuture;

  @override
  void initState() {
    super.initState();
    _booksFuture = DatabaseService.instance.getBooks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
      future: _booksFuture,
      builder: (context, snapshot) {
        final books = snapshot.data ?? const <Book>[];
        final lowStockLimit =
            TemporaryDataService.instance.settings.lowStockLimit;
        final lowStock = books
            .where((book) => book.stock <= lowStockLimit && book.stock > 0)
            .length;
        final outOfStock = books.where((book) => book.stock == 0).length;
        final featured = books.take(4).toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _booksFuture = DatabaseService.instance.getBooks();
            });
            await _booksFuture;
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (lowStock > 0 || outOfStock > 0)
                _StockAlertCard(
                  lowStock: lowStock,
                  outOfStock: outOfStock,
                  onTap: widget.onOpenLibrary,
                ),
              if (lowStock > 0 || outOfStock > 0) const SizedBox(height: 12),
              _buildActions().animate().fadeIn(delay: 120.ms).slideY(
                    begin: 0.08,
                  ),
              const SizedBox(height: 24),
              const Text(
                'Libros destacados',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (featured.isEmpty)
                const _SmallEmpty()
              else
                for (var i = 0; i < featured.length; i++)
                  BookCard(
                    book: featured[i],
                    onTap: () {
                      final onOpenBook = widget.onOpenBook;
                      if (onOpenBook != null) {
                        onOpenBook(featured[i]);
                        return;
                      }
                      widget.onOpenLibrary?.call();
                    },
                    showPrice: false,
                    animationIndex: i,
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    final actions = [
      _ActionTile(
        icon: Icons.library_books_outlined,
        title: 'Biblioteca',
        color: AppColors.teal,
        onTap: widget.onOpenLibrary,
      ),
      if (widget.onAddBook != null)
        _ActionTile(
          icon: Icons.add_circle_outline,
          title: 'Agregar',
          color: AppColors.coral,
          onTap: widget.onAddBook,
        ),
      if (widget.onOpenStats != null)
        _ActionTile(
          icon: Icons.query_stats,
          title: 'Metricas',
          color: AppColors.violet,
          onTap: widget.onOpenStats,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - ((actions.length - 1) * 10)) /
            actions.length;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final action in actions)
              SizedBox(width: itemWidth, child: action),
          ],
        );
      },
    );
  }
}

class _StockAlertCard extends StatelessWidget {
  final int lowStock;
  final int outOfStock;
  final VoidCallback? onTap;

  const _StockAlertCard({
    required this.lowStock,
    required this.outOfStock,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.coral.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notification_important_outlined,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$outOfStock libros agotados y $lowStock con stock bajo requieren reposicion.',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.05);
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.18)),
            boxShadow: AppShadows.crisp(color),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.ink,
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

class _SmallEmpty extends StatelessWidget {
  const _SmallEmpty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No tienes libros todavia',
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/book_card.dart';
import 'add_book_screen.dart';
import 'scanner_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _databaseService = DatabaseService.instance;

  String _searchQuery = '';
  String _filter = 'all';
  bool _isLoading = true;
  List<Book> _books = [];

  List<Book> get _filteredBooks {
    var filtered = _books;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final normalizedQuery = _normalizeCode(_searchQuery);
      filtered = filtered
          .where(
            (book) =>
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.isbn.toLowerCase().contains(query) ||
                _normalizeCode(book.isbn).contains(normalizedQuery),
          )
          .toList();
    }

    if (_filter == 'lowStock') {
      filtered =
          filtered.where((book) => book.stock <= 10 && book.stock > 0).toList();
    } else if (_filter == 'outOfStock') {
      filtered = filtered.where((book) => book.stock == 0).toList();
    }

    return filtered;
  }

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por título, autor o ISBN',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _scanAndSearch,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Escanear ISBN',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Todos', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Stock bajo', 'lowStock'),
                const SizedBox(width: 8),
                _buildFilterChip('Agotados', 'outOfStock'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_isLoading && _books.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildInventorySummary(),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron libros',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return BookCard(
                            book: book,
                            onTap: () {
                              _showBookDetail(context, book);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddBookScreen(),
        icon: const Icon(Icons.add),
        label: const Text('Agregar libro'),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
    );
  }

  Widget _buildInventorySummary() {
    final lowStock =
        _books.where((book) => book.stock <= 10 && book.stock > 0).length;
    final outOfStock = _books.where((book) => book.stock == 0).length;
    final inventoryValue = _books.fold<int>(
      0,
      (total, book) => total + (book.price * book.stock),
    );

    final summaryItems = [
      _buildSummaryPill(
        label: 'Libros',
        value: _books.length.toString(),
        color: AppColors.teal,
      ),
      _buildSummaryPill(
        label: 'Stock bajo',
        value: lowStock.toString(),
        color: AppColors.amber,
      ),
      _buildSummaryPill(
        label: 'Agotados',
        value: outOfStock.toString(),
        color: AppColors.coral,
      ),
      _buildSummaryPill(
        label: 'Valor',
        value: _formatCurrency(inventoryValue),
        color: AppColors.leaf,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: summaryItems[0]),
                  const SizedBox(width: 8),
                  Expanded(child: summaryItems[1]),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: summaryItems[2]),
                  const SizedBox(width: 8),
                  Expanded(child: summaryItems[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: summaryItems[0]),
            const SizedBox(width: 8),
            Expanded(child: summaryItems[1]),
            const SizedBox(width: 8),
            Expanded(child: summaryItems[2]),
            const SizedBox(width: 8),
            Expanded(child: summaryItems[3]),
          ],
        );
      },
    );
  }

  String _formatCurrency(int value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(0)}K';
    }

    return '\$$value';
  }

  Widget _buildSummaryPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookDetail(BuildContext context, Book book) {
    final stockColor = _stockColor(book);
    final statusText = _stockStatus(book);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.menu_book,
                    color: AppColors.teal,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.author,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: stockColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: stockColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Precio',
                    value: '\$${book.price}',
                    icon: Icons.attach_money,
                    color: AppColors.leaf,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Stock',
                    value: book.stock.toString(),
                    icon: Icons.inventory_2_outlined,
                    color: stockColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildDetailRow('ISBN', book.isbn),
            _buildDetailRow('Género', book.genre),
            _buildDetailRow(
              'Valor en inventario',
              '\$${book.price * book.stock}',
            ),
            const SizedBox(height: 12),
            const Text(
              'Descripción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              book.description,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                if (book.id != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _confirmDeleteBook(book);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.coral,
                      ),
                      child: const Text('Eliminar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _openEditBookScreen(book);
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showMessage(
                        context,
                        'Agregar al pedido: ${book.title}',
                      );
                    },
                    child: const Text('Pedido'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _stockColor(Book book) {
    if (book.stock == 0) return AppColors.coral;
    if (book.stock <= 10) return AppColors.amber;
    return AppColors.leaf;
  }

  String _stockStatus(Book book) {
    if (book.stock == 0) return 'Agotado';
    if (book.stock <= 10) return 'Stock bajo';
    return 'Disponible';
  }

  void _scanAndSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null && result is String) {
      if (!mounted) return;

      _handleScannedCode(result);
    }
  }

  void _handleScannedCode(String code) {
    final scannedCode = code.trim();
    if (scannedCode.isEmpty) return;

    _searchController.text = scannedCode;
    setState(() {
      _searchQuery = scannedCode;
    });

    final book = _findBookByIsbn(scannedCode);
    if (book != null) {
      _showMessage(context, 'Libro encontrado: ${book.title}');
      _showBookDetail(context, book);
      return;
    }

    _promptAddScannedBook(scannedCode);
  }

  Book? _findBookByIsbn(String code) {
    final normalizedCode = _normalizeCode(code);

    for (final book in _books) {
      if (_normalizeCode(book.isbn) == normalizedCode) {
        return book;
      }
    }

    return null;
  }

  String _normalizeCode(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Future<void> _promptAddScannedBook(String code) async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ISBN no encontrado'),
        content: Text(
          'No hay un libro con el código "$code" en el inventario. '
          '¿Quieres agregarlo ahora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.add),
            label: const Text('Agregar libro'),
          ),
        ],
      ),
    );

    if (shouldAdd != true || !mounted) return;

    await _openAddBookScreen(initialIsbn: code);
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _databaseService.getBooks();

      if (!mounted) return;

      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      _showMessage(context, 'No se pudo cargar la base de datos: $error');
    }
  }

  Future<void> _openAddBookScreen({String? initialIsbn}) async {
    final book = await Navigator.push<Book>(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookScreen(initialIsbn: initialIsbn),
      ),
    );

    if (book == null) return;

    try {
      await _databaseService.insertBook(book);

      if (!mounted) return;

      await _loadBooks();
      if (!mounted) return;

      _showMessage(context, 'Libro agregado: ${book.title}');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'No se pudo guardar el libro: $error');
    }
  }

  Future<void> _openEditBookScreen(Book book) async {
    final updatedBook = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (context) => AddBookScreen(book: book)),
    );

    if (updatedBook == null) return;

    try {
      await _databaseService.updateBook(updatedBook);

      if (!mounted) return;

      await _loadBooks();
      if (!mounted) return;

      _showMessage(context, 'Libro actualizado: ${updatedBook.title}');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'No se pudo actualizar el libro: $error');
    }
  }

  Future<void> _confirmDeleteBook(Book book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar libro'),
        content: Text(
          '¿Seguro que quieres eliminar "${book.title}" del inventario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await _deleteBook(book);
  }

  Future<void> _deleteBook(Book book) async {
    final id = book.id;
    if (id == null) return;

    try {
      await _databaseService.deleteBook(id);

      if (!mounted) return;

      await _loadBooks();
      if (!mounted) return;

      _showMessage(context, 'Libro eliminado: ${book.title}');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'No se pudo eliminar el libro: $error');
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

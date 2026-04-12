import 'package:flutter/material.dart';

import '../models/book.dart';
import '../services/database_service.dart';
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
      filtered = filtered
          .where(
            (book) =>
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.isbn.toLowerCase().contains(query),
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
      appBar: AppBar(
        title: const Text('Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanAndSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
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
        onPressed: _openAddBookScreen,
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

  void _showBookDetail(BuildContext context, Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(
              book.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              book.author,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildDetailRow('ISBN', book.isbn),
            _buildDetailRow('Género', book.genre),
            _buildDetailRow('Precio', '\$${book.price}'),
            _buildDetailRow('Stock disponible', book.stock.toString()),
            const SizedBox(height: 12),
            const Text(
              'Descripción',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              book.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (book.id != null) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteBook(book);
                      },
                      child: const Text('Eliminar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showMessage(
                        context,
                        'Agregar al pedido: ${book.title}',
                      );
                    },
                    child: const Text('Agregar a pedido'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _scanAndSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null && result is String) {
      if (!mounted) return;

      _searchController.text = result;
      setState(() {
        _searchQuery = result;
      });

      _showMessage(context, 'Buscando: $result');
    }
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

  Future<void> _openAddBookScreen() async {
    final book = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (context) => const AddBookScreen()),
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

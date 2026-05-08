import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:lottie/lottie.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/bodega_inventario.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_agregar_libro.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_escaner.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_catalogo_pdf.dart';
import 'package:book_manager/caracteristicas/inventario/componentes/tarjeta_libro.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';

class InventoryScreen extends StatefulWidget {
  final bool canManageInventory;
  final bool canEditStockOnly;
  final bool showPrices;
  final bool showFullDetails;
  final bool canScanInventory;
  final Book? initialBookToOpen;
  final int initialBookOpenRequest;
  final AppUser? currentUser;

  const InventoryScreen({
    super.key,
    this.canManageInventory = false,
    this.canEditStockOnly = false,
    this.showPrices = true,
    this.showFullDetails = true,
    this.canScanInventory = true,
    this.initialBookToOpen,
    this.initialBookOpenRequest = 0,
    this.currentUser,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _databaseService = DatabaseService.instance;
  final _dataService = TemporaryDataService.instance;

  String _searchQuery = '';
  String _filter = 'all';
  bool _isLoading = true;
  int _handledBookOpenRequest = 0;
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
                book.genre.toLowerCase().contains(query) ||
                book.isbn.toLowerCase().contains(query) ||
                _normalizeCode(book.isbn).contains(normalizedQuery),
          )
          .toList();
    }

    if (_filter == 'lowStock') {
      filtered = filtered
          .where(
            (book) =>
                book.stock <= _dataService.settings.lowStockLimit &&
                book.stock > 0,
          )
          .toList();
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
  void didUpdateWidget(covariant InventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _openInitialBookIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar titulo, autor o ISBN',
                      prefixIcon: const Icon(Icons.search),
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
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed:
                      _books.isEmpty || _isLoading ? null : _showCatalogOptions,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: 'Compartir catalogo PDF',
                ),
                if (widget.canManageInventory || widget.canEditStockOnly) ...[
                  const SizedBox(width: 6),
                  IconButton.filledTonal(
                    onPressed: _showInventoryMovements,
                    icon: const Icon(Icons.warehouse_outlined),
                    tooltip: 'Bodegas y movimientos',
                  ),
                ],
                if (widget.canScanInventory) ...[
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _scanAndSearch,
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Escanear ISBN',
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Todos', 'all', Icons.auto_awesome_mosaic),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Stock bajo',
                    'lowStock',
                    Icons.warning_amber_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Agotados',
                    'outOfStock',
                    Icons.remove_shopping_cart_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (!_isLoading && _hasInventoryAlerts) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildStockAlertBanner(),
            ),
            const SizedBox(height: 10),
          ],
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBooks.isEmpty
                    ? const _EmptyLibraryState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = _filteredBooks[index];
                          return Slidable(
                            key: ValueKey(book.id ?? book.isbn),
                            startActionPane: widget.canManageInventory ||
                                    widget.canEditStockOnly
                                ? ActionPane(
                                    motion: const StretchMotion(),
                                    children: [
                                      if (widget.canManageInventory)
                                        SlidableAction(
                                          onPressed: (_) =>
                                              _openEditBookScreen(book),
                                          backgroundColor: AppColors.teal,
                                          foregroundColor: Colors.white,
                                          icon: Icons.edit_outlined,
                                          label: 'Editar',
                                        ),
                                      SlidableAction(
                                        onPressed: (_) =>
                                            _openStockEditor(book),
                                        backgroundColor: AppColors.leaf,
                                        foregroundColor: Colors.white,
                                        icon: Icons.inventory_2_outlined,
                                        label: 'Stock',
                                      ),
                                    ],
                                  )
                                : null,
                            endActionPane: widget.canManageInventory
                                ? ActionPane(
                                    motion: const DrawerMotion(),
                                    children: [
                                      SlidableAction(
                                        onPressed: (_) =>
                                            _confirmDeleteBook(book),
                                        backgroundColor: AppColors.coral,
                                        foregroundColor: Colors.white,
                                        icon: Icons.delete_outline,
                                        label: 'Eliminar',
                                      ),
                                    ],
                                  )
                                : null,
                            child: BookCard(
                              book: book,
                              showPrice: widget.showPrices,
                              animationIndex: index,
                              onTap: () {
                                _showBookDetail(context, book);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: widget.canManageInventory
          ? FloatingActionButton.extended(
              onPressed: () => _openAddBookScreen(),
              icon: const Icon(Icons.add),
              label: const Text('Agregar libro'),
            )
          : null,
    );
  }

  bool get _hasInventoryAlerts {
    return _books.any(
      (book) =>
          book.stock == 0 ||
          (book.stock <= _dataService.settings.lowStockLimit && book.stock > 0),
    );
  }

  Widget _buildStockAlertBanner() {
    final lowStock = _books
        .where(
          (book) =>
              book.stock <= _dataService.settings.lowStockLimit &&
              book.stock > 0,
        )
        .length;
    final outOfStock = _books.where((book) => book.stock == 0).length;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _filter = outOfStock > 0 ? 'outOfStock' : 'lowStock';
          });
        },
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
                  '$outOfStock agotados y $lowStock con stock bajo. '
                  'Toca para revisar prioridades.',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }

  void _openInitialBookIfNeeded() {
    final bookToOpen = widget.initialBookToOpen;
    if (bookToOpen == null ||
        widget.initialBookOpenRequest == 0 ||
        widget.initialBookOpenRequest == _handledBookOpenRequest ||
        _isLoading) {
      return;
    }

    _handledBookOpenRequest = widget.initialBookOpenRequest;
    final book = _books.firstWhere(
      (candidate) =>
          candidate.id == bookToOpen.id || candidate.isbn == bookToOpen.isbn,
      orElse: () => bookToOpen,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showBookDetail(context, book);
    });
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    return FilterChip(
      avatar: Icon(icon, size: 17, color: AppColors.ink),
      label: Text(label),
      showCheckmark: false,
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: Colors.white,
      selectedColor: Colors.white,
      side: BorderSide(
        color: _filter == value ? AppColors.teal : AppColors.border,
      ),
      selected: _filter == value,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
    );
  }

  void _showBookDetail(BuildContext context, Book book) {
    if (!widget.showFullDetails) {
      _showStockOnlyDetail(context, book);
      return;
    }

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
                  clipBehavior: Clip.antiAlias,
                  child: BookCoverImage(coverUrl: book.coverUrl),
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
                    value: CurrencyFormatService.money(
                      book.price,
                      _dataService.settings.currencySymbol,
                    ),
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
            _buildDetailRow('Categoria', book.genre),
            _buildDetailRow('Estado', statusText),
            _buildDetailRow(
              'Valor en inventario',
              CurrencyFormatService.money(
                book.price * book.stock,
                _dataService.settings.currencySymbol,
              ),
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
                if (widget.canManageInventory && book.id != null) ...[
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
                if (widget.canManageInventory) ...[
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
                ],
                if (widget.canManageInventory && widget.canEditStockOnly)
                  const SizedBox(width: 12),
                if (widget.canEditStockOnly)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _openStockEditor(book);
                      },
                      child: const Text('Stock'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStockOnlyDetail(BuildContext context, Book book) {
    final stockColor = _stockColor(book);
    final statusText = _stockStatus(book);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              book.author,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: stockColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock actual: ${book.stock}',
                    style: TextStyle(
                      color: stockColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: stockColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.canEditStockOnly) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openStockEditor(book);
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Actualizar stock'),
                ),
              ),
            ],
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
    if (book.stock <= _dataService.settings.lowStockLimit) {
      return AppColors.amber;
    }
    return AppColors.leaf;
  }

  String _stockStatus(Book book) {
    if (book.stock == 0) return 'Agotado';
    if (book.stock <= _dataService.settings.lowStockLimit) return 'Stock bajo';
    return 'Disponible';
  }

  void _scanAndSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerScreen(
          currentUser: widget.currentUser,
          books: _books,
        ),
      ),
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
      _openInitialBookIfNeeded();
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
        builder: (context) => AddBookScreen(
          initialIsbn: initialIsbn,
          currentUser: widget.currentUser,
        ),
      ),
    );

    if (book == null) return;

    try {
      await _databaseService.insertBook(book);
      await ActivityLogService.instance.record(
        type: ActivityType.inventory,
        title: 'Libro agregado',
        detail: '${book.title} entro con ${book.stock} unidades.',
        actor: widget.currentUser,
        entityType: 'libro',
        entityId: book.isbn,
        entityName: book.title,
      );

      if (!mounted) return;

      await _loadBooks();
      if (!mounted) return;

      _showMessage(context, 'Libro agregado: ${book.title}');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'No se pudo guardar el libro: $error');
    }
  }

  Future<void> _showCatalogOptions() async {
    final genres = _books.map((book) => book.genre).toSet().toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    var options = CatalogPdfOptions(includePrices: widget.showPrices);
    var isGenerating = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.coral.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: AppColors.coral,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Catalogo PDF',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'Configura que informacion quieres compartir.',
                                style: TextStyle(
                                  color: AppColors.muted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: options.genre,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas las categorias'),
                        ),
                        ...genres.map(
                          (genre) => DropdownMenuItem(
                            value: genre,
                            child: Text(genre),
                          ),
                        ),
                      ],
                      onChanged: (genre) {
                        setSheetState(() {
                          options = options.copyWith(
                            genre: genre,
                            clearGenre: genre == null,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Solo libros disponibles'),
                      subtitle: const Text(
                        'Desactivalo para que tambien salgan agotados.',
                      ),
                      value: options.onlyAvailable,
                      onChanged: (value) {
                        setSheetState(() {
                          options = options.copyWith(
                            onlyAvailable: value,
                            includeOutOfStock:
                                value ? false : options.includeOutOfStock,
                          );
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Incluir stock bajo'),
                      subtitle: Text(
                        'Usa el limite actual: ${_dataService.settings.lowStockLimit} unidades.',
                      ),
                      value: options.includeLowStock,
                      onChanged: (value) {
                        setSheetState(() {
                          options = options.copyWith(includeLowStock: value);
                        });
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Incluir agotados'),
                      subtitle: const Text(
                        'Aparecen marcados como agotados en el PDF.',
                      ),
                      value: options.includeOutOfStock,
                      onChanged: options.onlyAvailable
                          ? null
                          : (value) {
                              setSheetState(() {
                                options =
                                    options.copyWith(includeOutOfStock: value);
                              });
                            },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mostrar precios'),
                      subtitle: widget.showPrices
                          ? const Text('Incluye precio comercial.')
                          : const Text('No disponible para este rol.'),
                      value: options.includePrices,
                      onChanged: widget.showPrices
                          ? (value) {
                              setSheetState(() {
                                options = options.copyWith(
                                  includePrices: value,
                                );
                              });
                            }
                          : null,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mostrar stock'),
                      subtitle: const Text('Incluye unidades disponibles.'),
                      value: options.includeStock,
                      onChanged: (value) {
                        setSheetState(() {
                          options = options.copyWith(includeStock: value);
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: isGenerating
                          ? null
                          : () async {
                              setSheetState(() => isGenerating = true);
                              await _shareCatalogPdf(options);
                              if (!mounted || !sheetContext.mounted) return;
                              setSheetState(() => isGenerating = false);
                              Navigator.of(sheetContext).pop();
                            },
                      icon: isGenerating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.ios_share_outlined),
                      label: const Text('Generar y compartir'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareCatalogPdf(CatalogPdfOptions options) async {
    try {
      await CatalogPdfService.instance.shareCatalog(
        books: _books,
        settings: _dataService.settings,
        options: options,
      );
      await ActivityLogService.instance.record(
        type: ActivityType.inventory,
        title: 'Catalogo PDF compartido',
        detail: 'Se genero un catalogo con filtros comerciales.',
        actor: widget.currentUser,
      );
      if (!mounted) return;
      _showMessage(context, 'Catalogo PDF listo para compartir.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(context, 'No se pudo generar el catalogo: $error');
    }
  }

  Future<void> _openEditBookScreen(Book book) async {
    final updatedBook = await Navigator.push<Book>(
      context,
      MaterialPageRoute(
        builder: (context) => AddBookScreen(
          book: book,
          currentUser: widget.currentUser,
        ),
      ),
    );

    if (updatedBook == null) return;

    try {
      await _databaseService.updateBook(updatedBook);
      await ActivityLogService.instance.record(
        type: ActivityType.inventory,
        title: 'Libro editado',
        detail:
            '${updatedBook.title} paso de ${book.stock} a ${updatedBook.stock} unidades.',
        actor: widget.currentUser,
      );

      if (!mounted) return;

      await _loadBooks();
      if (!mounted) return;

      _showMessage(context, 'Libro actualizado: ${updatedBook.title}');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'No se pudo actualizar el libro: $error');
    }
  }

  Future<void> _openStockEditor(Book book) async {
    final controller = TextEditingController(text: book.stock.toString());
    final observationController = TextEditingController();
    var selectedWarehouse = _dataService.warehouses.first;
    var movementType = 'ajuste';

    final newStock = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Movimiento de inventario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<AppWarehouse>(
                  initialValue: selectedWarehouse,
                  decoration: const InputDecoration(
                    labelText: 'Bodega',
                    prefixIcon: Icon(Icons.warehouse_outlined),
                  ),
                  items: _dataService.warehouses
                      .map(
                        (warehouse) => DropdownMenuItem(
                          value: warehouse,
                          child: Text(warehouse.name),
                        ),
                      )
                      .toList(),
                  onChanged: (warehouse) {
                    if (warehouse == null) return;
                    setDialogState(() => selectedWarehouse = warehouse);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: movementType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimiento',
                    prefixIcon: Icon(Icons.swap_vert),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'entrada', child: Text('Entrada')),
                    DropdownMenuItem(value: 'salida', child: Text('Salida')),
                    DropdownMenuItem(value: 'ajuste', child: Text('Ajuste')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => movementType = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Stock final',
                    helperText: '${book.title} - actual ${book.stock}',
                    prefixIcon: const Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: observationController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observacion',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final stock = int.tryParse(controller.text);
                if (stock == null || stock < 0) return;
                Navigator.pop(context, stock);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    final observation = observationController.text.trim();
    observationController.dispose();

    if (newStock == null) return;

    final updatedBook = book.copyWith(stock: newStock);
    final quantity = (newStock - book.stock).abs();

    try {
      await _databaseService.updateBook(updatedBook);
      await _dataService.addInventoryMovement(
        InventoryMovementRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          movementType: movementType,
          warehouse: selectedWarehouse,
          user: widget.currentUser,
          total: quantity,
          observation: observation.isEmpty ? 'Sin observacion' : observation,
          details: [
            InventoryMovementDetail(
              bookIsbn: book.isbn,
              bookTitle: book.title,
              quantity: quantity,
            ),
          ],
        ),
      );
      await ActivityLogService.instance.record(
        type: ActivityType.inventory,
        title: 'Movimiento de inventario',
        detail:
            '${selectedWarehouse.name}: ${book.title} ${book.stock} -> ${updatedBook.stock}.',
        actor: widget.currentUser,
      );
      await _loadBooks();
      if (!mounted) return;
      _showMessage(context, 'Stock actualizado: ${updatedBook.stock}');
    } catch (error) {
      if (!mounted) return;
      _showMessage(context, 'No se pudo actualizar el stock: $error');
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
      await ActivityLogService.instance.record(
        type: ActivityType.inventory,
        title: 'Libro eliminado',
        detail: '${book.title} fue retirado del inventario.',
        actor: widget.currentUser,
      );

      if (!mounted) return;

      await _loadBooks();
      if (!mounted) return;

      _showMessage(context, 'Libro eliminado: ${book.title}');
    } catch (error) {
      if (!mounted) return;

      _showMessage(context, 'No se pudo eliminar el libro: $error');
    }
  }

  Future<void> _showInventoryMovements() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => AnimatedBuilder(
        animation: _dataService,
        builder: (context, _) {
          final movements = _dataService.inventoryMovements;
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.78,
            minChildSize: 0.48,
            maxChildSize: 0.94,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Bodegas y movimientos',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (widget.canManageInventory)
                      IconButton.filled(
                        onPressed: _openWarehouseSheet,
                        icon: const Icon(Icons.add_business_outlined),
                        tooltip: 'Agregar bodega',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final warehouse in _dataService.warehouses)
                      Chip(
                        avatar: const Icon(Icons.warehouse_outlined, size: 16),
                        label:
                            Text('${warehouse.name} - ${warehouse.location}'),
                      ),
                  ],
                ),
                const Divider(height: 28),
                if (movements.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 44),
                    child: Text(
                      'Aun no hay movimientos registrados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  for (final movement in movements) ...[
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.swap_vert),
                        title: Text(
                          '${movement.movementType} - ${movement.warehouse.name}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          '${movement.details.map((detail) => '${detail.bookTitle} (${detail.quantity})').join(', ')}\n'
                          '${movement.observation} - ${movement.user?.name ?? 'Sistema'}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          _formatShortDate(movement.date),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openWarehouseSheet() async {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva bodega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Ubicacion'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await _dataService.addWarehouse(
                name: nameController.text,
                location: locationController.text,
              );
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    nameController.dispose();
    locationController.dispose();
    if (saved == true && mounted) {
      _showMessage(context, 'Bodega agregada');
    }
  }

  String _formatShortDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 330;
        final lottieHeight = compact ? 96.0 : 180.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: compact ? 140 : 220,
                  height: lottieHeight,
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_qmfs6c3i.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'No tienes libros todavia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Agrega tu primer libro o ajusta los filtros para verlo aqui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 360.ms).slideY(begin: 0.08);
  }
}

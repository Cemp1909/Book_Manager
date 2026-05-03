import 'package:flutter/services.dart';
import 'package:book_manager/datos/modelos/configuracion_empresa.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CatalogPdfOptions {
  final bool onlyAvailable;
  final bool includeLowStock;
  final bool includeOutOfStock;
  final bool includePrices;
  final bool includeStock;
  final String? genre;

  const CatalogPdfOptions({
    this.onlyAvailable = false,
    this.includeLowStock = true,
    this.includeOutOfStock = true,
    this.includePrices = true,
    this.includeStock = true,
    this.genre,
  });

  CatalogPdfOptions copyWith({
    bool? onlyAvailable,
    bool? includeLowStock,
    bool? includeOutOfStock,
    bool? includePrices,
    bool? includeStock,
    String? genre,
    bool clearGenre = false,
  }) {
    return CatalogPdfOptions(
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      includeLowStock: includeLowStock ?? this.includeLowStock,
      includeOutOfStock: includeOutOfStock ?? this.includeOutOfStock,
      includePrices: includePrices ?? this.includePrices,
      includeStock: includeStock ?? this.includeStock,
      genre: clearGenre ? null : genre ?? this.genre,
    );
  }
}

class CatalogPdfService {
  CatalogPdfService._();

  static final CatalogPdfService instance = CatalogPdfService._();
  static const _logoAsset = 'assets/branding/logo.jpeg';

  Future<Uint8List> buildCatalog({
    required List<Book> books,
    required CompanySettings settings,
    required CatalogPdfOptions options,
  }) async {
    final catalogBooks = _filterBooks(
      books,
      options,
      settings.lowStockLimit,
    );
    final logo = await _loadLogo();
    final generatedAt = DateTime.now();
    final document = pw.Document(
      title: 'Catalogo ${settings.companyName}',
      author: settings.companyName,
      creator: 'Editorial Manager',
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          margin: pw.EdgeInsets.all(28),
        ),
        header: (context) => _buildHeader(settings, generatedAt, logo),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildCover(settings, catalogBooks, books, options, generatedAt),
          pw.SizedBox(height: 18),
          _buildSummary(books, catalogBooks, settings.lowStockLimit),
          pw.SizedBox(height: 18),
          _buildBookTable(catalogBooks, settings, options),
        ],
      ),
    );

    return document.save();
  }

  Future<void> shareCatalog({
    required List<Book> books,
    required CompanySettings settings,
    required CatalogPdfOptions options,
  }) async {
    final bytes = await buildCatalog(
      books: books,
      settings: settings,
      options: options,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: _fileName(settings.companyName),
    );
  }

  List<Book> _filterBooks(
    List<Book> books,
    CatalogPdfOptions options,
    int lowStockLimit,
  ) {
    return books.where((book) {
      if (options.genre != null && book.genre != options.genre) return false;
      if (options.onlyAvailable && book.stock <= 0) return false;
      if (!options.includeLowStock &&
          book.stock > 0 &&
          book.stock <= lowStockLimit) {
        return false;
      }
      if (!options.onlyAvailable &&
          !options.includeOutOfStock &&
          book.stock == 0) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  pw.Widget _buildHeader(
    CompanySettings settings,
    DateTime generatedAt,
    pw.MemoryImage? logo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
          if (logo != null)
            pw.Container(
              width: 32,
              height: 32,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          if (logo != null) pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  settings.companyName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Catalogo comercial - ${_formatDate(generatedAt)}',
                  style: const pw.TextStyle(
                    color: PdfColors.grey600,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCover(
    CompanySettings settings,
    List<Book> catalogBooks,
    List<Book> allBooks,
    CatalogPdfOptions options,
    DateTime generatedAt,
  ) {
    final totalUnits = catalogBooks.fold<int>(
      0,
      (total, book) => total + book.stock,
    );
    final inventoryValue = catalogBooks.fold<int>(
      0,
      (total, book) => total + book.stock * book.price,
    );

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(22),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F172A'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Catalogo de libros disponibles',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generado para ventas, colegios, librerias y clientes comerciales.',
            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 11),
          ),
          pw.SizedBox(height: 18),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _coverMetric('Titulos', catalogBooks.length.toString()),
              _coverMetric('Unidades', totalUnits.toString()),
              if (options.includePrices)
                _coverMetric(
                  'Valor disponible',
                  _money(inventoryValue, settings.currencySymbol),
                ),
              _coverMetric('Filtro', _optionsLabel(options)),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Text(
            '${allBooks.length} titulos totales en inventario. '
            'Catalogo generado el ${_formatDate(generatedAt)}.',
            style: const pw.TextStyle(color: PdfColors.grey300, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _coverMetric(String label, String value) {
    return pw.Container(
      width: 118,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            value,
            maxLines: 1,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummary(
    List<Book> allBooks,
    List<Book> catalogBooks,
    int lowStockLimit,
  ) {
    final available = allBooks.where((book) => book.stock > 0).length;
    final lowStock = allBooks
        .where((book) => book.stock > 0 && book.stock <= lowStockLimit)
        .length;
    final outOfStock = allBooks.where((book) => book.stock == 0).length;

    return pw.Row(
      children: [
        _summaryBox('En catalogo', catalogBooks.length.toString()),
        pw.SizedBox(width: 8),
        _summaryBox('Disponibles', available.toString()),
        pw.SizedBox(width: 8),
        _summaryBox('Stock bajo', lowStock.toString()),
        pw.SizedBox(width: 8),
        _summaryBox('Agotados', outOfStock.toString()),
      ],
    );
  }

  pw.Widget _summaryBox(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              label,
              style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildBookTable(
    List<Book> books,
    CompanySettings settings,
    CatalogPdfOptions options,
  ) {
    if (books.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(18),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text(
          'No hay libros que coincidan con los filtros seleccionados.',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    final headers = [
      'Titulo',
      'Autor',
      'ISBN',
      'Categoria',
      if (options.includePrices) 'Precio',
      if (options.includeStock) 'Stock',
      'Estado',
    ];

    final rows = books.map((book) {
      return [
        book.title,
        book.author,
        book.isbn,
        book.genre,
        if (options.includePrices) _money(book.price, settings.currencySymbol),
        if (options.includeStock) book.stock.toString(),
        _stockStatus(book, settings.lowStockLimit),
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: null,
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F172A'),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Pagina ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
      ),
    );
  }

  Future<pw.MemoryImage?> _loadLogo() async {
    try {
      final bytes = await rootBundle.load(_logoAsset);
      return pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  String _fileName(String companyName) {
    final normalizedCompany = companyName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final date = DateTime.now();
    return 'catalogo_${normalizedCompany}_${date.year}_${date.month.toString().padLeft(2, '0')}_${date.day.toString().padLeft(2, '0')}.pdf';
  }

  String _stockStatus(Book book, int lowStockLimit) {
    if (book.stock == 0) return 'Agotado';
    if (book.stock <= lowStockLimit) return 'Stock bajo';
    return 'Disponible';
  }

  String _optionsLabel(CatalogPdfOptions options) {
    if (options.genre != null) return options.genre!;
    if (options.onlyAvailable) return 'Disponibles';
    if (options.includeOutOfStock) return 'Completo';
    return 'Comercial';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _money(int value, String currency) {
    final formatted = value.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
    return '$currency $formatted';
  }
}

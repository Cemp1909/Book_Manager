import 'dart:typed_data';

import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';
import 'package:book_manager/datos/modelos/configuracion_empresa.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

enum BusinessReportType {
  inventory('Inventario actual', 'inventario_actual'),
  ordersBySchool('Pedidos por colegio', 'pedidos_por_colegio'),
  returns('Devoluciones', 'devoluciones'),
  dispatches('Despachos', 'despachos'),
  salesByCitySchool('Ventas por ciudad/colegio', 'ventas_ciudad_colegio');

  final String label;
  final String fileName;

  const BusinessReportType(this.label, this.fileName);
}

class BusinessReportPdfService {
  BusinessReportPdfService._();

  static final BusinessReportPdfService instance = BusinessReportPdfService._();

  Future<void> shareReport({
    required BusinessReportType type,
    required List<Book> books,
    required TemporaryDataService dataService,
  }) async {
    final bytes = await buildReport(
      type: type,
      books: books,
      dataService: dataService,
    );
    final date = DateTime.now();
    await Printing.sharePdf(
      bytes: bytes,
      filename:
          '${type.fileName}_${date.year}_${_two(date.month)}_${_two(date.day)}.pdf',
    );
  }

  Future<Uint8List> buildReport({
    required BusinessReportType type,
    required List<Book> books,
    required TemporaryDataService dataService,
  }) async {
    final settings = dataService.settings;
    final document = pw.Document(
      title: type.label,
      author: settings.companyName,
      creator: 'Editorial Manager',
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(28)),
        header: (context) => _header(type.label, settings),
        footer: (context) => _footer(context),
        build: (context) => [
          _summary(type, books, dataService),
          pw.SizedBox(height: 18),
          ..._content(type, books, dataService),
        ],
      ),
    );

    return document.save();
  }

  List<pw.Widget> _content(
    BusinessReportType type,
    List<Book> books,
    TemporaryDataService dataService,
  ) {
    return switch (type) {
      BusinessReportType.inventory => [
          _inventoryTable(books, dataService.settings)
        ],
      BusinessReportType.ordersBySchool => [_ordersBySchoolTable(dataService)],
      BusinessReportType.returns => [_returnsTable(dataService)],
      BusinessReportType.dispatches => [_dispatchesTable(dataService)],
      BusinessReportType.salesByCitySchool => [
          _salesByCitySchoolTable(dataService)
        ],
    };
  }

  pw.Widget _header(String title, CompanySettings settings) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        children: [
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
                  title,
                  style: const pw.TextStyle(
                    color: PdfColors.grey600,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          pw.Text(
            _formatDate(DateTime.now()),
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _summary(
    BusinessReportType type,
    List<Book> books,
    TemporaryDataService dataService,
  ) {
    final settings = dataService.settings;
    final dispatched = dataService.orders
        .where((order) => order.status == OrderStatus.dispatched)
        .fold<int>(0, (sum, order) => sum + order.total);

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F172A'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            type.label,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric('Libros', books.length.toString()),
              _metric('Pedidos', dataService.orders.length.toString()),
              _metric('Devoluciones', dataService.returns.length.toString()),
              _metric('Ventas despachadas', _money(dispatched, settings)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _metric(String label, String value) {
    return pw.Container(
      width: 124,
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
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
          ),
        ],
      ),
    );
  }

  pw.Widget _inventoryTable(List<Book> books, CompanySettings settings) {
    return _table(
      headers: const [
        'Titulo',
        'ISBN',
        'Categoria',
        'Precio',
        'Stock',
        'Estado'
      ],
      rows: books
          .map(
            (book) => [
              book.title,
              book.isbn,
              book.genre,
              _money(book.price, settings),
              book.stock.toString(),
              _stockStatus(book, settings.lowStockLimit),
            ],
          )
          .toList(),
    );
  }

  pw.Widget _ordersBySchoolTable(TemporaryDataService dataService) {
    final rows = dataService.schools.map((school) {
      final orders = dataService.orders
          .where((order) =>
              order.customer.toLowerCase() == school.name.toLowerCase())
          .toList();
      final total = orders.fold<int>(0, (sum, order) => sum + order.total);
      return [
        dataService.cityById(school.cityId)?.name ?? 'Sin ciudad',
        school.name,
        orders.length.toString(),
        orders
            .where((order) => order.status != OrderStatus.dispatched)
            .length
            .toString(),
        _money(total, dataService.settings),
      ];
    }).toList();

    return _table(
      headers: const ['Ciudad', 'Colegio', 'Pedidos', 'Activos', 'Total'],
      rows: rows,
    );
  }

  pw.Widget _returnsTable(TemporaryDataService dataService) {
    return _table(
      headers: const [
        'Pedido',
        'Cliente',
        'Producto',
        'Cant.',
        'Estado',
        'Motivo'
      ],
      rows: dataService.returns
          .map(
            (record) => [
              record.orderId,
              record.customer,
              record.itemTitle,
              record.quantity.toString(),
              record.status.label,
              record.reason,
            ],
          )
          .toList(),
    );
  }

  pw.Widget _dispatchesTable(TemporaryDataService dataService) {
    final dispatches = dataService.orders
        .where(
          (order) =>
              order.status == OrderStatus.ready ||
              order.status == OrderStatus.dispatched,
        )
        .toList();

    return _table(
      headers: const ['Pedido', 'Cliente', 'Direccion', 'Estado', 'Total'],
      rows: dispatches
          .map(
            (order) => [
              order.id,
              order.customer,
              order.deliveryAddress,
              order.status.label,
              _money(order.total, dataService.settings),
            ],
          )
          .toList(),
    );
  }

  pw.Widget _salesByCitySchoolTable(TemporaryDataService dataService) {
    final rows = <List<String>>[];
    for (final school in dataService.schools) {
      final orders = dataService.orders
          .where((order) =>
              order.customer.toLowerCase() == school.name.toLowerCase())
          .toList();
      if (orders.isEmpty) continue;
      final dispatched =
          orders.where((order) => order.status == OrderStatus.dispatched);
      final total = orders.fold<int>(0, (sum, order) => sum + order.total);
      rows.add([
        dataService.cityById(school.cityId)?.name ?? 'Sin ciudad',
        school.name,
        orders.length.toString(),
        dispatched.length.toString(),
        _money(total, dataService.settings),
      ]);
    }

    return _table(
      headers: const ['Ciudad', 'Colegio', 'Pedidos', 'Despachados', 'Ventas'],
      rows: rows,
    );
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Text('No hay datos para este reporte.'),
      );
    }

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      border: null,
      headerDecoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F766E'),
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

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Pagina ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
      ),
    );
  }

  String _stockStatus(Book book, int lowStockLimit) {
    if (book.stock == 0) return 'Agotado';
    if (book.stock <= lowStockLimit) return 'Stock bajo';
    return 'Disponible';
  }

  String _money(int value, CompanySettings settings) {
    return CurrencyFormatService.money(value, settings.currencySymbol);
  }

  String _formatDate(DateTime date) {
    return '${_two(date.day)}/${_two(date.month)}/${date.year}';
  }

  String _two(int value) {
    return value.toString().padLeft(2, '0');
  }
}

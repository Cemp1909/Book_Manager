import 'package:flutter/services.dart';
import 'package:book_manager/datos/modelos/configuracion_empresa.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/caracteristicas/pedidos/servicios/descarga_pdf_stub.dart'
    if (dart.library.html) 'package:book_manager/caracteristicas/pedidos/servicios/descarga_pdf_web.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class DispatchPdfService {
  DispatchPdfService._();

  static final DispatchPdfService instance = DispatchPdfService._();
  static const _logoAsset = 'assets/branding/logo.jpeg';

  Future<Uint8List> buildDispatchGuide({
    required AppOrder order,
    required CompanySettings settings,
  }) async {
    final logo = await _loadLogo();
    final generatedAt = DateTime.now();
    final document = pw.Document(
      title: 'Remision ${order.id}',
      author: settings.companyName,
      creator: 'Editorial Manager',
    );

    document.addPage(
      pw.Page(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(28)),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(settings, order, generatedAt, logo),
            pw.SizedBox(height: 24),
            _buildInfoBlock(order),
            pw.SizedBox(height: 22),
            _buildItemsTable(order, settings.currencySymbol),
            pw.Spacer(),
            _buildSignatures(),
            pw.SizedBox(height: 18),
            _buildFooter(),
          ],
        ),
      ),
    );

    return document.save();
  }

  Future<void> shareDispatchGuide({
    required AppOrder order,
    required CompanySettings settings,
  }) async {
    final bytes = await buildDispatchGuide(order: order, settings: settings);
    await downloadPdfBytes(
      bytes: bytes,
      filename: 'remision_${order.id}.pdf',
    );
  }

  pw.Widget _buildHeader(
    CompanySettings settings,
    AppOrder order,
    DateTime generatedAt,
    pw.MemoryImage? logo,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F766E'),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.Container(
              width: 46,
              height: 46,
              padding: const pw.EdgeInsets.all(5),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          if (logo != null) pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  settings.companyName,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Remision / guia de despacho',
                  style: const pw.TextStyle(
                    color: PdfColors.grey200,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                '#${order.id}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                _formatDate(generatedAt),
                style: const pw.TextStyle(
                  color: PdfColors.grey200,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoBlock(AppOrder order) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _infoRow('Cliente', order.customer),
          _infoRow('Direccion de entrega', order.deliveryAddress),
          _infoRow('Fecha del pedido', _formatDate(order.date)),
          _infoRow('Estado', order.status.label),
          _infoRow('Unidades despachadas', order.itemCount.toString()),
        ],
      ),
    );
  }

  pw.Widget _buildItemsTable(AppOrder order, String currency) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#ECFDF5')),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.all(8),
      headers: const ['Producto', 'Detalle', 'Cant.', 'Valor unit.', 'Total'],
      data: order.items
          .map(
            (item) => [
              item.title,
              item.isCombo ? 'Combo - ${item.subtitle}' : item.subtitle,
              item.quantity.toString(),
              CurrencyFormatService.money(item.unitPrice, currency),
              CurrencyFormatService.money(item.total, currency),
            ],
          )
          .toList(),
    );
  }

  pw.Widget _buildSignatures() {
    return pw.Row(
      children: [
        _signatureBox('Entrega'),
        pw.SizedBox(width: 18),
        _signatureBox('Recibe'),
      ],
    );
  }

  pw.Widget _signatureBox(String label) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 1, color: PdfColors.grey500),
          pw.SizedBox(height: 6),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Text(
      'Documento generado automaticamente. Verifique cantidades al recibir.',
      style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 9),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 116,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

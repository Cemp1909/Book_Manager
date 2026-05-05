import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/caracteristicas/reportes/servicios/servicio_reportes_pdf.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/datos/modelos/libro.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _dataService = TemporaryDataService.instance;
  final _databaseService = DatabaseService.instance;
  final _reportService = BusinessReportPdfService.instance;

  List<Book> _books = [];
  BusinessReportType? _generatingType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudieron cargar libros: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            if (_isLoading)
              const LinearProgressIndicator()
            else
              for (final type in BusinessReportType.values) ...[
                _ReportCard(
                  type: type,
                  busy: _generatingType == type,
                  onGenerate: () => _generate(type),
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.picture_as_pdf, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reportes PDF',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Genera documentos para inventario, pedidos, devoluciones y ventas.',
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
      ),
    );
  }

  Future<void> _generate(BusinessReportType type) async {
    setState(() => _generatingType = type);
    try {
      await _reportService.shareReport(
        type: type,
        books: _books,
        dataService: _dataService,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar el reporte: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _generatingType = null);
      }
    }
  }
}

class _ReportCard extends StatelessWidget {
  final BusinessReportType type;
  final bool busy;
  final VoidCallback onGenerate;

  const _ReportCard({
    required this.type,
    required this.busy,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: const Icon(Icons.description_outlined, color: AppColors.teal),
        title: Text(
          type.label,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(_description(type)),
        trailing: FilledButton.icon(
          onPressed: busy ? null : onGenerate,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('PDF'),
        ),
      ),
    );
  }

  String _description(BusinessReportType type) {
    return switch (type) {
      BusinessReportType.inventory => 'Listado de libros, stock y estado.',
      BusinessReportType.ordersBySchool => 'Resumen de pedidos por colegio.',
      BusinessReportType.returns => 'Devoluciones con motivo y estado.',
      BusinessReportType.dispatches => 'Pedidos listos o despachados.',
      BusinessReportType.salesByCitySchool =>
        'Ventas agrupadas por ciudad y colegio.',
    };
  }
}

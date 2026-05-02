import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/caracteristicas/estadisticas/componentes/d3_chart_data.dart';
import 'package:book_manager/caracteristicas/estadisticas/componentes/d3_chart_view.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dataService = TemporaryDataService.instance;

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        return FutureBuilder<List<Book>>(
          future: DatabaseService.instance.getBooks(),
          builder: (context, snapshot) {
            final books = snapshot.data ?? const <Book>[];
            final orders = dataService.orders;
            final categories = _categoryCounts(books);
            final inventoryValue = _inventoryValue(books);
            final currency = dataService.settings.currencySymbol;
            final lowStockLimit = dataService.settings.lowStockLimit;
            final lowStock = _lowStockCount(books, lowStockLimit);
            final outOfStock = _outOfStockCount(books);
            final available = books.length - lowStock - outOfStock;
            final totalUnits = books.fold(0, (sum, book) => sum + book.stock);

            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatsHeader(total: books.length),
                const SizedBox(height: 16),
                _MetricGrid(
                  metrics: [
                    _MetricInfo(
                      label: 'Pedidos del dia',
                      value: dataService.todayOrders.toString(),
                      icon: Icons.today_outlined,
                      color: AppColors.teal,
                    ),
                    _MetricInfo(
                      label: 'Pendientes',
                      value: dataService.pendingOrders.toString(),
                      icon: Icons.pending_actions,
                      color: AppColors.amber,
                    ),
                    _MetricInfo(
                      label: 'Despachados',
                      value: dataService.dispatchedOrders.toString(),
                      icon: Icons.local_shipping_outlined,
                      color: AppColors.leaf,
                    ),
                    _MetricInfo(
                      label: 'Valor libros',
                      value: _compactMoney(inventoryValue, currency),
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.violet,
                    ),
                    _MetricInfo(
                      label: 'Ingresos',
                      value: _compactMoney(dataService.income, currency),
                      icon: Icons.payments_outlined,
                      color: AppColors.coral,
                    ),
                    _MetricInfo(
                      label: 'Stock bajo',
                      value: lowStock.toString(),
                      icon: Icons.warning_amber_outlined,
                      color: AppColors.sky,
                    ),
                    _MetricInfo(
                      label: 'Agotados',
                      value: outOfStock.toString(),
                      icon: Icons.remove_shopping_cart_outlined,
                      color: AppColors.coral,
                    ),
                    _MetricInfo(
                      label: 'Unidades',
                      value: totalUnits.toString(),
                      icon: Icons.stacked_bar_chart,
                      color: AppColors.leaf,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ChartDashboardGrid(
                  charts: [
                    D3ChartView(
                      title: 'Disponibilidad de inventario',
                      subtitle: 'Clic sobre cada segmento para leer el estado.',
                      kind: D3ChartKind.donut,
                      height: 360,
                      data: [
                        D3ChartDatum(
                          label: 'Disponibles',
                          value: available,
                          color: _hex(AppColors.leaf),
                          detail:
                              'Hay inventario sano para venta o despacho inmediato.',
                        ),
                        D3ChartDatum(
                          label: 'Stock bajo',
                          value: lowStock,
                          color: _hex(AppColors.amber),
                          detail:
                              'Requieren reposicion antes de quedar agotados.',
                        ),
                        D3ChartDatum(
                          label: 'Agotados',
                          value: outOfStock,
                          color: _hex(AppColors.coral),
                          detail:
                              'No pueden comprometerse en nuevos pedidos hasta reabastecer.',
                        ),
                      ],
                    ),
                    D3ChartView(
                      title: 'Estado de pedidos',
                      subtitle: 'Distribucion del flujo operativo actual.',
                      kind: D3ChartKind.donut,
                      height: 360,
                      data: _orderStatusData(orders),
                    ),
                    D3ChartView(
                      title: 'Valor de pedidos por estado',
                      subtitle: 'Muestra dinero comprometido por etapa.',
                      kind: D3ChartKind.bars,
                      height: 360,
                      data: _orderValueByStatus(orders),
                    ),
                    D3ChartView(
                      title: 'Valor de libros por categoria',
                      subtitle: 'Categorias con mayor capital en inventario.',
                      kind: D3ChartKind.bars,
                      height: 360,
                      data: _inventoryValueByCategory(books),
                    ),
                    D3ChartView(
                      title: 'Stock por categoria',
                      subtitle: 'Volumen disponible agrupado por categoria.',
                      kind: D3ChartKind.bars,
                      height: 360,
                      data: _stockByCategory(books),
                    ),
                    D3ChartView(
                      title: 'Libros criticos de stock',
                      subtitle:
                          'Prioridad de reposicion segun limite configurado.',
                      kind: D3ChartKind.bars,
                      height: 360,
                      data: _criticalStockBooks(books, lowStockLimit),
                    ),
                    D3ChartView(
                      title: 'Precio vs stock',
                      subtitle:
                          'Burbujas: precio, unidades y valor inmovilizado.',
                      kind: D3ChartKind.bubble,
                      height: 360,
                      data: _priceStockBubbles(books),
                    ),
                    D3ChartView(
                      title: 'Categorias mas usadas',
                      subtitle: 'Cantidad de titulos por categoria.',
                      kind: D3ChartKind.bars,
                      height: 360,
                      data: [
                        for (final entry in categories.entries)
                          D3ChartDatum(
                            label: entry.key,
                            value: entry.value,
                            color: _hex(AppColors.teal),
                            detail:
                                'Esta categoria concentra ${entry.value} titulos del catalogo.',
                          ),
                      ],
                    ),
                    D3ChartView(
                      title: 'Libros con mas unidades',
                      subtitle: 'Titulos con mayor disponibilidad fisica.',
                      kind: D3ChartKind.bars,
                      height: 360,
                      data: _topStockBooks(books),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Map<String, int> _categoryCounts(List<Book> books) {
    final counts = <String, int>{};
    for (final book in books) {
      counts.update(book.genre, (value) => value + 1, ifAbsent: () => 1);
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries.take(5));
  }

  int _inventoryValue(List<Book> books) {
    return books.fold(0, (sum, book) => sum + (book.price * book.stock));
  }

  int _lowStockCount(List<Book> books, int lowStockLimit) {
    return books
        .where((book) => book.stock <= lowStockLimit && book.stock > 0)
        .length;
  }

  int _outOfStockCount(List<Book> books) {
    return books.where((book) => book.stock == 0).length;
  }

  List<D3ChartDatum> _orderStatusData(List<AppOrder> orders) {
    int count(OrderStatus status) {
      return orders.where((order) => order.status == status).length;
    }

    return [
      D3ChartDatum(
        label: 'Pendientes',
        value: count(OrderStatus.pending),
        color: _hex(AppColors.amber),
        detail: 'Pedidos recibidos que todavia necesitan preparacion.',
      ),
      D3ChartDatum(
        label: 'Preparando',
        value: count(OrderStatus.preparing),
        color: _hex(AppColors.sky),
        detail: 'Pedidos en proceso interno antes de quedar listos.',
      ),
      D3ChartDatum(
        label: 'Listos',
        value: count(OrderStatus.ready),
        color: _hex(AppColors.violet),
        detail: 'Pedidos preparados que esperan despacho.',
      ),
      D3ChartDatum(
        label: 'Despachados',
        value: count(OrderStatus.dispatched),
        color: _hex(AppColors.leaf),
        detail: 'Pedidos completados y enviados al cliente.',
      ),
    ];
  }

  List<D3ChartDatum> _orderValueByStatus(List<AppOrder> orders) {
    int total(OrderStatus status) {
      return orders
          .where((order) => order.status == status)
          .fold(0, (sum, order) => sum + order.total);
    }

    return [
      D3ChartDatum(
        label: 'Pendiente',
        value: total(OrderStatus.pending),
        color: _hex(AppColors.amber),
        detail: 'Valor que aun no ha iniciado preparacion.',
      ),
      D3ChartDatum(
        label: 'Preparando',
        value: total(OrderStatus.preparing),
        color: _hex(AppColors.sky),
        detail: 'Valor que esta en proceso operativo.',
      ),
      D3ChartDatum(
        label: 'Listo',
        value: total(OrderStatus.ready),
        color: _hex(AppColors.violet),
        detail: 'Valor listo para convertirse en despacho.',
      ),
      D3ChartDatum(
        label: 'Despachado',
        value: total(OrderStatus.dispatched),
        color: _hex(AppColors.leaf),
        detail: 'Valor ya entregado dentro del flujo.',
      ),
    ];
  }

  List<D3ChartDatum> _inventoryValueByCategory(List<Book> books) {
    final values = <String, int>{};
    for (final book in books) {
      values.update(
        book.genre,
        (value) => value + (book.price * book.stock),
        ifAbsent: () => book.price * book.stock,
      );
    }

    return _sortedData(values, AppColors.violet);
  }

  List<D3ChartDatum> _stockByCategory(List<Book> books) {
    final values = <String, int>{};
    for (final book in books) {
      values.update(
        book.genre,
        (value) => value + book.stock,
        ifAbsent: () => book.stock,
      );
    }

    return _sortedData(values, AppColors.teal);
  }

  List<D3ChartDatum> _topStockBooks(List<Book> books) {
    final sorted = List<Book>.of(books)
      ..sort((a, b) => b.stock.compareTo(a.stock));

    return [
      for (final book in sorted.take(5))
        D3ChartDatum(
          label: book.title,
          value: book.stock,
          color: _hex(AppColors.coral),
          detail: 'Este titulo tiene una de las mayores existencias fisicas.',
        ),
    ];
  }

  List<D3ChartDatum> _criticalStockBooks(List<Book> books, int lowStockLimit) {
    final sorted = books.where((book) => book.stock <= lowStockLimit).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    return [
      for (final book in sorted.take(6))
        D3ChartDatum(
          label: book.title,
          value: book.stock,
          color:
              book.stock == 0 ? _hex(AppColors.coral) : _hex(AppColors.amber),
          detail: book.stock == 0
              ? 'Titulo agotado: requiere reposicion urgente.'
              : 'Titulo por debajo del limite de stock definido.',
        ),
    ];
  }

  List<D3ChartDatum> _priceStockBubbles(List<Book> books) {
    return [
      for (final book in books.take(8))
        D3ChartDatum(
          label: book.title,
          value: book.price,
          secondaryValue: book.stock,
          size: book.price * book.stock,
          color: book.stock == 0
              ? _hex(AppColors.coral)
              : book.stock <= 5
                  ? _hex(AppColors.amber)
                  : _hex(AppColors.teal),
          detail:
              'Precio ${book.price}, stock ${book.stock}, valor ${book.price * book.stock}.',
        ),
    ];
  }

  List<D3ChartDatum> _sortedData(Map<String, int> values, Color color) {
    final entries = values.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return [
      for (final entry in entries.take(6))
        D3ChartDatum(
          label: entry.key,
          value: entry.value,
          color: _hex(color),
          detail: 'Aporta ${entry.value} al total de esta metrica.',
        ),
    ];
  }

  String _compactMoney(int value, String currency) {
    if (value >= 1000000) {
      return '$currency${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '$currency${(value / 1000).toStringAsFixed(0)}K';
    }

    return '$currency$value';
  }

  String _hex(Color color) {
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}

class _MetricInfo {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricInfo({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricInfo> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 480
                ? 2
                : 1;

        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 1 ? 3.6 : 2.25,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return _MetricCard(metric: metric)
                .animate(delay: (45 * index).ms)
                .fadeIn()
                .slideY(begin: 0.08);
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricInfo metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.crisp(metric.color),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: metric.color.withValues(alpha: 0.16)),
            ),
            child: Icon(metric.icon, color: metric.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: metric.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartDashboardGrid extends StatelessWidget {
  final List<Widget> charts;

  const _ChartDashboardGrid({required this.charts});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 2 : 1;

        if (columns == 1) {
          return Column(
            children: [
              for (var i = 0; i < charts.length; i++) ...[
                charts[i]
                    .animate(delay: (70 * i).ms)
                    .fadeIn()
                    .slideY(begin: 0.06),
                if (i != charts.length - 1) const SizedBox(height: 16),
              ],
            ],
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: charts.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            return charts[index]
                .animate(delay: (60 * index).ms)
                .fadeIn()
                .slideY(begin: 0.06);
          },
        );
      },
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final int total;

  const _StatsHeader({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft(AppColors.teal),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.query_stats, color: AppColors.violet),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estadisticas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                Text(
                  '$total libros analizados',
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
    ).animate().fadeIn().slideY(begin: 0.08);
  }
}

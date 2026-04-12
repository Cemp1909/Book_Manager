import 'package:flutter/material.dart';

import '../models/app_order.dart';
import '../services/temporary_data_service.dart';
import '../theme/app_theme.dart';
import '../widgets/quick_action.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback onNewOrder;
  final VoidCallback onOpenDispatches;
  final VoidCallback onScan;

  const DashboardScreen({
    super.key,
    required this.onNewOrder,
    required this.onOpenDispatches,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = TemporaryDataService.instance;

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final orders = dataService.orders;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryGrid(context, dataService),
              const SizedBox(height: 18),
              _buildAlerts(dataService),
              const SizedBox(height: 24),
              const Text(
                'Acciones rapidas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 24),
              const Text(
                'Movimiento de pedidos',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              _MiniBars(orders: orders),
              const SizedBox(height: 24),
              const Text(
                'Pedidos recientes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              for (final order in orders.take(3)) ...[
                _RecentOrderTile(order: order),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryGrid(
    BuildContext context,
    TemporaryDataService dataService,
  ) {
    final cards = [
      SummaryCard(
        title: 'Pedidos hoy',
        value: dataService.todayOrders.toString(),
        icon: Icons.shopping_cart,
        color: AppColors.teal,
        onTap: onNewOrder,
      ),
      SummaryCard(
        title: 'Despachos',
        value: dataService.dispatchedOrders.toString(),
        icon: Icons.local_shipping,
        color: AppColors.leaf,
        onTap: onOpenDispatches,
      ),
      SummaryCard(
        title: 'Activos',
        value: dataService.pendingOrders.toString(),
        icon: Icons.warning,
        color: AppColors.amber,
        onTap: onNewOrder,
      ),
      SummaryCard(
        title: 'Ingresos',
        value: _compactMoney(
            dataService.income, dataService.settings.currencySymbol),
        icon: Icons.attach_money,
        color: AppColors.coral,
        onTap: onNewOrder,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 700 ? 4 : 2;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth < 380 ? 1.05 : 1.35,
          children: cards,
        );
      },
    );
  }

  Widget _buildAlerts(TemporaryDataService dataService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_active,
                  color: AppColors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${dataService.pendingOrders} pedidos pendientes por mover. '
                'Stock bajo empieza en ${dataService.settings.lowStockLimit}.',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      QuickAction(
        title: 'Nuevo pedido',
        icon: Icons.add_shopping_cart,
        onTap: onNewOrder,
      ),
      QuickAction(
        title: 'Escanear QR',
        icon: Icons.qr_code_scanner,
        onTap: onScan,
      ),
      QuickAction(
        title: 'Despachos',
        icon: Icons.local_shipping_outlined,
        onTap: onOpenDispatches,
      ),
      QuickAction(
        title: 'Reporte rapido',
        icon: Icons.picture_as_pdf,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Reporte temporal listo para conectar')),
          );
        },
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 420
            ? (constraints.maxWidth - 12) / 2
            : 180.0;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actions
              .map(
                (action) => SizedBox(width: itemWidth, child: action),
              )
              .toList(),
        );
      },
    );
  }

  String _compactMoney(int value, String currency) {
    if (value >= 1000000) {
      return '$currency${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '$currency${(value / 1000).toStringAsFixed(1)}K';
    }
    return '$currency$value';
  }
}

class _MiniBars extends StatelessWidget {
  final List<AppOrder> orders;

  const _MiniBars({required this.orders});

  @override
  Widget build(BuildContext context) {
    final values = [
      orders.where((order) => order.status == OrderStatus.pending).length,
      orders.where((order) => order.status == OrderStatus.preparing).length,
      orders.where((order) => order.status == OrderStatus.ready).length,
      orders.where((order) => order.status == OrderStatus.dispatched).length,
    ];
    final labels = ['Pend.', 'Prep.', 'Listo', 'Desp.'];
    final maxValue = values.fold(1, (max, value) => value > max ? value : max);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < values.length; index++) ...[
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 36 + (values[index] / maxValue) * 72,
                      decoration: BoxDecoration(
                        color: [
                          AppColors.amber,
                          AppColors.teal,
                          AppColors.leaf,
                          AppColors.coral,
                        ][index]
                            .withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (index < values.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final AppOrder order;

  const _RecentOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.pending => AppColors.amber,
      OrderStatus.preparing => AppColors.teal,
      OrderStatus.ready => AppColors.leaf,
      OrderStatus.dispatched => AppColors.muted,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shopping_cart, color: AppColors.teal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.customer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                order.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

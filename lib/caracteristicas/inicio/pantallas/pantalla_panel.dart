import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/caracteristicas/pedidos/componentes/hoja_detalle_pedido.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/componentes/accion_rapida.dart';
import 'package:book_manager/compartido/componentes/tarjeta_resumen.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';

class DashboardScreen extends StatelessWidget {
  final VoidCallback? onNewOrder;
  final VoidCallback? onOpenDispatches;
  final VoidCallback? onScan;
  final bool canEditOrders;
  final bool canAdvanceOrders;
  final void Function(AppOrder order)? onEditOrder;
  final void Function(AppOrder order)? onAdvanceOrder;

  const DashboardScreen({
    super.key,
    this.onNewOrder,
    this.onOpenDispatches,
    this.onScan,
    this.canEditOrders = false,
    this.canAdvanceOrders = false,
    this.onEditOrder,
    this.onAdvanceOrder,
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
                _RecentOrderTile(
                  order: order,
                  canEdit: canEditOrders,
                  canAdvance: canAdvanceOrders,
                  onTap: () => showOrderDetailSheet(
                    context: context,
                    order: order,
                    currency: dataService.settings.currencySymbol,
                  ),
                  onEdit: order.status == OrderStatus.dispatched
                      ? null
                      : () => onEditOrder?.call(order),
                  onAdvance: order.status == OrderStatus.dispatched
                      ? null
                      : () => onAdvanceOrder?.call(order),
                ),
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
        onTap: onNewOrder == null
            ? null
            : () => _showPendingOrders(context, dataService),
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
        value: CurrencyFormatService.compactMoney(
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

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      if (onNewOrder != null)
        QuickAction(
          title: 'Nuevo pedido',
          icon: Icons.add_shopping_cart,
          onTap: onNewOrder,
        ),
      if (onScan != null)
        QuickAction(
          title: 'Escanear QR',
          icon: Icons.qr_code_scanner,
          onTap: onScan,
        ),
      if (onOpenDispatches != null)
        QuickAction(
          title: 'Despachos',
          icon: Icons.local_shipping_outlined,
          onTap: onOpenDispatches,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (actions.isEmpty) return const SizedBox.shrink();

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

  void _showPendingOrders(
    BuildContext context,
    TemporaryDataService dataService,
  ) {
    final rootContext = context;
    final pendingOrders = dataService.orders
        .where((order) => order.status != OrderStatus.dispatched)
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.66,
        minChildSize: 0.42,
        maxChildSize: 0.9,
        builder: (listContext, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Pedidos pendientes',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Selecciona un pedido para ver toda la informacion.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            if (pendingOrders.isEmpty)
              const Text(
                'No hay pedidos pendientes por ahora.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              for (final order in pendingOrders) ...[
                _PendingOrderRow(
                  order: order,
                  currency: dataService.settings.currencySymbol,
                  canEdit: canEditOrders,
                  canAdvance: canAdvanceOrders,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showOrderDetailSheet(
                      context: rootContext,
                      order: order,
                      currency: dataService.settings.currencySymbol,
                    );
                  },
                  onEdit: () {
                    Navigator.pop(sheetContext);
                    onEditOrder?.call(order);
                  },
                  onAdvance: () {
                    Navigator.pop(sheetContext);
                    onAdvanceOrder?.call(order);
                  },
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
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
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAdvance;
  final bool canEdit;
  final bool canAdvance;

  const _RecentOrderTile({
    required this.order,
    required this.onTap,
    this.onEdit,
    this.onAdvance,
    this.canEdit = false,
    this.canAdvance = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.pending => AppColors.amber,
      OrderStatus.preparing => AppColors.teal,
      OrderStatus.ready => AppColors.leaf,
      OrderStatus.dispatched => AppColors.muted,
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.teal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        const Icon(Icons.shopping_cart, color: AppColors.teal),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
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
              if (order.status != OrderStatus.dispatched &&
                  (canEdit || canAdvance)) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEdit && onEdit != null)
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    if (canEdit &&
                        onEdit != null &&
                        canAdvance &&
                        onAdvance != null)
                      const SizedBox(width: 10),
                    if (canAdvance && onAdvance != null)
                      OutlinedButton.icon(
                        onPressed: onAdvance,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Avanzar'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingOrderRow extends StatelessWidget {
  final AppOrder order;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAdvance;
  final bool canEdit;
  final bool canAdvance;

  const _PendingOrderRow({
    required this.order,
    required this.currency,
    required this.onTap,
    this.onEdit,
    this.onAdvance,
    this.canEdit = false,
    this.canAdvance = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (order.status) {
      OrderStatus.pending => AppColors.amber,
      OrderStatus.preparing => AppColors.teal,
      OrderStatus.ready => AppColors.leaf,
      OrderStatus.dispatched => AppColors.muted,
    };

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long, color: statusColor),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${order.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        Text(
                          order.customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                        Text(
                          '${order.status.label} - ${CurrencyFormatService.money(order.total, currency)}',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right, color: AppColors.muted),
                ),
              ],
            ),
            if (order.status != OrderStatus.dispatched &&
                (canEdit || canAdvance))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (canEdit && onEdit != null)
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    if (canEdit &&
                        onEdit != null &&
                        canAdvance &&
                        onAdvance != null)
                      const SizedBox(width: 10),
                    if (canAdvance && onAdvance != null)
                      OutlinedButton.icon(
                        onPressed: onAdvance,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Avanzar'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

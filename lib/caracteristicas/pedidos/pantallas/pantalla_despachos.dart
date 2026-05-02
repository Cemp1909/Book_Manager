import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/caracteristicas/pedidos/componentes/hoja_detalle_pedido.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';

class DispatchesScreen extends StatelessWidget {
  final bool canDispatchOrders;

  const DispatchesScreen({
    super.key,
    this.canDispatchOrders = true,
  });

  @override
  Widget build(BuildContext context) {
    final dataService = TemporaryDataService.instance;

    return AnimatedBuilder(
      animation: dataService,
      builder: (context, _) {
        final dispatches = dataService.orders
            .where(
              (order) =>
                  order.status == OrderStatus.ready ||
                  order.status == OrderStatus.dispatched,
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${dispatches.length} despachos en seguimiento',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (dispatches.isEmpty)
              const _EmptyDispatches()
            else
              for (final order in dispatches) ...[
                _DispatchCard(
                  order: order,
                  currency: dataService.settings.currencySymbol,
                  onTap: () => showOrderDetailSheet(
                    context: context,
                    order: order,
                    currency: dataService.settings.currencySymbol,
                  ),
                  onDispatch: canDispatchOrders
                      ? () {
                          dataService.updateOrderStatus(
                            order.id,
                            OrderStatus.dispatched,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Pedido #${order.id} despachado'),
                            ),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _DispatchCard extends StatelessWidget {
  final AppOrder order;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback? onDispatch;

  const _DispatchCard({
    required this.order,
    required this.currency,
    required this.onTap,
    this.onDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final dispatched = order.status == OrderStatus.dispatched;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.leaf.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  dispatched ? Icons.check_circle : Icons.local_shipping,
                  color: dispatched ? AppColors.leaf : AppColors.teal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pedido #${order.id}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.customer,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.deliveryAddress} - $currency${order.total}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: dispatched ? null : onDispatch,
                      icon: Icon(dispatched ? Icons.done : Icons.send_outlined),
                      label:
                          Text(dispatched ? 'Despachado' : 'Marcar despacho'),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyDispatches extends StatelessWidget {
  const _EmptyDispatches();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(
        child: Text(
          'Cuando un pedido este listo, aparecera aqui para despacharlo.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

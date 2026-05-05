import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';
import 'package:book_manager/compartido/servicios/servicio_mapas.dart';

Future<void> showOrderDetailSheet({
  required BuildContext context,
  required AppOrder order,
  required String currency,
}) {
  final history = ActivityLogService.instance.activitiesForEntity(
    entityType: 'pedido',
    entityId: order.id,
  );

  return showModalBottomSheet<void>(
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Pedido #${order.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(label: 'Cliente', value: order.customer),
          _InfoRow(label: 'Direccion', value: order.deliveryAddress),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () async {
                final opened = await MapService.openAddress(
                  address: order.deliveryAddress,
                  city: _cityNameForOrder(order),
                  label: order.customer,
                );
                if (!opened && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el mapa')),
                  );
                }
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Abrir mapa'),
            ),
          ),
          _InfoRow(label: 'Estado', value: order.status.label),
          _InfoRow(label: 'Unidades', value: order.itemCount.toString()),
          const Divider(height: 28),
          const Text(
            'Detalle del pedido',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final item in order.items)
            _OrderLine(item: item, currency: currency),
          const Divider(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                CurrencyFormatService.money(order.total, currency),
                style: const TextStyle(
                  color: AppColors.tealDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Historial del pedido',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(history.length.toString()),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Text(
              'Aun no hay actividad registrada para este pedido.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (final activity in history.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history_outlined),
                title: Text(activity.title),
                subtitle: Text(activity.detail),
              ),
        ],
      ),
    ),
  );
}

String? _cityNameForOrder(AppOrder order) {
  final dataService = TemporaryDataService.instance;
  for (final school in dataService.schools) {
    if (school.name.toLowerCase() == order.customer.toLowerCase()) {
      return dataService.cityById(school.cityId)?.name;
    }
  }
  return null;
}

class _OrderLine extends StatelessWidget {
  final OrderItem item;
  final String currency;

  const _OrderLine({required this.item, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (item.isCombo ? AppColors.violet : AppColors.teal)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              item.isCombo ? Icons.grid_view : Icons.menu_book_outlined,
              color: item.isCombo ? AppColors.violet : AppColors.teal,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${item.quantity} x ${CurrencyFormatService.money(item.unitPrice, currency)} - ${item.subtitle}',
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
          Text(
            CurrencyFormatService.money(item.total, currency),
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.pending => AppColors.amber,
      OrderStatus.preparing => AppColors.teal,
      OrderStatus.ready => AppColors.leaf,
      OrderStatus.dispatched => AppColors.muted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/bodega_inventario.dart';
import 'package:book_manager/datos/modelos/devolucion_app.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/servicio_base_datos.dart';
import 'package:book_manager/caracteristicas/pedidos/componentes/hoja_detalle_pedido.dart';
import 'package:book_manager/caracteristicas/pedidos/servicios/servicio_remision_pdf.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_formato_moneda.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';
import 'package:book_manager/compartido/servicios/servicio_mapas.dart';

class DispatchesScreen extends StatelessWidget {
  final bool canDispatchOrders;
  final AppUser? currentUser;

  const DispatchesScreen({
    super.key,
    this.canDispatchOrders = true,
    this.currentUser,
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
                        '${dispatches.length} despachos en seguimiento'
                        ' - ${dataService.returnCount} devoluciones',
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
                  onShareGuide: () => _shareDispatchGuide(context, order),
                  onReturn: order.status == OrderStatus.dispatched
                      ? () => _openReturnSheet(context, order)
                      : null,
                ),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }

  Future<void> _shareDispatchGuide(
    BuildContext context,
    AppOrder order,
  ) async {
    try {
      await DispatchPdfService.instance.shareDispatchGuide(
        order: order,
        settings: TemporaryDataService.instance.settings,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la remision: $error')),
      );
    }
  }

  Future<void> _openReturnSheet(BuildContext context, AppOrder order) async {
    final reasonController = TextEditingController();
    var selectedItem = order.items.first;
    var quantity = 1;
    var restock = false;

    final record = await showModalBottomSheet<ReturnRecord>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar devolucion #${order.id}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<OrderItem>(
                  initialValue: selectedItem,
                  decoration: const InputDecoration(
                    labelText: 'Producto devuelto',
                    prefixIcon: Icon(Icons.assignment_return_outlined),
                  ),
                  items: order.items
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (item) {
                    if (item == null) return;
                    setSheetState(() {
                      selectedItem = item;
                      quantity = 1;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton.outlined(
                      onPressed: quantity == 1
                          ? null
                          : () => setSheetState(() => quantity--),
                      icon: const Icon(Icons.remove),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$quantity de ${selectedItem.quantity} unidades',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    IconButton.filled(
                      onPressed: quantity >= selectedItem.quantity
                          ? null
                          : () => setSheetState(() => quantity++),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: restock,
                  title: const Text('Marcar como reintegrable'),
                  subtitle: const Text(
                    'Deja constancia para ajustar stock si corresponde.',
                  ),
                  onChanged: (value) => setSheetState(() => restock = value),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;

                    Navigator.pop(
                      context,
                      ReturnRecord(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        orderId: order.id,
                        customer: order.customer,
                        itemTitle: selectedItem.title,
                        quantity: quantity,
                        reason: reason,
                        restock: restock,
                        date: DateTime.now(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.assignment_return_outlined),
                  label: const Text('Guardar devolucion'),
                ),
              ],
            ),
          );
        },
      ),
    );

    reasonController.dispose();
    if (record == null) return;
    if (!context.mounted) return;

    TemporaryDataService.instance.addReturn(record);
    if (record.restock) {
      await _restockReturnedItem(
        context: context,
        item: selectedItem,
        quantity: record.quantity,
        reason: record.reason,
      );
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          record.restock
              ? 'Devolucion registrada y stock reintegrado'
              : 'Devolucion registrada: ${record.quantity} x ${record.itemTitle}',
        ),
      ),
    );
  }

  Future<void> _restockReturnedItem({
    required BuildContext context,
    required OrderItem item,
    required int quantity,
    required String reason,
  }) async {
    try {
      final books = await DatabaseService.instance.getBooks();
      final returnedBooks = item.isCombo
          ? _booksForCombo(item.title, books)
          : _booksForItem(item, books);

      if (returnedBooks.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Devolucion guardada, pero no se encontro stock para ${item.title}'),
          ),
        );
        return;
      }

      final movementDetails = <InventoryMovementDetail>[];
      for (final book in returnedBooks) {
        if (book.id == null) continue;
        final updatedBook = book.copyWith(stock: book.stock + quantity);
        await DatabaseService.instance.updateBook(updatedBook);
        movementDetails.add(
          InventoryMovementDetail(
            bookIsbn: book.isbn,
            bookTitle: book.title,
            quantity: quantity,
          ),
        );
      }

      if (movementDetails.isEmpty) return;

      final dataService = TemporaryDataService.instance;
      final warehouse = dataService.warehouses.first;
      dataService.addInventoryMovement(
        InventoryMovementRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          movementType: 'entrada',
          warehouse: warehouse,
          user: currentUser,
          total:
              movementDetails.fold(0, (sum, detail) => sum + detail.quantity),
          observation: 'Devolucion reintegrada: $reason',
          details: movementDetails,
        ),
      );
      await ActivityLogService.instance.record(
        type: ActivityType.inventory,
        title: 'Devolucion reintegrada',
        detail:
            '${item.title}: ${movementDetails.length} referencia(s), $quantity unidad(es).',
        actor: currentUser,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Devolucion guardada, pero no se reintegro stock: $error')),
      );
    }
  }

  List<Book> _booksForItem(OrderItem item, List<Book> books) {
    return books
        .where(
          (book) =>
              book.title.toLowerCase() == item.title.toLowerCase() &&
              book.author.toLowerCase() == item.subtitle.toLowerCase(),
        )
        .toList();
  }

  List<Book> _booksForCombo(String comboName, List<Book> books) {
    final combos = TemporaryDataService.instance.buildCombos(books);
    for (final combo in combos) {
      if (combo.name.toLowerCase() == comboName.toLowerCase()) {
        return combo.books;
      }
    }
    return const [];
  }
}

class _DispatchCard extends StatelessWidget {
  final AppOrder order;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback? onDispatch;
  final VoidCallback onShareGuide;
  final VoidCallback? onReturn;

  const _DispatchCard({
    required this.order,
    required this.currency,
    required this.onTap,
    required this.onShareGuide,
    this.onDispatch,
    this.onReturn,
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
                      '${order.deliveryAddress} - ${CurrencyFormatService.money(order.total, currency)}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: dispatched ? null : onDispatch,
                          icon: Icon(
                            dispatched ? Icons.done : Icons.send_outlined,
                          ),
                          label: Text(
                            dispatched ? 'Despachado' : 'Marcar despacho',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShareGuide,
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('Remision'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final opened = await MapService.openAddress(
                              address: order.deliveryAddress,
                              city: _cityNameForOrder(order),
                              label: order.customer,
                            );
                            if (!opened && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No se pudo abrir el mapa'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Mapa'),
                        ),
                        if (onReturn != null)
                          OutlinedButton.icon(
                            onPressed: onReturn,
                            icon: const Icon(
                              Icons.assignment_return_outlined,
                            ),
                            label: const Text('Devolucion'),
                          ),
                      ],
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

String? _cityNameForOrder(AppOrder order) {
  final dataService = TemporaryDataService.instance;
  for (final school in dataService.schools) {
    if (school.name.toLowerCase() == order.customer.toLowerCase()) {
      return dataService.cityById(school.cityId)?.name;
    }
  }
  return null;
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

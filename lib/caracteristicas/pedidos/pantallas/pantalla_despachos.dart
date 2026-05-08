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
            if (dataService.returns.isNotEmpty) ...[
              _ReturnsPanel(returns: dataService.returns),
              const SizedBox(height: 16),
            ],
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
                          _dispatchOrder(context, order);
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
      await TemporaryDataService.instance.markRemissionGenerated(order.id);
      await ActivityLogService.instance.record(
        type: ActivityType.orders,
        title: 'Remision generada',
        detail: 'Se genero la remision del pedido #${order.id}.',
        actor: currentUser,
        entityType: 'pedido',
        entityId: order.id,
        entityName: 'Pedido #${order.id}',
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo generar la remision: $error')),
      );
    }
  }

  Future<void> _dispatchOrder(BuildContext context, AppOrder order) async {
    final validationErrors = await _validateBeforeDispatch(order);
    if (validationErrors.isNotEmpty) {
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No se puede despachar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Revisa estas condiciones antes de continuar:'),
              const SizedBox(height: 10),
              for (final error in validationErrors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 18, color: AppColors.coral),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error)),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    if (!context.mounted) return;
    final dispatchDetails = await _discountStockForOrder(context, order);
    if (dispatchDetails == null) return;

    try {
      final dataService = TemporaryDataService.instance;
      final warehouse = dataService.warehouses.isNotEmpty
          ? dataService.warehouses.first
          : const AppWarehouse(
              id: 'principal',
              name: 'Bodega principal',
              location: 'Sin ubicacion',
            );
      await TemporaryDataService.instance.persistDispatch(
        order: order,
        user: currentUser,
        details: dispatchDetails,
        movement: InventoryMovementRecord(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          movementType: 'salida',
          warehouse: warehouse,
          user: currentUser,
          total:
              dispatchDetails.fold(0, (sum, detail) => sum + detail.quantity),
          observation: 'Despacho del pedido #${order.id}',
          details: dispatchDetails,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el despacho: $error')),
      );
      return;
    }

    await TemporaryDataService.instance.updateOrderStatus(
      order.id,
      OrderStatus.dispatched,
    );
    await ActivityLogService.instance.record(
      type: ActivityType.orders,
      title: 'Pedido despachado',
      detail: 'Pedido #${order.id} fue marcado como despachado.',
      actor: currentUser,
      entityType: 'pedido',
      entityId: order.id,
      entityName: 'Pedido #${order.id}',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido #${order.id} despachado')),
    );
  }

  Future<List<InventoryMovementDetail>?> _discountStockForOrder(
    BuildContext context,
    AppOrder order,
  ) async {
    try {
      final books = await DatabaseService.instance.getBooks();
      final requiredByIsbn = <String, int>{};
      final booksByIsbn = {for (final book in books) book.isbn: book};

      for (final item in order.items) {
        final itemBooks = item.isCombo
            ? _booksForCombo(item.title, books)
            : _booksForItem(item, books);

        for (final book in itemBooks) {
          requiredByIsbn[book.isbn] =
              (requiredByIsbn[book.isbn] ?? 0) + item.quantity;
        }
      }

      if (requiredByIsbn.isEmpty) {
        if (!context.mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontro inventario para descontar.'),
          ),
        );
        return null;
      }

      final movementDetails = <InventoryMovementDetail>[];
      for (final entry in requiredByIsbn.entries) {
        final book = booksByIsbn[entry.key];
        if (book == null || book.id == null) continue;

        movementDetails.add(
          InventoryMovementDetail(
            bookIsbn: book.isbn,
            bookTitle: book.title,
            quantity: entry.value,
          ),
        );
      }

      if (movementDetails.isEmpty) return null;
      await ActivityLogService.instance.record(
        type: ActivityType.inventory,
        title: 'Stock descontado por despacho',
        detail:
            'Pedido #${order.id}: ${movementDetails.length} referencia(s), ${movementDetails.fold(0, (sum, detail) => sum + detail.quantity)} unidad(es).',
        actor: currentUser,
        entityType: 'pedido',
        entityId: order.id,
        entityName: 'Pedido #${order.id}',
      );
      return movementDetails;
    } catch (error) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo descontar stock: $error')),
      );
      return null;
    }
  }

  Future<List<String>> _validateBeforeDispatch(AppOrder order) async {
    final errors = <String>[];
    final dataService = TemporaryDataService.instance;

    if (order.items.isEmpty) {
      errors.add('El pedido no tiene productos.');
    }

    final hasSchool = dataService.schools.any(
      (school) => school.name.toLowerCase() == order.customer.toLowerCase(),
    );
    if (!hasSchool || order.deliveryAddress.trim().isEmpty) {
      errors.add('El pedido debe tener colegio y direccion de entrega.');
    }

    if (!dataService.hasGeneratedRemission(order.id)) {
      errors.add('Primero genera la remision del pedido.');
    }

    final stockErrors = await _stockErrorsForOrder(order);
    errors.addAll(stockErrors);
    return errors;
  }

  Future<List<String>> _stockErrorsForOrder(AppOrder order) async {
    final books = await DatabaseService.instance.getBooks();
    final requiredByIsbn = <String, int>{};
    final titlesByIsbn = <String, String>{};

    for (final item in order.items) {
      final itemBooks = item.isCombo
          ? _booksForCombo(item.title, books)
          : _booksForItem(item, books);
      if (itemBooks.isEmpty) {
        return ['No se encontro inventario para ${item.title}.'];
      }
      for (final book in itemBooks) {
        requiredByIsbn[book.isbn] =
            (requiredByIsbn[book.isbn] ?? 0) + item.quantity;
        titlesByIsbn[book.isbn] = book.title;
      }
    }

    final booksByIsbn = {for (final book in books) book.isbn: book};
    return requiredByIsbn.entries
        .where((entry) => (booksByIsbn[entry.key]?.stock ?? 0) < entry.value)
        .map((entry) {
      final available = booksByIsbn[entry.key]?.stock ?? 0;
      return '${titlesByIsbn[entry.key] ?? entry.key}: requiere ${entry.value}, disponible $available.';
    }).toList();
  }

  Future<void> _openReturnSheet(BuildContext context, AppOrder order) async {
    final reasonController = TextEditingController();
    var selectedItem = order.items.first;
    var quantity = 1;
    var restock = false;
    var returnStatus = ReturnStatus.registered;

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
                  onChanged: (value) => setSheetState(() {
                    restock = value;
                    returnStatus = value
                        ? ReturnStatus.restocked
                        : ReturnStatus.registered;
                  }),
                ),
                if (!restock) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<ReturnStatus>(
                    initialValue: returnStatus,
                    decoration: const InputDecoration(
                      labelText: 'Estado de devolucion',
                      prefixIcon: Icon(Icons.traffic_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: ReturnStatus.registered,
                        child: Text('Registrada'),
                      ),
                      DropdownMenuItem(
                        value: ReturnStatus.notRestockable,
                        child: Text('No reintegrable'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setSheetState(() => returnStatus = value);
                    },
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;

                    if (restock) {
                      final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Confirmar reintegro'),
                              content: const Text(
                                'Esto aumentará el stock y creará un movimiento de entrada.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Reintegrar'),
                                ),
                              ],
                            ),
                          ) ??
                          false;
                      if (!context.mounted || !confirmed) return;
                    }

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
                        status: restock ? ReturnStatus.restocked : returnStatus,
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

    var savedRecord = record;
    if (record.restock) {
      final restocked = await _restockReturnedItem(
        context: context,
        item: selectedItem,
        quantity: record.quantity,
        reason: record.reason,
      );
      savedRecord = record.copyWith(
        restock: restocked,
        status: restocked ? ReturnStatus.restocked : ReturnStatus.registered,
      );
    }
    try {
      await TemporaryDataService.instance.addReturn(
        savedRecord,
        user: currentUser,
        item: selectedItem,
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la devolucion: $error')),
      );
      return;
    }
    await ActivityLogService.instance.record(
      type: ActivityType.orders,
      title: 'Devolucion registrada',
      detail:
          '${savedRecord.quantity} x ${savedRecord.itemTitle}: ${savedRecord.status.label}.',
      actor: currentUser,
      entityType: 'pedido',
      entityId: savedRecord.orderId,
      entityName: 'Pedido #${savedRecord.orderId}',
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedRecord.status == ReturnStatus.restocked
              ? 'Devolucion registrada y stock reintegrado'
              : 'Devolucion registrada: ${savedRecord.quantity} x ${savedRecord.itemTitle}',
        ),
      ),
    );
  }

  Future<bool> _restockReturnedItem({
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
        if (!context.mounted) return false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Devolucion guardada, pero no se encontro stock para ${item.title}'),
          ),
        );
        return false;
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

      if (movementDetails.isEmpty) return false;

      final dataService = TemporaryDataService.instance;
      final warehouse = dataService.warehouses.first;
      await dataService.addInventoryMovement(
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
      return true;
    } catch (error) {
      if (!context.mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Devolucion guardada, pero no se reintegro stock: $error')),
      );
      return false;
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

class _ReturnsPanel extends StatelessWidget {
  final List<ReturnRecord> returns;

  const _ReturnsPanel({required this.returns});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface.withValues(alpha: 0.96),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Devoluciones recientes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(returns.length.toString()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final record in returns.take(4)) _ReturnTile(record: record),
          ],
        ),
      ),
    );
  }
}

class _ReturnTile extends StatelessWidget {
  final ReturnRecord record;

  const _ReturnTile({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = _returnStatusColor(record.status);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      title: Text(
        record.itemTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        '${record.customer} - ${record.quantity} unidad(es)',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Chip(
        visualDensity: VisualDensity.compact,
        backgroundColor: color.withValues(alpha: 0.12),
        label: Text(record.status.label),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

Color _returnStatusColor(ReturnStatus status) {
  return switch (status) {
    ReturnStatus.registered => AppColors.amber,
    ReturnStatus.restocked => AppColors.leaf,
    ReturnStatus.notRestockable => AppColors.coral,
  };
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

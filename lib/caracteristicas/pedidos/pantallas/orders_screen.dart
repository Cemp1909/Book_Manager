import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/app_theme.dart';
import 'package:book_manager/caracteristicas/combos/modelos/book_combo.dart';
import 'package:book_manager/caracteristicas/inventario/modelos/book.dart';
import 'package:book_manager/caracteristicas/inventario/servicios/database_service.dart';
import 'package:book_manager/caracteristicas/pedidos/modelos/app_order.dart';
import 'package:book_manager/caracteristicas/pedidos/widgets/order_detail_sheet.dart';
import 'package:book_manager/compartido/servicios/temporary_data_service.dart';

class OrdersScreen extends StatefulWidget {
  final bool canCreateOrders;
  final bool canEditOrders;
  final bool canAdvanceOrders;

  const OrdersScreen({
    super.key,
    this.canCreateOrders = true,
    this.canEditOrders = false,
    this.canAdvanceOrders = true,
  });

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _dataService = TemporaryDataService.instance;
  final _databaseService = DatabaseService.instance;

  List<Book> _books = [];
  bool _isLoadingBooks = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dataService,
      builder: (context, _) {
        final orders = _dataService.orders;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(orders),
            const SizedBox(height: 16),
            if (widget.canCreateOrders) ...[
              FilledButton.icon(
                onPressed: _isLoadingBooks ? null : () => _openOrderSheet(),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Nuevo pedido'),
              ),
              const SizedBox(height: 16),
            ],
            for (final order in orders) ...[
              _OrderCard(
                order: order,
                currency: _dataService.settings.currencySymbol,
                onTap: () => showOrderDetailSheet(
                  context: context,
                  order: order,
                  currency: _dataService.settings.currencySymbol,
                ),
                onEdit: widget.canEditOrders &&
                        order.status != OrderStatus.dispatched
                    ? () => _openOrderSheet(initialOrder: order)
                    : null,
                onAdvance: widget.canAdvanceOrders
                    ? () => _advanceOrder(order)
                    : null,
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHeader(List<AppOrder> orders) {
    final pending =
        orders.where((order) => order.status != OrderStatus.dispatched).length;
    final total = orders.fold(0, (sum, order) => sum + order.total);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _HeaderMetric(
                label: 'Pedidos activos',
                value: pending.toString(),
                color: AppColors.teal,
              ),
            ),
            Expanded(
              child: _HeaderMetric(
                label: 'Total temporal',
                value: _money(total),
                color: AppColors.leaf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadBooks() async {
    try {
      final books = await _databaseService.getBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _isLoadingBooks = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoadingBooks = false;
      });
      _message('No se pudieron cargar libros: $error');
    }
  }

  Future<void> _openOrderSheet({AppOrder? initialOrder}) async {
    if (_books.isEmpty) {
      _message('Agrega libros al inventario antes de crear pedidos');
      return;
    }

    final customerController = TextEditingController(
      text: initialOrder?.customer ?? '',
    );
    final addressController = TextEditingController(
      text: initialOrder?.deliveryAddress == 'Pendiente por confirmar'
          ? ''
          : initialOrder?.deliveryAddress ?? '',
    );
    final combos = _dataService.buildCombos(_books);
    final products = [
      for (final book in _books) _OrderProduct.book(book),
      for (final combo in combos) _OrderProduct.combo(combo),
    ];
    final draftItems = initialOrder == null
        ? <OrderItem>[]
        : initialOrder.items
            .map(
              (item) => OrderItem(
                title: item.title,
                subtitle: item.subtitle,
                unitPrice: item.unitPrice,
                quantity: item.quantity,
                isCombo: item.isCombo,
              ),
            )
            .toList();
    var selectedProduct = products.first;
    int quantity = 1;

    final savedOrder = await showModalBottomSheet<AppOrder>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final draftTotal = draftItems.fold<int>(
              0,
              (sum, item) => sum + item.total,
            );
            final lineTotal = selectedProduct.unitPrice * quantity;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.86,
              minChildSize: 0.55,
              maxChildSize: 0.94,
              builder: (context, scrollController) => ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                children: [
                  Text(
                    initialOrder == null ? 'Nuevo pedido' : 'Editar pedido',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: customerController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente o colegio',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Direccion de entrega',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<_OrderProduct>(
                    initialValue: selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Libro o combo',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    items: products
                        .map(
                          (product) => DropdownMenuItem(
                            value: product,
                            child: Text(
                              product.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (product) {
                      if (product == null) return;
                      setSheetState(() => selectedProduct = product);
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
                            '$quantity unidades',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      IconButton.filled(
                        onPressed: () => setSheetState(() => quantity++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Linea: ${_money(lineTotal)}',
                          style: const TextStyle(
                            color: AppColors.tealDark,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setSheetState(() {
                            draftItems.add(
                              OrderItem(
                                title: selectedProduct.title,
                                subtitle: selectedProduct.subtitle,
                                unitPrice: selectedProduct.unitPrice,
                                quantity: quantity,
                                isCombo: selectedProduct.isCombo,
                              ),
                            );
                            quantity = 1;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Carrito',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (draftItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text(
                        'Agrega uno o varios libros, combos, o mezcla ambos.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    for (var index = 0; index < draftItems.length; index++)
                      _DraftOrderItem(
                        item: draftItems[index],
                        money: _money,
                        onRemove: () {
                          setSheetState(() {
                            draftItems.removeAt(index);
                          });
                        },
                      ),
                  const SizedBox(height: 12),
                  Text(
                    'Total pedido: ${_money(draftTotal)}',
                    style: const TextStyle(
                      color: AppColors.tealDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: () {
                      final customer = customerController.text.trim();
                      if (customer.isEmpty || draftItems.isEmpty) return;

                      Navigator.pop(
                        context,
                        AppOrder(
                          id: initialOrder?.id ??
                              DateTime.now().millisecondsSinceEpoch.toString(),
                          customer: customer,
                          date: initialOrder?.date ?? DateTime.now(),
                          status: initialOrder?.status ?? OrderStatus.pending,
                          deliveryAddress: addressController.text.trim().isEmpty
                              ? 'Pendiente por confirmar'
                              : addressController.text.trim(),
                          items: List.unmodifiable(draftItems),
                        ),
                      );
                    },
                    child: Text(
                      initialOrder == null
                          ? 'Guardar pedido completo'
                          : 'Guardar cambios',
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    customerController.dispose();
    addressController.dispose();

    if (savedOrder == null) return;

    if (initialOrder == null) {
      _dataService.addOrder(savedOrder);
      _message('Pedido creado para ${savedOrder.customer}');
      return;
    }

    _dataService.updateOrder(savedOrder);
    _message('Pedido actualizado para ${savedOrder.customer}');
  }

  void _advanceOrder(AppOrder order) {
    final nextStatus = switch (order.status) {
      OrderStatus.pending => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.dispatched,
      OrderStatus.dispatched => OrderStatus.dispatched,
    };

    if (nextStatus == order.status) return;
    _dataService.updateOrderStatus(order.id, nextStatus);
    _message('Pedido #${order.id}: ${nextStatus.label}');
  }

  String _money(int value) => '${_dataService.settings.currencySymbol}$value';

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _OrderCard extends StatelessWidget {
  final AppOrder order;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onAdvance;

  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onTap,
    this.onEdit,
    this.onAdvance,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pedido #${order.id}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _StatusBadge(label: order.status.label, color: statusColor),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.customer,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${order.itemCount} unidades - $currency${order.total}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              if (onEdit != null || onAdvance != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar'),
                      ),
                    if (onEdit != null && onAdvance != null)
                      const SizedBox(width: 10),
                    if (onAdvance != null)
                      OutlinedButton.icon(
                        onPressed: order.status == OrderStatus.dispatched
                            ? null
                            : onAdvance,
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          order.status == OrderStatus.dispatched
                              ? 'Completado'
                              : 'Avanzar',
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderProduct {
  final String title;
  final String subtitle;
  final int unitPrice;
  final bool isCombo;

  const _OrderProduct({
    required this.title,
    required this.subtitle,
    required this.unitPrice,
    required this.isCombo,
  });

  factory _OrderProduct.book(Book book) {
    return _OrderProduct(
      title: book.title,
      subtitle: book.author,
      unitPrice: book.price,
      isCombo: false,
    );
  }

  factory _OrderProduct.combo(BookCombo combo) {
    return _OrderProduct(
      title: combo.name,
      subtitle: '${combo.books.length} libros - ${combo.discountPercent}% off',
      unitPrice: combo.total,
      isCombo: true,
    );
  }

  String get label => isCombo ? 'Combo: $title' : 'Libro: $title';
}

class _DraftOrderItem extends StatelessWidget {
  final OrderItem item;
  final String Function(int value) money;
  final VoidCallback onRemove;

  const _DraftOrderItem({
    required this.item,
    required this.money,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            item.isCombo ? Icons.grid_view : Icons.menu_book_outlined,
            color: item.isCombo ? AppColors.violet : AppColors.teal,
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
                  '${item.quantity} x ${money(item.unitPrice)}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

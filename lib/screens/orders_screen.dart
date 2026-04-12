import 'package:flutter/material.dart';

import '../models/app_order.dart';
import '../models/book.dart';
import '../services/database_service.dart';
import '../services/temporary_data_service.dart';
import '../theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

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
            FilledButton.icon(
              onPressed: _isLoadingBooks ? null : _openNewOrderSheet,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Nuevo pedido'),
            ),
            const SizedBox(height: 16),
            for (final order in orders) ...[
              _OrderCard(
                order: order,
                currency: _dataService.settings.currencySymbol,
                onTap: () => _showOrderDetail(order),
                onAdvance: () => _advanceOrder(order),
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

  Future<void> _openNewOrderSheet() async {
    if (_books.isEmpty) {
      _message('Agrega libros al inventario antes de crear pedidos');
      return;
    }

    final customerController = TextEditingController();
    final addressController = TextEditingController();
    Book selectedBook = _books.first;
    int quantity = 1;

    final created = await showModalBottomSheet<AppOrder>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final total = selectedBook.price * quantity;

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
                  const Text(
                    'Nuevo pedido',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
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
                  DropdownButtonFormField<Book>(
                    initialValue: selectedBook,
                    decoration: const InputDecoration(
                      labelText: 'Libro',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    items: _books
                        .map(
                          (book) => DropdownMenuItem(
                            value: book,
                            child: Text(
                              book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (book) {
                      if (book == null) return;
                      setSheetState(() => selectedBook = book);
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
                  Text(
                    'Total: ${_money(total)}',
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
                      if (customer.isEmpty) return;

                      Navigator.pop(
                        context,
                        AppOrder(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          customer: customer,
                          date: DateTime.now(),
                          status: OrderStatus.pending,
                          deliveryAddress: addressController.text.trim().isEmpty
                              ? 'Pendiente por confirmar'
                              : addressController.text.trim(),
                          items: [
                            OrderItem(book: selectedBook, quantity: quantity),
                          ],
                        ),
                      );
                    },
                    child: const Text('Guardar pedido'),
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

    if (created == null) return;

    _dataService.addOrder(created);
    _message('Pedido creado para ${created.customer}');
  }

  void _showOrderDetail(AppOrder order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Pedido #${order.id}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(order.customer, style: const TextStyle(color: AppColors.muted)),
          Text(order.deliveryAddress),
          const Divider(height: 28),
          for (final item in order.items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.book.title),
              subtitle: Text('${item.quantity} x ${_money(item.book.price)}'),
              trailing: Text(
                _money(item.total),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          const Divider(height: 28),
          Text(
            'Total: ${_money(order.total)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
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
  final VoidCallback onAdvance;

  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onTap,
    required this.onAdvance,
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
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed:
                      order.status == OrderStatus.dispatched ? null : onAdvance,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    order.status == OrderStatus.dispatched
                        ? 'Completado'
                        : 'Avanzar',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

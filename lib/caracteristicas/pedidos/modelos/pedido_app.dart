enum OrderStatus {
  pending,
  preparing,
  ready,
  dispatched,
}

extension OrderStatusText on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pendiente';
      case OrderStatus.preparing:
        return 'Preparando';
      case OrderStatus.ready:
        return 'Listo';
      case OrderStatus.dispatched:
        return 'Despachado';
    }
  }
}

class OrderItem {
  final String title;
  final String subtitle;
  final int unitPrice;
  final int quantity;
  final bool isCombo;

  const OrderItem({
    required this.title,
    required this.subtitle,
    required this.unitPrice,
    required this.quantity,
    this.isCombo = false,
  });

  int get total => unitPrice * quantity;
}

class AppOrder {
  final String id;
  final String customer;
  final DateTime date;
  final OrderStatus status;
  final List<OrderItem> items;
  final String deliveryAddress;

  const AppOrder({
    required this.id,
    required this.customer,
    required this.date,
    required this.status,
    required this.items,
    required this.deliveryAddress,
  });

  int get total => items.fold(0, (sum, item) => sum + item.total);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  AppOrder copyWith({
    String? id,
    String? customer,
    DateTime? date,
    OrderStatus? status,
    List<OrderItem>? items,
    String? deliveryAddress,
  }) {
    return AppOrder(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      date: date ?? this.date,
      status: status ?? this.status,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}

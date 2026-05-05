enum ReturnStatus {
  registered('Registrada'),
  restocked('Reintegrada'),
  notRestockable('No reintegrable');

  final String label;

  const ReturnStatus(this.label);
}

class ReturnRecord {
  final String id;
  final String orderId;
  final String customer;
  final String itemTitle;
  final int quantity;
  final String reason;
  final bool restock;
  final DateTime date;
  final ReturnStatus status;

  const ReturnRecord({
    required this.id,
    required this.orderId,
    required this.customer,
    required this.itemTitle,
    required this.quantity,
    required this.reason,
    required this.restock,
    required this.date,
    this.status = ReturnStatus.registered,
  });

  ReturnRecord copyWith({
    bool? restock,
    ReturnStatus? status,
  }) {
    return ReturnRecord(
      id: id,
      orderId: orderId,
      customer: customer,
      itemTitle: itemTitle,
      quantity: quantity,
      reason: reason,
      restock: restock ?? this.restock,
      date: date,
      status: status ?? this.status,
    );
  }
}

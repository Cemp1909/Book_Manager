class ReturnRecord {
  final String id;
  final String orderId;
  final String customer;
  final String itemTitle;
  final int quantity;
  final String reason;
  final bool restock;
  final DateTime date;

  const ReturnRecord({
    required this.id,
    required this.orderId,
    required this.customer,
    required this.itemTitle,
    required this.quantity,
    required this.reason,
    required this.restock,
    required this.date,
  });
}

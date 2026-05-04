import 'package:book_manager/datos/modelos/usuario_app.dart';

class AppWarehouse {
  final String id;
  final String name;
  final String location;

  const AppWarehouse({
    required this.id,
    required this.name,
    required this.location,
  });
}

class InventoryMovementDetail {
  final String bookIsbn;
  final String bookTitle;
  final int quantity;

  const InventoryMovementDetail({
    required this.bookIsbn,
    required this.bookTitle,
    required this.quantity,
  });
}

class InventoryMovementRecord {
  final String id;
  final DateTime date;
  final String movementType;
  final AppWarehouse warehouse;
  final AppUser? user;
  final int total;
  final String observation;
  final List<InventoryMovementDetail> details;

  const InventoryMovementRecord({
    required this.id,
    required this.date,
    required this.movementType,
    required this.warehouse,
    required this.user,
    required this.total,
    required this.observation,
    required this.details,
  });
}

class ScanLogRecord {
  final String id;
  final DateTime dateTime;
  final AppUser? user;
  final String code;
  final String codeType;
  final String result;
  final String? bookIsbn;
  final String? bookTitle;
  final String? comboId;
  final String? comboName;

  const ScanLogRecord({
    required this.id,
    required this.dateTime,
    required this.user,
    required this.code,
    required this.codeType,
    required this.result,
    this.bookIsbn,
    this.bookTitle,
    this.comboId,
    this.comboName,
  });
}

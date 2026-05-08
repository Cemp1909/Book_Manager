import 'dart:async';

import 'package:flutter/material.dart';
import 'package:book_manager/datos/api/api_client.dart';
import 'package:book_manager/datos/modelos/combo_libros.dart';
import 'package:book_manager/datos/modelos/bodega_inventario.dart';
import 'package:book_manager/datos/modelos/configuracion_empresa.dart';
import 'package:book_manager/datos/modelos/devolucion_app.dart';
import 'package:book_manager/datos/modelos/cliente_escolar.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';

class TemporaryDataService extends ChangeNotifier {
  TemporaryDataService._();

  static final TemporaryDataService instance = TemporaryDataService._();

  final List<AppOrder> _orders = [];
  final List<ReturnRecord> _returns = [];
  final List<_ComboTemplate> _comboTemplates = [];
  final List<_SchoolBookPrice> _bookPrices = [];
  final List<SchoolCity> _cities = [];
  final List<SchoolCustomer> _schools = [];
  final List<AppWarehouse> _warehouses = [];
  final List<InventoryMovementRecord> _inventoryMovements = [];
  final List<ScanLogRecord> _scanLogs = [];
  final Set<String> _generatedRemissions = {};
  CompanySettings _settings = CompanySettings.defaults;
  bool _settingsLoaded = false;
  final ApiClient _api = ApiClient.instance;

  List<AppOrder> get orders => List.unmodifiable(_orders);

  List<ReturnRecord> get returns => List.unmodifiable(_returns);

  List<SchoolCity> get cities => List.unmodifiable(_cities);

  List<SchoolCustomer> get schools => List.unmodifiable(_schools);

  List<AppWarehouse> get warehouses => List.unmodifiable(_warehouses);

  List<InventoryMovementRecord> get inventoryMovements =>
      List.unmodifiable(_inventoryMovements);

  List<ScanLogRecord> get scanLogs => List.unmodifiable(_scanLogs);

  CompanySettings get settings => _settings;

  int get pendingOrders =>
      _orders.where((order) => order.status != OrderStatus.dispatched).length;

  int get dispatchedOrders =>
      _orders.where((order) => order.status == OrderStatus.dispatched).length;

  int get returnCount => _returns.length;

  int get inventoryMovementCount => _inventoryMovements.length;

  int get scanLogCount => _scanLogs.length;

  int get todayOrders => _orders.length;

  int get income => _orders.fold(0, (sum, order) => sum + order.total);

  bool hasGeneratedRemission(String orderId) {
    return _generatedRemissions.contains(orderId);
  }

  Future<void> markRemissionGenerated(String orderId) async {
    await _persistRemission(orderId);
    _generatedRemissions.add(orderId);
    notifyListeners();
  }

  int currentSchoolYear() => DateTime.now().year;

  Future<void> loadSettings() async {
    if (_settingsLoaded) return;

    await _loadOracleTables();
    _settingsLoaded = true;
    notifyListeners();
  }

  Future<void> saveSettings(CompanySettings settings) async {
    _settings = settings;
    _settingsLoaded = true;
    notifyListeners();
  }

  List<SchoolCustomer> schoolsForCity(String? cityId) {
    if (cityId == null) return schools;
    return _schools.where((school) => school.cityId == cityId).toList();
  }

  int priceForBook({
    required Book book,
    required String schoolId,
    int? year,
  }) {
    final targetYear = year ?? currentSchoolYear();
    for (final price in _bookPrices) {
      if (price.bookIsbn == book.isbn &&
          price.schoolId == schoolId &&
          price.year == targetYear) {
        return price.price;
      }
    }
    return book.price;
  }

  Future<void> setBookPriceForSchool({
    required String bookIsbn,
    required String schoolId,
    required int year,
    required int price,
  }) async {
    final index = _bookPrices.indexWhere(
      (item) =>
          item.bookIsbn == bookIsbn &&
          item.schoolId == schoolId &&
          item.year == year,
    );
    final nextPrice = _SchoolBookPrice(
      bookIsbn: bookIsbn,
      schoolId: schoolId,
      year: year,
      price: price,
    );
    if (index == -1) {
      _bookPrices.add(nextPrice);
    } else {
      _bookPrices[index] = nextPrice;
    }
    await _persistBookPrice(nextPrice);
    notifyListeners();
  }

  SchoolCity? cityById(String cityId) {
    for (final city in _cities) {
      if (city.id == cityId) return city;
    }
    return null;
  }

  SchoolCustomer? schoolById(String schoolId) {
    for (final school in _schools) {
      if (school.id == schoolId) return school;
    }
    return null;
  }

  Future<void> addCity(String name) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final response = await _api.post('/api/v1/ciudades', {'nombre': cleanName});
    final id = _intValue(response['id']).toString();
    _cities.add(
      SchoolCity(
        id: id,
        name: cleanName,
      ),
    );
    notifyListeners();
  }

  Future<void> addSchool({
    required String cityId,
    required String name,
    required String address,
    required String phone,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final normalizedAddress =
        address.trim().isEmpty ? 'Pendiente por confirmar' : address.trim();
    final response = await _api.post('/api/v1/colegios', {
      'nombre': cleanName,
      'direccion': normalizedAddress,
      'telefono': phone.trim(),
      'id_ciudad': _intValue(cityId),
    });
    final id = _intValue(response['id']).toString();
    _schools.add(
      SchoolCustomer(
        id: id,
        cityId: cityId,
        name: cleanName,
        address: normalizedAddress,
        phone: phone.trim(),
      ),
    );
    notifyListeners();
  }

  Future<void> addWarehouse({
    required String name,
    required String location,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    final normalizedLocation =
        location.trim().isEmpty ? 'Sin ubicacion' : location.trim();
    final response = await _api.post('/api/v1/bodegas', {
      'nombre': cleanName,
      'ubicacion': normalizedLocation,
    });
    final id = _intValue(response['id']).toString();
    _warehouses.add(
      AppWarehouse(
        id: id,
        name: cleanName,
        location: normalizedLocation,
      ),
    );
    notifyListeners();
  }

  Future<void> addInventoryMovement(InventoryMovementRecord record) async {
    _inventoryMovements.insert(0, record);
    notifyListeners();
    await _persistInventoryMovement(record);
  }

  void addScanLog({
    required String code,
    required String codeType,
    required String result,
    required AppUser? user,
    String? bookIsbn,
    String? bookTitle,
    String? comboId,
    String? comboName,
  }) {
    _scanLogs.insert(
      0,
      ScanLogRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        dateTime: DateTime.now(),
        user: user,
        code: code,
        codeType: codeType,
        result: result,
        bookIsbn: bookIsbn,
        bookTitle: bookTitle,
        comboId: comboId,
        comboName: comboName,
      ),
    );
    unawaited(_persistScanLog(_scanLogs.first));
    notifyListeners();
  }

  List<BookCombo> buildCombos(
    List<Book> books, {
    String? cityId,
    String? schoolId,
  }) {
    if (books.length < 2) return const [];

    final booksByIsbn = {for (final book in books) book.isbn: book};

    return _comboTemplates
        .where((template) => cityId == null || template.cityId == cityId)
        .where((template) => schoolId == null || template.schoolId == schoolId)
        .map((template) {
          final comboBooks = template.bookIsbns
              .map((isbn) => booksByIsbn[isbn])
              .whereType<Book>()
              .toList();

          if (comboBooks.length < 2) return null;
          final school = schoolById(template.schoolId);
          final city = cityById(template.cityId);

          return BookCombo(
            id: template.id,
            name: template.name,
            audience: template.audience,
            cityId: template.cityId,
            cityName: city?.name ?? 'Ciudad sin asignar',
            schoolId: template.schoolId,
            schoolName: school?.name ?? 'Colegio sin asignar',
            books: comboBooks,
            discountPercent: template.discountPercent,
            customPrice: template.customPrice,
          );
        })
        .whereType<BookCombo>()
        .toList();
  }

  Future<void> addCombo({
    required String name,
    required String audience,
    required String cityId,
    required String schoolId,
    required int discountPercent,
    required int? customPrice,
    required List<String> bookIsbns,
  }) async {
    final combo = _ComboTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      audience: audience,
      cityId: cityId,
      schoolId: schoolId,
      discountPercent: discountPercent,
      customPrice: customPrice,
      bookIsbns: bookIsbns,
    );
    final comboId = await _persistCombo(combo);
    _comboTemplates.insert(
      0,
      combo.copyWith(id: comboId?.toString()),
    );
    notifyListeners();
  }

  Future<AppOrder> addOrder(
    AppOrder order, {
    AppUser? user,
    List<Book>? books,
  }) async {
    final savedOrder = await _persistOrder(order, user: user, books: books);
    _orders.insert(0, savedOrder);
    notifyListeners();
    return savedOrder;
  }

  Future<void> updateOrder(AppOrder order) async {
    final index = _orders.indexWhere((item) => item.id == order.id);
    if (index == -1) return;

    _orders[index] = order;
    await _persistOrderStatus(order.id, order.status);
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(status: status);
    await _persistOrderStatus(orderId, status);
    notifyListeners();
  }

  Future<void> addReturn(
    ReturnRecord record, {
    AppUser? user,
    OrderItem? item,
    List<Book>? books,
    InventoryMovementRecord? movement,
  }) async {
    await _persistReturn(
      record,
      user: user,
      item: item,
      books: books,
      movement: movement,
    );
    _returns.insert(0, record);
    notifyListeners();
  }

  Future<void> updateCombo({
    required String comboId,
    required String name,
    required String audience,
    required String cityId,
    required String schoolId,
    required int discountPercent,
    required int? customPrice,
    required List<String> bookIsbns,
  }) async {
    final index = _comboTemplates.indexWhere((combo) => combo.id == comboId);
    if (index == -1) return;

    _comboTemplates[index] = _comboTemplates[index].copyWith(
      name: name,
      audience: audience,
      cityId: cityId,
      schoolId: schoolId,
      discountPercent: discountPercent,
      customPrice: customPrice,
      clearCustomPrice: customPrice == null,
      bookIsbns: bookIsbns,
    );
    await _persistCombo(_comboTemplates[index], replace: true);
    notifyListeners();
  }

  Future<AppOrder> _persistOrder(
    AppOrder order, {
    AppUser? user,
    List<Book>? books,
  }) async {
    final availableBooks = books ?? await _loadBooksFromOracle();
    _cacheBooks(availableBooks);
    final response = await _api.post('/api/v1/domain/orders', {
      'schoolId': _schoolIdForOrder(order),
      'userId': await _userIdFor(user),
      'total': order.total,
      'status': order.status.label,
      'items': order.items
          .map((item) => _orderItemToApi(item, availableBooks))
          .toList(),
    });
    final id = _intValue(response['id']).toString();
    return order.copyWith(id: id);
  }

  Future<void> _persistBookPrice(_SchoolBookPrice price) async {
    await _loadBooksFromOracle();
    await _api.post('/api/v1/domain/book-prices', {
      'id_libro': _bookIdForIsbn(price.bookIsbn),
      'id_colegio': _intValue(price.schoolId),
      'anio': price.year,
      'precio': price.price,
    });
  }

  Future<int?> _persistCombo(
    _ComboTemplate combo, {
    bool replace = false,
  }) async {
    await _loadBooksFromOracle();
    if (replace) {
      await _api.put('/api/v1/domain/combos/${_intValue(combo.id)}', {
        'name': combo.name,
        'description': combo.audience,
        'schoolId': _intValue(combo.schoolId),
        'year': currentSchoolYear(),
        'price': combo.customPrice,
        'bookIds':
            combo.bookIsbns.map(_bookIdForIsbn).whereType<int>().toList(),
      });
      return _intValue(combo.id);
    }

    final response = await _api.post('/api/v1/combos', {
      'nombre': combo.name,
      'descripcion': combo.audience,
    });
    final comboId = _intValue(response['id']);

    for (final isbn in combo.bookIsbns) {
      await _api.post('/api/v1/combo-detalle', {
        'id_combo': comboId,
        'id_libro': _bookIdForIsbn(isbn),
        'cantidad': 1,
      });
    }

    if (combo.schoolId.isNotEmpty && combo.customPrice != null) {
      await _api.post('/api/v1/precio-combo-colegio-anio', {
        'id_combo': comboId,
        'id_colegio': _intValue(combo.schoolId),
        'anio': currentSchoolYear(),
        'precio': combo.customPrice,
      });
    }
    return comboId;
  }

  Future<void> _persistOrderStatus(String orderId, OrderStatus status) async {
    final id = _intValue(orderId, -1);
    if (id < 0) return;
    await _api.put('/api/v1/domain/orders/$id/status', {
      'status': status.label,
    });
  }

  Future<void> persistDispatch({
    required AppOrder order,
    required AppUser? user,
    required List<InventoryMovementDetail> details,
    InventoryMovementRecord? movement,
    List<Book>? books,
    String? remissionNumber,
  }) async {
    if (books != null) {
      _cacheBooks(books);
    } else {
      await _loadBooksFromOracle();
    }
    await _api.post('/api/v1/domain/dispatches', {
      'orderId': _intValue(order.id),
      'userId': await _userIdFor(user),
      'status': OrderStatus.dispatched.label,
      'remissionNumber': remissionNumber,
      'observation': 'Despacho del pedido #${order.id}',
      'details': details.map(_movementDetailToApi).toList(),
      if (movement != null) 'movement': await _inventoryMovementToApi(movement),
    });
  }

  Future<void> _persistReturn(
    ReturnRecord record, {
    AppUser? user,
    OrderItem? item,
    List<Book>? books,
    InventoryMovementRecord? movement,
  }) async {
    final availableBooks = books ?? await _loadBooksFromOracle();
    _cacheBooks(availableBooks);
    final returnItem = item == null
        ? null
        : _returnItemToApi(item, availableBooks, record.quantity, record);
    final details = returnItem == null ? const [] : [returnItem];
    await _api.post('/api/v1/domain/returns', {
      'orderId': _intValue(record.orderId),
      'userId': await _userIdFor(user),
      'reason': record.reason,
      'restock': record.restock,
      'status': record.status.label,
      'details': details,
      if (movement != null) 'movement': await _inventoryMovementToApi(movement),
    });
  }

  Future<void> _persistInventoryMovement(
    InventoryMovementRecord record,
  ) async {
    await _loadBooksFromOracle();
    await _api.post(
      '/api/v1/domain/inventory-movements',
      await _inventoryMovementToApi(record),
    );
  }

  Future<void> _persistScanLog(ScanLogRecord record) async {
    await _loadBooksFromOracle();
    await _api.post('/api/v1/log-escaneos', {
      'id_usuario': await _userIdFor(record.user),
      'id_libro':
          record.bookIsbn == null ? null : _bookIdForIsbn(record.bookIsbn!),
      'id_combo': record.comboId == null ? null : _intValue(record.comboId),
      'resultado': '${record.codeType}: ${record.result}',
    });
  }

  Future<Map<String, dynamic>> _inventoryMovementToApi(
    InventoryMovementRecord record,
  ) async {
    return {
      'movementType': record.movementType,
      'warehouseId': _intValue(record.warehouse.id),
      'userId': await _userIdFor(record.user),
      'total': record.total,
      'observation': record.observation,
      'details': record.details.map(_movementDetailToApi).toList(),
    };
  }

  Map<String, dynamic> _movementDetailToApi(InventoryMovementDetail detail) {
    return {
      'bookId': _bookIdForIsbn(detail.bookIsbn),
      'quantity': detail.quantity,
    };
  }

  Map<String, dynamic> _orderItemToApi(OrderItem item, List<Book> books) {
    final book = _bookForOrderItem(item, books);
    return {
      'productType': item.isCombo ? 'combo' : 'libro',
      'bookId': item.isCombo ? null : book?.id,
      'comboId': item.isCombo ? _comboIdForName(item.title) : null,
      'quantity': item.quantity,
      'unitPrice': item.unitPrice,
      'subtotal': item.total,
    };
  }

  Map<String, dynamic> _returnItemToApi(
    OrderItem item,
    List<Book> books,
    int quantity,
    ReturnRecord record,
  ) {
    final book = _bookForOrderItem(item, books);
    return {
      'bookId': item.isCombo ? null : book?.id,
      'comboId': item.isCombo ? _comboIdForName(item.title) : null,
      'quantity': quantity,
      'bookStatus': record.status.label,
      'observation': record.reason,
    };
  }

  int? _schoolIdForOrder(AppOrder order) {
    for (final school in _schools) {
      if (school.name.toLowerCase() == order.customer.toLowerCase()) {
        return _intValue(school.id);
      }
    }
    return null;
  }

  int? _comboIdForName(String name) {
    for (final combo in _comboTemplates) {
      if (combo.name.toLowerCase() == name.toLowerCase()) {
        final id = _intValue(combo.id, -1);
        return id < 0 ? null : id;
      }
    }
    return null;
  }

  int? _bookIdForIsbn(String isbn) {
    final normalized = isbn.toLowerCase();
    for (final book in _cachedBooks) {
      if (book.isbn.toLowerCase() == normalized) return book.id;
    }
    return null;
  }

  Book? _bookForOrderItem(OrderItem item, List<Book> books) {
    return books.cast<Book?>().firstWhere(
          (book) =>
              book?.title.toLowerCase() == item.title.toLowerCase() &&
              book?.author.toLowerCase() == item.subtitle.toLowerCase(),
          orElse: () => null,
        );
  }

  Future<int?> _userIdFor(AppUser? user) async {
    if (user == null) return null;
    try {
      final users = await _rows('/api/v1/usuarios?limit=1000');
      for (final row in users) {
        final email = _stringValue(row, 'CORREO', 'correo');
        if (email.toLowerCase() == user.email.toLowerCase()) {
          return _intValue(row['ID_USUARIO'] ?? row['id_usuario']);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  final List<Book> _cachedBooks = [];

  Future<List<Book>> _loadBooksFromOracle() async {
    final rows = await _rows('/api/v1/libros?limit=1000');
    final books = rows.map(Book.fromApiMap).toList();
    _cacheBooks(books);
    return List.unmodifiable(_cachedBooks);
  }

  void _cacheBooks(List<Book> books) {
    _cachedBooks
      ..clear()
      ..addAll(books);
  }

  Future<void> _persistRemission(String orderId) async {
    await _api.post('/api/v1/domain/remissions', {
      'orderId': _intValue(orderId),
      'number': 'REM-$orderId',
      'status': 'Generada',
    });
  }

  Future<void> _loadOracleTables() async {
    try {
      final cities = await _rows('/api/v1/ciudades?limit=200');
      final schools = await _rows('/api/v1/colegios?limit=500');
      final warehouses = await _rows('/api/v1/bodegas?limit=200');
      final bookPrices =
          await _rows('/api/v1/precio-libro-colegio-anio?limit=1000');
      final combos = await _rows('/api/v1/combos?limit=500');
      final comboDetails = await _rows('/api/v1/combo-detalle?limit=1000');
      final comboPrices =
          await _rows('/api/v1/precio-combo-colegio-anio?limit=1000');
      final books = await _rows('/api/v1/libros?limit=1000');
      final orders = await _rows('/api/v1/pedidos?limit=500');
      final orderDetails = await _rows('/api/v1/pedido-detalle?limit=2000');
      final returns = await _rows('/api/v1/devoluciones?limit=1000');
      final returnDetails =
          await _rows('/api/v1/devolucion-detalle?limit=2000');
      final movements = await _rows('/api/v1/movimiento-inventario?limit=1000');
      final movementDetails =
          await _rows('/api/v1/movimiento-detalle?limit=2000');
      final scans = await _rows('/api/v1/log-escaneos?limit=1000');
      final dispatches = await _rows('/api/v1/despachos?limit=1000');
      final remissions = await _rows('/api/v1/remisiones?limit=1000');
      final users = await _rows('/api/v1/usuarios?limit=1000');
      _loadedDispatches
        ..clear()
        ..addAll(dispatches);

      final booksById = {
        for (final book in books)
          _stringValue(book, 'ID_LIBRO', 'id_libro'): Book.fromApiMap(book),
      };
      _cacheBooks(booksById.values.toList());

      _cities
        ..clear()
        ..addAll(cities.map(_cityFromOracle));
      _schools
        ..clear()
        ..addAll(schools.map(_schoolFromOracle));
      _warehouses
        ..clear()
        ..addAll(warehouses.map(_warehouseFromOracle));
      _bookPrices
        ..clear()
        ..addAll(bookPrices.map((row) => _bookPriceFromOracle(row, booksById)));
      _comboTemplates
        ..clear()
        ..addAll(
          combos.map(
            (row) => _comboFromOracle(
              row,
              comboDetails,
              comboPrices,
              booksById,
            ),
          ),
        );
      _orders
        ..clear()
        ..addAll(
          orders.map((row) => _orderFromOracle(row, orderDetails, booksById)),
        );
      _returns
        ..clear()
        ..addAll(
          returns.map((row) => _returnFromOracle(
                row,
                returnDetails,
                booksById,
              )),
        );
      _inventoryMovements
        ..clear()
        ..addAll(
          movements.map((row) => _inventoryMovementFromOracle(
                row,
                movementDetails,
                booksById,
              )),
        );
      _scanLogs
        ..clear()
        ..addAll(scans.map((row) => _scanLogFromOracle(row, booksById, users)));
      _generatedRemissions
        ..clear()
        ..addAll(
          remissions.map((row) {
            final dispatchId = _stringValue(row, 'ID_DESPACHO', 'id_despacho');
            for (final dispatch in _loadedDispatches) {
              if (_stringValue(dispatch, 'ID_DESPACHO', 'id_despacho') ==
                  dispatchId) {
                return _stringValue(dispatch, 'ID_PEDIDO', 'id_pedido');
              }
            }
            return '';
          }).where((id) => id.isNotEmpty),
        );
    } catch (_) {
      // Keep whatever was already loaded in memory if the API is unavailable.
    }
  }

  final List<Map<String, dynamic>> _loadedDispatches = [];

  Future<List<Map<String, dynamic>>> _rows(String path) async {
    final response = await _api.get(path);
    final data = response['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((row) {
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  String _stringValue(
    Map<String, dynamic> map,
    String upperKey,
    String lowerKey,
  ) {
    return (map[upperKey] ?? map[lowerKey] ?? '').toString();
  }

  SchoolCity _cityFromOracle(Map<String, dynamic> map) {
    return SchoolCity(
      id: _stringValue(map, 'ID_CIUDAD', 'id_ciudad'),
      name: _stringValue(map, 'NOMBRE', 'nombre'),
    );
  }

  SchoolCustomer _schoolFromOracle(Map<String, dynamic> map) {
    return SchoolCustomer(
      id: _stringValue(map, 'ID_COLEGIO', 'id_colegio'),
      cityId: _stringValue(map, 'ID_CIUDAD', 'id_ciudad'),
      name: _stringValue(map, 'NOMBRE', 'nombre'),
      address: _stringValue(map, 'DIRECCION', 'direccion'),
      phone: _stringValue(map, 'TELEFONO', 'telefono'),
    );
  }

  AppWarehouse _warehouseFromOracle(Map<String, dynamic> map) {
    return AppWarehouse(
      id: _stringValue(map, 'ID_BODEGA', 'id_bodega'),
      name: _stringValue(map, 'NOMBRE', 'nombre'),
      location: _stringValue(map, 'UBICACION', 'ubicacion'),
    );
  }

  _SchoolBookPrice _bookPriceFromOracle(
    Map<String, dynamic> map,
    Map<String, Book> booksById,
  ) {
    final bookId = _stringValue(map, 'ID_LIBRO', 'id_libro');
    return _SchoolBookPrice(
      bookIsbn: booksById[bookId]?.isbn ?? bookId,
      schoolId: _stringValue(map, 'ID_COLEGIO', 'id_colegio'),
      year: _intValue(map['ANIO'] ?? map['anio']),
      price: _intValue(map['PRECIO'] ?? map['precio']),
    );
  }

  _ComboTemplate _comboFromOracle(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> details,
    List<Map<String, dynamic>> prices,
    Map<String, Book> booksById,
  ) {
    final comboId = _stringValue(map, 'ID_COMBO', 'id_combo');
    final detailRows = details.where(
      (detail) => _stringValue(detail, 'ID_COMBO', 'id_combo') == comboId,
    );
    final priceRow = prices.cast<Map<String, dynamic>?>().firstWhere(
          (price) =>
              _stringValue(price ?? {}, 'ID_COMBO', 'id_combo') == comboId,
          orElse: () => null,
        );
    final schoolId = priceRow == null
        ? ''
        : _stringValue(priceRow, 'ID_COLEGIO', 'id_colegio');
    final school = schoolId.isEmpty ? null : schoolById(schoolId);

    return _ComboTemplate(
      id: comboId,
      name: _stringValue(map, 'NOMBRE', 'nombre'),
      audience: school?.name ?? _stringValue(map, 'DESCRIPCION', 'descripcion'),
      cityId: school?.cityId ?? '',
      schoolId: schoolId,
      discountPercent: 0,
      customPrice: priceRow == null
          ? null
          : _intValue(priceRow['PRECIO'] ?? priceRow['precio']),
      bookIsbns: detailRows
          .map((detail) {
            final bookId = _stringValue(detail, 'ID_LIBRO', 'id_libro');
            return booksById[bookId]?.isbn ?? '';
          })
          .where((isbn) => isbn.isNotEmpty)
          .toList(),
    );
  }

  AppOrder _orderFromOracle(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> details,
    Map<String, Book> booksById,
  ) {
    final orderId = _stringValue(map, 'ID_PEDIDO', 'id_pedido');
    final schoolId = _stringValue(map, 'ID_COLEGIO', 'id_colegio');
    final school = schoolId.isEmpty ? null : schoolById(schoolId);
    final items = details
        .where((detail) =>
            _stringValue(detail, 'ID_PEDIDO', 'id_pedido') == orderId)
        .map((detail) {
      final bookId = _stringValue(detail, 'ID_LIBRO', 'id_libro');
      final book = booksById[bookId];
      return OrderItem(
        title: book?.title ?? 'Producto $bookId',
        subtitle: book?.author ?? '',
        unitPrice: _intValue(
          detail['PRECIO_UNITARIO'] ?? detail['precio_unitario'],
        ),
        quantity: _intValue(detail['CANTIDAD'] ?? detail['cantidad']),
        isCombo: _stringValue(detail, 'TIPO_PRODUCTO', 'tipo_producto')
            .toLowerCase()
            .contains('combo'),
      );
    }).toList();

    return AppOrder(
      id: orderId,
      customer: school?.name ?? 'Colegio $schoolId',
      date: _dateValue(map['FECHA'] ?? map['fecha']),
      status: _orderStatusFromOracle(_stringValue(map, 'ESTADO', 'estado')),
      items: items,
      deliveryAddress: school?.address ?? '',
    );
  }

  OrderStatus _orderStatusFromOracle(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('despach')) return OrderStatus.dispatched;
    if (normalized.contains('list')) return OrderStatus.ready;
    if (normalized.contains('prepar')) return OrderStatus.preparing;
    return OrderStatus.pending;
  }

  ReturnRecord _returnFromOracle(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> details,
    Map<String, Book> booksById,
  ) {
    final returnId = _stringValue(map, 'ID_DEVOLUCION', 'id_devolucion');
    final detail = details.cast<Map<String, dynamic>?>().firstWhere(
          (item) =>
              _stringValue(item ?? {}, 'ID_DEVOLUCION', 'id_devolucion') ==
              returnId,
          orElse: () => null,
        );
    final bookId =
        detail == null ? '' : _stringValue(detail, 'ID_LIBRO', 'id_libro');
    final book = booksById[bookId];
    return ReturnRecord(
      id: returnId,
      orderId: _stringValue(map, 'ID_PEDIDO', 'id_pedido'),
      customer: 'Pedido ${_stringValue(map, 'ID_PEDIDO', 'id_pedido')}',
      itemTitle: book?.title ?? 'Producto $bookId',
      quantity: detail == null
          ? 0
          : _intValue(detail['CANTIDAD'] ?? detail['cantidad']),
      reason: _stringValue(map, 'MOTIVO', 'motivo'),
      restock: _intValue(
              map['REINTEGRAR_INVENTARIO'] ?? map['reintegrar_inventario']) ==
          1,
      date: _dateValue(map['FECHA'] ?? map['fecha']),
      status: _returnStatusFromOracle(_stringValue(map, 'ESTADO', 'estado')),
    );
  }

  ReturnStatus _returnStatusFromOracle(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('reintegr')) return ReturnStatus.restocked;
    if (normalized.contains('no')) return ReturnStatus.notRestockable;
    return ReturnStatus.registered;
  }

  InventoryMovementRecord _inventoryMovementFromOracle(
    Map<String, dynamic> map,
    List<Map<String, dynamic>> details,
    Map<String, Book> booksById,
  ) {
    final movementId = _stringValue(map, 'ID_MOVIMIENTO', 'id_movimiento');
    final movementDetails = details
        .where((detail) =>
            _stringValue(detail, 'ID_MOVIMIENTO', 'id_movimiento') ==
            movementId)
        .map((detail) {
      final bookId = _stringValue(detail, 'ID_LIBRO', 'id_libro');
      final book = booksById[bookId];
      return InventoryMovementDetail(
        bookIsbn: book?.isbn ?? bookId,
        bookTitle: book?.title ?? 'Libro $bookId',
        quantity: _intValue(detail['CANTIDAD'] ?? detail['cantidad']),
      );
    }).toList();
    final warehouseId = _stringValue(map, 'ID_BODEGA', 'id_bodega');
    final warehouse = warehouseId.isEmpty
        ? null
        : _warehouses.cast<AppWarehouse?>().firstWhere(
              (item) => item?.id == warehouseId,
              orElse: () => null,
            );

    return InventoryMovementRecord(
      id: movementId,
      date: _dateValue(map['FECHA'] ?? map['fecha']),
      movementType: _stringValue(map, 'TIPO_MOVIMIENTO', 'tipo_movimiento'),
      warehouse: warehouse ??
          AppWarehouse(
            id: warehouseId,
            name: 'Bodega $warehouseId',
            location: '',
          ),
      user: null,
      total: _intValue(map['TOTAL'] ?? map['total']),
      observation: _stringValue(map, 'OBSERVACION', 'observacion'),
      details: movementDetails,
    );
  }

  ScanLogRecord _scanLogFromOracle(
    Map<String, dynamic> map,
    Map<String, Book> booksById,
    List<Map<String, dynamic>> users,
  ) {
    final bookId = _stringValue(map, 'ID_LIBRO', 'id_libro');
    final book = booksById[bookId];
    final userId = _stringValue(map, 'ID_USUARIO', 'id_usuario');
    final userRow = users.cast<Map<String, dynamic>?>().firstWhere(
          (row) =>
              _stringValue(row ?? {}, 'ID_USUARIO', 'id_usuario') == userId,
          orElse: () => null,
        );
    final result = _stringValue(map, 'RESULTADO', 'resultado');
    return ScanLogRecord(
      id: _stringValue(map, 'ID_LOG_ESCANEO', 'id_log_escaneo'),
      dateTime: _dateValue(map['FECHA_HORA'] ?? map['fecha_hora']),
      user: userRow == null
          ? null
          : AppUser(
              name: _stringValue(userRow, 'NOMBRE', 'nombre'),
              email: _stringValue(userRow, 'CORREO', 'correo'),
            ),
      code: book?.isbn ?? '',
      codeType: result.split(':').first,
      result: result,
      bookIsbn: book?.isbn,
      bookTitle: book?.title,
      comboId: _stringValue(map, 'ID_COMBO', 'id_combo'),
    );
  }

  int _intValue(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  DateTime _dateValue(Object? value) {
    return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
  }
}

class _SchoolBookPrice {
  final String bookIsbn;
  final String schoolId;
  final int year;
  final int price;

  const _SchoolBookPrice({
    required this.bookIsbn,
    required this.schoolId,
    required this.year,
    required this.price,
  });
}

class _ComboTemplate {
  final String id;
  final String name;
  final String audience;
  final String cityId;
  final String schoolId;
  final int discountPercent;
  final int? customPrice;
  final List<String> bookIsbns;

  const _ComboTemplate({
    required this.id,
    required this.name,
    required this.audience,
    required this.cityId,
    required this.schoolId,
    required this.discountPercent,
    required this.customPrice,
    required this.bookIsbns,
  });

  _ComboTemplate copyWith({
    String? id,
    String? name,
    String? audience,
    String? cityId,
    String? schoolId,
    int? discountPercent,
    int? customPrice,
    bool clearCustomPrice = false,
    List<String>? bookIsbns,
  }) {
    return _ComboTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      audience: audience ?? this.audience,
      cityId: cityId ?? this.cityId,
      schoolId: schoolId ?? this.schoolId,
      discountPercent: discountPercent ?? this.discountPercent,
      customPrice: clearCustomPrice ? null : customPrice ?? this.customPrice,
      bookIsbns: bookIsbns ?? this.bookIsbns,
    );
  }
}

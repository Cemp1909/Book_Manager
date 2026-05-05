import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const _companyNameKey = 'settings_company_name';
  static const _currencyKey = 'settings_currency_symbol';
  static const _lowStockKey = 'settings_low_stock_limit';

  final List<AppOrder> _orders = _seedOrders;
  final List<ReturnRecord> _returns = [];
  final List<_ComboTemplate> _comboTemplates = List.of(_seedComboTemplates);
  final List<_SchoolBookPrice> _bookPrices = List.of(_seedBookPrices);
  final List<SchoolCity> _cities = List.of(_seedCities);
  final List<SchoolCustomer> _schools = List.of(_seedSchools);
  final List<AppWarehouse> _warehouses = List.of(_seedWarehouses);
  final List<InventoryMovementRecord> _inventoryMovements = [];
  final List<ScanLogRecord> _scanLogs = [];
  final Set<String> _generatedRemissions = {};
  CompanySettings _settings = CompanySettings.defaults;
  bool _settingsLoaded = false;

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

  void markRemissionGenerated(String orderId) {
    _generatedRemissions.add(orderId);
    notifyListeners();
  }

  int currentSchoolYear() => DateTime.now().year;

  Future<void> loadSettings() async {
    if (_settingsLoaded) return;

    final prefs = await SharedPreferences.getInstance();
    _settings = CompanySettings(
      companyName: prefs.getString(_companyNameKey) ??
          CompanySettings.defaults.companyName,
      currencySymbol: prefs.getString(_currencyKey) ??
          CompanySettings.defaults.currencySymbol,
      lowStockLimit:
          prefs.getInt(_lowStockKey) ?? CompanySettings.defaults.lowStockLimit,
    );
    _settingsLoaded = true;
    notifyListeners();
  }

  Future<void> saveSettings(CompanySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_companyNameKey, settings.companyName);
    await prefs.setString(_currencyKey, settings.currencySymbol);
    await prefs.setInt(_lowStockKey, settings.lowStockLimit);

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

  void setBookPriceForSchool({
    required String bookIsbn,
    required String schoolId,
    required int year,
    required int price,
  }) {
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

  void addCity(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    _cities.add(
      SchoolCity(
        id: _slugId(cleanName),
        name: cleanName,
      ),
    );
    notifyListeners();
  }

  void addSchool({
    required String cityId,
    required String name,
    required String address,
    required String phone,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    _schools.add(
      SchoolCustomer(
        id: _slugId('$cityId-$cleanName'),
        cityId: cityId,
        name: cleanName,
        address:
            address.trim().isEmpty ? 'Pendiente por confirmar' : address.trim(),
        phone: phone.trim(),
      ),
    );
    notifyListeners();
  }

  void addWarehouse({
    required String name,
    required String location,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;

    _warehouses.add(
      AppWarehouse(
        id: _slugId(cleanName),
        name: cleanName,
        location: location.trim().isEmpty ? 'Sin ubicacion' : location.trim(),
      ),
    );
    notifyListeners();
  }

  void addInventoryMovement(InventoryMovementRecord record) {
    _inventoryMovements.insert(0, record);
    notifyListeners();
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
    notifyListeners();
  }

  String _slugId(String value) {
    final slug = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final exists = _cities.any((city) => city.id == slug) ||
        _schools.any((school) => school.id == slug);
    return exists ? '${slug}_${DateTime.now().millisecondsSinceEpoch}' : slug;
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

  void addCombo({
    required String name,
    required String audience,
    required String cityId,
    required String schoolId,
    required int discountPercent,
    required int? customPrice,
    required List<String> bookIsbns,
  }) {
    _comboTemplates.insert(
      0,
      _ComboTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        audience: audience,
        cityId: cityId,
        schoolId: schoolId,
        discountPercent: discountPercent,
        customPrice: customPrice,
        bookIsbns: bookIsbns,
      ),
    );
    notifyListeners();
  }

  void addOrder(AppOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrder(AppOrder order) {
    final index = _orders.indexWhere((item) => item.id == order.id);
    if (index == -1) return;

    _orders[index] = order;
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(status: status);
    notifyListeners();
  }

  void addReturn(ReturnRecord record) {
    _returns.insert(0, record);
    notifyListeners();
  }

  void updateCombo({
    required String comboId,
    required String name,
    required String audience,
    required String cityId,
    required String schoolId,
    required int discountPercent,
    required int? customPrice,
    required List<String> bookIsbns,
  }) {
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
    notifyListeners();
  }

  static const List<SchoolCity> _seedCities = [
    SchoolCity(id: 'bogota', name: 'Bogota'),
    SchoolCity(id: 'medellin', name: 'Medellin'),
    SchoolCity(id: 'cali', name: 'Cali'),
  ];

  static const List<SchoolCustomer> _seedSchools = [
    SchoolCustomer(
      id: 'los_alamos',
      cityId: 'bogota',
      name: 'Colegio Los Alamos',
      address: 'Cra. 12 #45-20',
      phone: '601 555 1200',
    ),
    SchoolCustomer(
      id: 'san_martin',
      cityId: 'medellin',
      name: 'Colegio San Martin',
      address: 'Calle 80 #22-15',
      phone: '604 555 8030',
    ),
    SchoolCustomer(
      id: 'nueva_granada',
      cityId: 'cali',
      name: 'Colegio Nueva Granada',
      address: 'Av. 6 Norte #18-40',
      phone: '602 555 4200',
    ),
  ];

  static const List<AppWarehouse> _seedWarehouses = [
    AppWarehouse(
      id: 'principal',
      name: 'Bodega principal',
      location: 'Principal',
    ),
    AppWarehouse(
      id: 'despachos',
      name: 'Zona de despachos',
      location: 'Salida de pedidos',
    ),
  ];

  static const List<_SchoolBookPrice> _seedBookPrices = [
    _SchoolBookPrice(
      bookIsbn: '978-84-376-0494-7',
      schoolId: 'los_alamos',
      year: 2026,
      price: 43000,
    ),
    _SchoolBookPrice(
      bookIsbn: '978-84-9759-329-4',
      schoolId: 'los_alamos',
      year: 2026,
      price: 36000,
    ),
    _SchoolBookPrice(
      bookIsbn: '978-84-376-0494-7',
      schoolId: 'san_martin',
      year: 2026,
      price: 47000,
    ),
  ];

  static final _sampleBooks = [
    const Book(
      title: 'Cien anos de soledad',
      author: 'Gabriel Garcia Marquez',
      isbn: '978-84-376-0494-7',
      price: 45000,
      stock: 50,
      genre: 'Novela',
      description: 'Lectura principal para plan lector.',
    ),
    const Book(
      title: '1984',
      author: 'George Orwell',
      isbn: '978-84-9759-329-4',
      price: 38000,
      stock: 5,
      genre: 'Ciencia ficcion',
      description: 'Texto para analisis literario.',
    ),
    const Book(
      title: 'El principito',
      author: 'Antoine de Saint-Exupery',
      isbn: '978-84-376-0494-8',
      price: 25000,
      stock: 0,
      genre: 'Infantil',
      description: 'Lectura corta para actividades.',
    ),
  ];

  static final List<AppOrder> _seedOrders = [
    AppOrder(
      id: '2024001',
      customer: 'Colegio Los Alamos',
      date: DateTime(2026, 4, 12),
      status: OrderStatus.pending,
      deliveryAddress: 'Cra. 12 #45-20',
      items: [
        OrderItem(
          title: _sampleBooks[0].title,
          subtitle: _sampleBooks[0].author,
          unitPrice: _sampleBooks[0].price,
          quantity: 18,
        ),
        OrderItem(
          title: _sampleBooks[1].title,
          subtitle: _sampleBooks[1].author,
          unitPrice: _sampleBooks[1].price,
          quantity: 8,
        ),
      ],
    ),
    AppOrder(
      id: '2024002',
      customer: 'Libreria Central',
      date: DateTime(2026, 4, 11),
      status: OrderStatus.ready,
      deliveryAddress: 'Av. Principal #10-35',
      items: [
        const OrderItem(
          title: 'Combo literatura clasica',
          subtitle: '3 libros con descuento',
          unitPrice: 92000,
          quantity: 4,
          isCombo: true,
        ),
        OrderItem(
          title: _sampleBooks[1].title,
          subtitle: _sampleBooks[1].author,
          unitPrice: _sampleBooks[1].price,
          quantity: 6,
        ),
      ],
    ),
    AppOrder(
      id: '2024003',
      customer: 'Colegio San Martin',
      date: DateTime(2026, 4, 10),
      status: OrderStatus.dispatched,
      deliveryAddress: 'Calle 80 #22-15',
      items: [
        OrderItem(
          title: _sampleBooks[0].title,
          subtitle: _sampleBooks[0].author,
          unitPrice: _sampleBooks[0].price,
          quantity: 20,
        ),
      ],
    ),
  ];

  static const List<_ComboTemplate> _seedComboTemplates = [
    _ComboTemplate(
      id: 'combo_secundaria',
      name: 'Plan lectura secundaria',
      audience: 'Colegio Los Alamos',
      cityId: 'bogota',
      schoolId: 'los_alamos',
      discountPercent: 12,
      customPrice: null,
      bookIsbns: [
        '978-84-376-0494-7',
        '978-84-9759-329-4',
        '978-84-376-0494-8',
      ],
    ),
    _ComboTemplate(
      id: 'combo_clasica',
      name: 'Combo literatura clasica',
      audience: 'Grado 10 y 11',
      cityId: 'medellin',
      schoolId: 'san_martin',
      discountPercent: 10,
      customPrice: 92000,
      bookIsbns: [
        '978-84-9759-329-5',
        '978-84-376-0494-8',
        '978-84-9759-329-4',
      ],
    ),
    _ComboTemplate(
      id: 'combo_inicial',
      name: 'Biblioteca inicial',
      audience: 'Clientes nuevos',
      cityId: 'cali',
      schoolId: 'nueva_granada',
      discountPercent: 15,
      customPrice: null,
      bookIsbns: [
        '978-84-376-0494-7',
        '978-84-9759-329-4',
        '978-84-9759-329-5',
      ],
    ),
  ];
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

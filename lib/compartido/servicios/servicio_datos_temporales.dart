import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_manager/datos/modelos/combo_libros.dart';
import 'package:book_manager/datos/modelos/configuracion_empresa.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';

class TemporaryDataService extends ChangeNotifier {
  TemporaryDataService._();

  static final TemporaryDataService instance = TemporaryDataService._();

  static const _companyNameKey = 'settings_company_name';
  static const _currencyKey = 'settings_currency_symbol';
  static const _lowStockKey = 'settings_low_stock_limit';

  final List<AppOrder> _orders = _seedOrders;
  final List<_ComboTemplate> _comboTemplates = List.of(_seedComboTemplates);
  CompanySettings _settings = CompanySettings.defaults;
  bool _settingsLoaded = false;

  List<AppOrder> get orders => List.unmodifiable(_orders);

  CompanySettings get settings => _settings;

  int get pendingOrders =>
      _orders.where((order) => order.status != OrderStatus.dispatched).length;

  int get dispatchedOrders =>
      _orders.where((order) => order.status == OrderStatus.dispatched).length;

  int get todayOrders => _orders.length;

  int get income => _orders.fold(0, (sum, order) => sum + order.total);

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

  List<BookCombo> buildCombos(List<Book> books) {
    if (books.length < 2) return const [];

    final booksByIsbn = {for (final book in books) book.isbn: book};

    return _comboTemplates
        .map((template) {
          final comboBooks = template.bookIsbns
              .map((isbn) => booksByIsbn[isbn])
              .whereType<Book>()
              .toList();

          if (comboBooks.length < 2) return null;

          return BookCombo(
            id: template.id,
            name: template.name,
            audience: template.audience,
            books: comboBooks,
            discountPercent: template.discountPercent,
          );
        })
        .whereType<BookCombo>()
        .toList();
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

  void updateCombo({
    required String comboId,
    required String name,
    required String audience,
    required int discountPercent,
    required List<String> bookIsbns,
  }) {
    final index = _comboTemplates.indexWhere((combo) => combo.id == comboId);
    if (index == -1) return;

    _comboTemplates[index] = _comboTemplates[index].copyWith(
      name: name,
      audience: audience,
      discountPercent: discountPercent,
      bookIsbns: bookIsbns,
    );
    notifyListeners();
  }

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
      discountPercent: 12,
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
      discountPercent: 10,
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
      discountPercent: 15,
      bookIsbns: [
        '978-84-376-0494-7',
        '978-84-9759-329-4',
        '978-84-9759-329-5',
      ],
    ),
  ];
}

class _ComboTemplate {
  final String id;
  final String name;
  final String audience;
  final int discountPercent;
  final List<String> bookIsbns;

  const _ComboTemplate({
    required this.id,
    required this.name,
    required this.audience,
    required this.discountPercent,
    required this.bookIsbns,
  });

  _ComboTemplate copyWith({
    String? id,
    String? name,
    String? audience,
    int? discountPercent,
    List<String>? bookIsbns,
  }) {
    return _ComboTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      audience: audience ?? this.audience,
      discountPercent: discountPercent ?? this.discountPercent,
      bookIsbns: bookIsbns ?? this.bookIsbns,
    );
  }
}

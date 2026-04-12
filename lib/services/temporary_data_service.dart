import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_order.dart';
import '../models/book.dart';
import '../models/book_combo.dart';
import '../models/company_settings.dart';

class TemporaryDataService extends ChangeNotifier {
  TemporaryDataService._();

  static final TemporaryDataService instance = TemporaryDataService._();

  static const _companyNameKey = 'settings_company_name';
  static const _currencyKey = 'settings_currency_symbol';
  static const _lowStockKey = 'settings_low_stock_limit';

  final List<AppOrder> _orders = _seedOrders;
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
    if (books.length < 3) return const [];

    return [
      BookCombo(
        name: 'Plan lectura secundaria',
        audience: 'Colegio Los Alamos',
        books: books.take(3).toList(),
        discountPercent: 12,
      ),
      BookCombo(
        name: 'Combo literatura clasica',
        audience: 'Grado 10 y 11',
        books: books.reversed.take(3).toList(),
        discountPercent: 10,
      ),
      BookCombo(
        name: 'Biblioteca inicial',
        audience: 'Clientes nuevos',
        books: books.where((book) => book.stock > 0).take(4).toList(),
        discountPercent: 15,
      ),
    ];
  }

  void addOrder(AppOrder order) {
    _orders.insert(0, order);
    notifyListeners();
  }

  void updateOrderStatus(String orderId, OrderStatus status) {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return;

    _orders[index] = _orders[index].copyWith(status: status);
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
        OrderItem(book: _sampleBooks[0], quantity: 18),
        OrderItem(book: _sampleBooks[1], quantity: 8),
      ],
    ),
    AppOrder(
      id: '2024002',
      customer: 'Libreria Central',
      date: DateTime(2026, 4, 11),
      status: OrderStatus.ready,
      deliveryAddress: 'Av. Principal #10-35',
      items: [
        OrderItem(book: _sampleBooks[2], quantity: 12),
        OrderItem(book: _sampleBooks[1], quantity: 6),
      ],
    ),
    AppOrder(
      id: '2024003',
      customer: 'Colegio San Martin',
      date: DateTime(2026, 4, 10),
      status: OrderStatus.dispatched,
      deliveryAddress: 'Calle 80 #22-15',
      items: [
        OrderItem(book: _sampleBooks[0], quantity: 20),
      ],
    ),
  ];
}

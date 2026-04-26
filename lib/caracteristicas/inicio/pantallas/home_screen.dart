import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/app_theme.dart';
import 'package:book_manager/caracteristicas/autenticacion/modelos/app_user.dart';
import 'package:book_manager/caracteristicas/autenticacion/servicios/auth_service.dart';
import 'package:book_manager/caracteristicas/combos/pantallas/combos_screen.dart';
import 'package:book_manager/caracteristicas/configuracion/pantallas/settings_screen.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/inventory_screen.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/scanner_screen.dart';
import 'package:book_manager/caracteristicas/pedidos/modelos/app_order.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/dispatches_screen.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/orders_screen.dart';
import 'package:book_manager/compartido/servicios/temporary_data_service.dart';
import 'package:book_manager/caracteristicas/inicio/pantallas/dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    TemporaryDataService.instance.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildNavItems();
    final selectedIndex = _selectedIndex >= items.length ? 0 : _selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(items[selectedIndex].title),
        actions: [
          if (widget.user.canUseScanner)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _openScanner,
            ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.teal,
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            onPressed: () {
              _showUserMenu(context);
            },
          ),
        ],
      ),
      body: items[selectedIndex].screen,
      bottomNavigationBar: items.length < 2
          ? null
          : NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              destinations: items.map((item) => item.destination).toList(),
            ),
    );
  }

  List<_NavItem> _buildNavItems() {
    final items = <_NavItem>[];

    if (widget.user.canViewDashboard) {
      items.add(
        _NavItem(
          title: 'Editorial Manager',
          destination: const NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          screen: DashboardScreen(
            onNewOrder:
                widget.user.canCreateOrders ? () => _selectSection('Pedidos') : null,
            onOpenDispatches: widget.user.canViewDispatches
                ? () => _selectSection('Despachos')
                : null,
            onScan: widget.user.canUseScanner ? _openScanner : null,
            canEditOrders: widget.user.canEditOrders,
            canAdvanceOrders: widget.user.canAdvanceOrders,
            onEditOrder: (order) => _selectSection('Pedidos'),
            onAdvanceOrder: (order) => TemporaryDataService.instance
                .updateOrderStatus(order.id, _nextOrderStatus(order.status)),
          ),
        ),
      );
    }

    if (widget.user.canViewInventory) {
      items.add(
        _NavItem(
          title: 'Inventario',
          destination: const NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Inventario',
          ),
          screen: InventoryScreen(
            canManageInventory: widget.user.canManageInventory,
            canEditStockOnly: widget.user.canEditStockOnly,
            showPrices: widget.user.canSeePrices,
            showFullDetails: widget.user.canSeeInventoryDetails,
            canScanInventory: widget.user.canUseScanner,
          ),
        ),
      );
    }

    if (widget.user.canViewCombos) {
      items.add(
        _NavItem(
          title: 'Combos',
          destination: const NavigationDestination(
            icon: Icon(Icons.grid_view),
            label: 'Combos',
          ),
          screen: CombosScreen(
            canEditCombos: widget.user.canEditCombos,
          ),
        ),
      );
    }

    if (widget.user.canViewOrders) {
      items.add(
        _NavItem(
          title: 'Pedidos',
          destination: const NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Pedidos',
          ),
          screen: OrdersScreen(
            canCreateOrders: widget.user.canCreateOrders,
            canEditOrders: widget.user.canEditOrders,
            canAdvanceOrders: widget.user.canAdvanceOrders,
          ),
        ),
      );
    }

    if (widget.user.canViewDispatches) {
      items.add(
        _NavItem(
          title: 'Despachos',
          destination: const NavigationDestination(
            icon: Icon(Icons.local_shipping),
            label: 'Despachos',
          ),
          screen: DispatchesScreen(
            canDispatchOrders: widget.user.canDispatchOrders,
          ),
        ),
      );
    }

    return items;
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _selectSection(String title) {
    final index = _buildNavItems().indexWhere((item) => item.title == title);
    if (index == -1) return;
    _selectTab(index);
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
  }

  OrderStatus _nextOrderStatus(OrderStatus status) {
    return switch (status) {
      OrderStatus.pending => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.dispatched,
      OrderStatus.dispatched => OrderStatus.dispatched,
    };
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.teal,
              child: Text(
                widget.user.name.isNotEmpty
                    ? widget.user.name[0].toUpperCase()
                    : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.user.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(widget.user.email),
            const SizedBox(height: 4),
            Chip(
              label: Text(widget.user.role.label),
              backgroundColor: AppColors.teal.withValues(alpha: 0.12),
              labelStyle: const TextStyle(
                color: AppColors.tealDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 30),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Escanear código'),
              onTap: () {
                Navigator.pop(context);
                _openScanner();
              },
            ),
            if (widget.user.canManageSettings)
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(context);
                await AuthService.instance.logout();
                if (!mounted) return;
                widget.onLogout();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final String title;
  final NavigationDestination destination;
  final Widget screen;

  const _NavItem({
    required this.title,
    required this.destination,
    required this.screen,
  });
}

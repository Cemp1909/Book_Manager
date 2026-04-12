import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/temporary_data_service.dart';
import '../theme/app_theme.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'combos_screen.dart';
import 'orders_screen.dart';
import 'dispatches_screen.dart';
import 'scanner_screen.dart';
import 'settings_screen.dart';

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

  final List<String> _titles = [
    'Editorial Manager',
    'Inventario',
    'Combos',
    'Pedidos',
    'Despachos',
  ];

  @override
  void initState() {
    super.initState();
    TemporaryDataService.instance.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNewOrder: () => _selectTab(3),
        onOpenDispatches: () => _selectTab(4),
        onScan: _openScanner,
      ),
      const InventoryScreen(),
      const CombosScreen(),
      const OrdersScreen(),
      const DispatchesScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
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
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Inicio'),
          NavigationDestination(
            icon: Icon(Icons.menu_book),
            label: 'Inventario',
          ),
          NavigationDestination(icon: Icon(Icons.grid_view), label: 'Combos'),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Pedidos',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping),
            label: 'Despachos',
          ),
        ],
      ),
    );
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
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
              label: Text(widget.user.role),
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

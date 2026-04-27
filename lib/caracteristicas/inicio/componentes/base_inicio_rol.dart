import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/caracteristicas/autenticacion/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/autenticacion/servicios/servicio_autenticacion.dart';
import 'package:book_manager/caracteristicas/configuracion/pantallas/pantalla_configuracion.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_escaner.dart';
import 'package:book_manager/caracteristicas/pedidos/modelos/pedido_app.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';

class BaseInicioRol extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;
  final List<ItemNavegacionRol> Function(AccionesInicioRol actions) buildItems;

  const BaseInicioRol({
    super.key,
    required this.user,
    required this.onLogout,
    required this.buildItems,
  });

  @override
  State<BaseInicioRol> createState() => _BaseInicioRolState();
}

class _BaseInicioRolState extends State<BaseInicioRol> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    TemporaryDataService.instance.loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.buildItems(_actions);
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
            onPressed: () => _showUserMenu(context),
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

  AccionesInicioRol get _actions {
    return AccionesInicioRol(
      openScanner: _openScanner,
      selectSection: _selectSection,
      advanceOrder: _advanceOrder,
    );
  }

  void _selectSection(String title) {
    final items = widget.buildItems(_actions);
    final index = items.indexWhere((item) => item.title == title);
    if (index == -1) return;

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

  void _advanceOrder(AppOrder order) {
    TemporaryDataService.instance.updateOrderStatus(
      order.id,
      _nextOrderStatus(order.status),
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
            if (widget.user.canUseScanner)
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

class AccionesInicioRol {
  final VoidCallback openScanner;
  final void Function(String title) selectSection;
  final void Function(AppOrder order) advanceOrder;

  const AccionesInicioRol({
    required this.openScanner,
    required this.selectSection,
    required this.advanceOrder,
  });
}

class ItemNavegacionRol {
  final String title;
  final NavigationDestination destination;
  final Widget screen;

  const ItemNavegacionRol({
    required this.title,
    required this.destination,
    required this.screen,
  });
}

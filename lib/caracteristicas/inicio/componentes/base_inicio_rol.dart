import 'package:flutter/material.dart';
import 'package:book_manager/aplicacion/tema/tema_app.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/datos/modelos/libro.dart';
import 'package:book_manager/caracteristicas/autenticacion/servicios/servicio_autenticacion.dart';
import 'package:book_manager/caracteristicas/configuracion/pantallas/pantalla_configuracion.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_escaner.dart';
import 'package:book_manager/datos/modelos/pedido_app.dart';
import 'package:book_manager/compartido/servicios/servicio_datos_temporales.dart';
import 'package:book_manager/compartido/servicios/servicio_historial.dart';

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
  Book? _bookToOpen;
  int _bookOpenRequest = 0;

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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        toolbarHeight: 82,
        titleSpacing: 16,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.aurora,
            border: Border(
              bottom: BorderSide(
                color: AppColors.border.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        leading: items.length < 2
            ? null
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Abrir menu',
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(items[selectedIndex].title),
            const SizedBox(height: 3),
            Text(
              '${widget.user.role.label} · ${widget.user.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.user.canUseScanner)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _openScanner,
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _showUserMenu(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: AppColors.teal,
                  child: Text(
                    widget.user.name.isNotEmpty
                        ? widget.user.name[0].toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: items.length < 2
          ? null
          : _MenuLateralRol(
              user: widget.user,
              items: items,
              selectedIndex: selectedIndex,
              onSelected: (index) {
                Navigator.pop(context);
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.aurora),
        child: items[selectedIndex].screen,
      ),
    );
  }

  AccionesInicioRol get _actions {
    return AccionesInicioRol(
      openScanner: _openScanner,
      selectSection: _selectSection,
      openBookInSection: _openBookInSection,
      bookToOpen: _bookToOpen,
      bookOpenRequest: _bookOpenRequest,
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

  void _openBookInSection(String title, Book book) {
    final items = widget.buildItems(_actions);
    final index = items.indexWhere((item) => item.title == title);
    if (index == -1) return;

    setState(() {
      _bookToOpen = book;
      _bookOpenRequest++;
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
    final nextStatus = _nextOrderStatus(order.status);
    TemporaryDataService.instance.updateOrderStatus(order.id, nextStatus);
    ActivityLogService.instance.record(
      type: ActivityType.orders,
      title: 'Pedido actualizado',
      detail: 'Pedido ${order.id} paso a ${nextStatus.label}.',
      actor: widget.user,
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
                      builder: (context) => SettingsScreen(
                        currentUser: widget.user,
                      ),
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
  final void Function(String title, Book book) openBookInSection;
  final Book? bookToOpen;
  final int bookOpenRequest;
  final void Function(AppOrder order) advanceOrder;

  const AccionesInicioRol({
    required this.openScanner,
    required this.selectSection,
    required this.openBookInSection,
    required this.bookToOpen,
    required this.bookOpenRequest,
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

class _MenuLateralRol extends StatelessWidget {
  final AppUser user;
  final List<ItemNavegacionRol> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _MenuLateralRol({
    required this.user,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.navy,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.command,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.teal,
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.role.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = index == selectedIndex;
                  final icon = selected
                      ? item.destination.selectedIcon ?? item.destination.icon
                      : item.destination.icon;

                  return ListTile(
                    selected: selected,
                    selectedColor: Colors.white,
                    selectedTileColor: AppColors.teal.withValues(alpha: 0.22),
                    iconColor: selected ? Colors.white : Colors.white70,
                    textColor: selected ? Colors.white : Colors.white70,
                    leading: IconTheme(
                      data: IconThemeData(
                        color: selected ? Colors.white : Colors.white70,
                      ),
                      child: icon,
                    ),
                    title: Text(
                      item.destination.label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () => onSelected(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

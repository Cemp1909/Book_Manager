import 'package:flutter/material.dart';
import 'package:book_manager/caracteristicas/autenticacion/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/combos/pantallas/pantalla_combos.dart';
import 'package:book_manager/caracteristicas/inicio/componentes/base_inicio_rol.dart';
import 'package:book_manager/caracteristicas/inicio/pantallas/pantalla_panel.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_inventario.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/pantalla_despachos.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/pantalla_pedidos.dart';

class PantallaInicioVendedor extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const PantallaInicioVendedor({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return BaseInicioRol(
      user: user,
      onLogout: onLogout,
      buildItems: (actions) {
        return [
          ItemNavegacionRol(
            title: 'Panel de ventas',
            destination: const NavigationDestination(
              icon: Icon(Icons.dashboard),
              label: 'Inicio',
            ),
            screen: DashboardScreen(
              onNewOrder: () => actions.selectSection('Pedidos'),
              onOpenDispatches: () => actions.selectSection('Despachos'),
              onScan: actions.openScanner,
              canEditOrders: true,
              canAdvanceOrders: true,
              onEditOrder: (order) => actions.selectSection('Pedidos'),
              onAdvanceOrder: actions.advanceOrder,
            ),
          ),
          const ItemNavegacionRol(
            title: 'Inventario para venta',
            destination: NavigationDestination(
              icon: Icon(Icons.menu_book),
              label: 'Inventario',
            ),
            screen: InventoryScreen(
              canManageInventory: false,
              canEditStockOnly: false,
              showPrices: true,
              showFullDetails: true,
              canScanInventory: true,
            ),
          ),
          const ItemNavegacionRol(
            title: 'Combos',
            destination: NavigationDestination(
              icon: Icon(Icons.grid_view),
              label: 'Combos',
            ),
            screen: CombosScreen(canEditCombos: false),
          ),
          const ItemNavegacionRol(
            title: 'Pedidos',
            destination: NavigationDestination(
              icon: Icon(Icons.shopping_cart),
              label: 'Pedidos',
            ),
            screen: OrdersScreen(
              canCreateOrders: true,
              canEditOrders: true,
              canAdvanceOrders: true,
            ),
          ),
          const ItemNavegacionRol(
            title: 'Despachos',
            destination: NavigationDestination(
              icon: Icon(Icons.local_shipping),
              label: 'Despachos',
            ),
            screen: DispatchesScreen(canDispatchOrders: false),
          ),
        ];
      },
    );
  }
}

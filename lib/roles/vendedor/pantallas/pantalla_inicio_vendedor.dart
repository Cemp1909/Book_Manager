import 'package:flutter/material.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/combos/pantallas/pantalla_combos.dart';
import 'package:book_manager/caracteristicas/estadisticas/pantallas/pantalla_estadisticas.dart';
import 'package:book_manager/caracteristicas/inicio/componentes/base_inicio_rol.dart';
import 'package:book_manager/caracteristicas/inicio/pantallas/pantalla_biblioteca_inicio.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_inventario.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/pantalla_despachos.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/pantalla_pedidos.dart';
import 'package:book_manager/caracteristicas/perfil/pantallas/pantalla_perfil.dart';

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
            title: 'Inicio',
            destination: const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            screen: LibraryHomeScreen(
              onOpenLibrary: () => actions.selectSection('Biblioteca'),
              onOpenBook: (book) =>
                  actions.openBookInSection('Biblioteca', book),
              onOpenStats: () => actions.selectSection('Estadisticas'),
            ),
          ),
          ItemNavegacionRol(
            title: 'Biblioteca',
            destination: const NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'Biblioteca',
            ),
            screen: InventoryScreen(
              canManageInventory: false,
              canEditStockOnly: false,
              showPrices: true,
              showFullDetails: true,
              canScanInventory: true,
              initialBookToOpen: actions.bookToOpen,
              initialBookOpenRequest: actions.bookOpenRequest,
            ),
          ),
          const ItemNavegacionRol(
            title: 'Estadisticas',
            destination: NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Estadísticas',
            ),
            screen: StatisticsScreen(),
          ),
          const ItemNavegacionRol(
            title: 'Combos',
            destination: NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Combos',
            ),
            screen: CombosScreen(canEditCombos: false),
          ),
          const ItemNavegacionRol(
            title: 'Pedidos',
            destination: NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
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
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Despachos',
            ),
            screen: DispatchesScreen(canDispatchOrders: false),
          ),
          ItemNavegacionRol(
            title: 'Perfil',
            destination: const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
            screen: ProfileScreen(user: user, onLogout: onLogout),
          ),
        ];
      },
    );
  }
}

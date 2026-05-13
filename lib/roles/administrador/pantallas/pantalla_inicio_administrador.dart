import 'package:flutter/material.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/colegios/pantallas/pantalla_colegios.dart';
import 'package:book_manager/caracteristicas/combos/pantallas/pantalla_combos.dart';
import 'package:book_manager/caracteristicas/devoluciones/pantallas/pantalla_devoluciones.dart';
import 'package:book_manager/caracteristicas/estadisticas/pantallas/pantalla_estadisticas.dart';
import 'package:book_manager/caracteristicas/historial/pantallas/pantalla_historial.dart';
import 'package:book_manager/caracteristicas/inicio/componentes/base_inicio_rol.dart';
import 'package:book_manager/caracteristicas/inicio/pantallas/pantalla_biblioteca_inicio.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_agregar_libro.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_inventario.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/pantalla_despachos.dart';
import 'package:book_manager/caracteristicas/pedidos/pantallas/pantalla_pedidos.dart';
import 'package:book_manager/caracteristicas/perfil/pantallas/pantalla_perfil.dart';
import 'package:book_manager/caracteristicas/reportes/pantallas/pantalla_reportes.dart';
import 'package:book_manager/caracteristicas/usuarios/pantallas/pantalla_usuarios.dart';

class PantallaInicioAdministrador extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const PantallaInicioAdministrador({
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
              onAddBook: () => actions.selectSection('Agregar'),
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
              canManageInventory: true,
              canEditStockOnly: false,
              showPrices: true,
              showFullDetails: true,
              canScanInventory: true,
              initialBookToOpen: actions.bookToOpen,
              initialBookOpenRequest: actions.bookOpenRequest,
              currentUser: user,
            ),
          ),
          ItemNavegacionRol(
            title: 'Agregar',
            destination: const NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: 'Agregar',
            ),
            screen: AddBookScreen(
              persistOnSave: true,
              embedded: true,
              currentUser: user,
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
            title: 'Colegios',
            destination: NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Colegios',
            ),
            screen: SchoolsScreen(canManageSchools: true),
          ),
          const ItemNavegacionRol(
            title: 'Reportes',
            destination: NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Reportes',
            ),
            screen: ReportsScreen(),
          ),
          const ItemNavegacionRol(
            title: 'Combos',
            destination: NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Combos',
            ),
            screen: CombosScreen(canEditCombos: true),
          ),
          ItemNavegacionRol(
            title: 'Pedidos',
            destination: const NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Pedidos',
            ),
            screen: OrdersScreen(
              canCreateOrders: true,
              canEditOrders: true,
              canAdvanceOrders: true,
              currentUser: user,
            ),
          ),
          ItemNavegacionRol(
            title: 'Despachos',
            destination: const NavigationDestination(
              icon: Icon(Icons.local_shipping_outlined),
              selectedIcon: Icon(Icons.local_shipping),
              label: 'Despachos',
            ),
            screen:
                DispatchesScreen(canDispatchOrders: true, currentUser: user),
          ),
          const ItemNavegacionRol(
            title: 'Devoluciones',
            destination: NavigationDestination(
              icon: Icon(Icons.assignment_return_outlined),
              selectedIcon: Icon(Icons.assignment_return),
              label: 'Devoluciones',
            ),
            screen: ReturnsScreen(),
          ),
          ItemNavegacionRol(
            title: 'Usuarios',
            destination: const NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'Usuarios',
            ),
            screen: UsersScreen(currentUser: user),
          ),
          const ItemNavegacionRol(
            title: 'Historial',
            destination: NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Historial',
            ),
            screen: ActivityHistoryScreen(),
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

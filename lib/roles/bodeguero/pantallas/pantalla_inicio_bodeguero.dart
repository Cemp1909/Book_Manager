import 'package:flutter/material.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/inicio/componentes/base_inicio_rol.dart';
import 'package:book_manager/caracteristicas/inventario/pantallas/pantalla_inventario.dart';

class PantallaInicioBodeguero extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const PantallaInicioBodeguero({
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
        return const [
          ItemNavegacionRol(
            title: 'Inventario de bodega',
            destination: NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
            screen: InventoryScreen(
              canManageInventory: false,
              canEditStockOnly: true,
              showPrices: false,
              showFullDetails: false,
              canScanInventory: true,
            ),
          ),
        ];
      },
    );
  }
}

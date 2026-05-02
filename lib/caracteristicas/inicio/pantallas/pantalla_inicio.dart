import 'package:flutter/material.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/roles/administrador/pantallas/pantalla_inicio_administrador.dart';
import 'package:book_manager/roles/bodeguero/pantallas/pantalla_inicio_bodeguero.dart';
import 'package:book_manager/roles/vendedor/pantallas/pantalla_inicio_vendedor.dart';

class HomeScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return switch (user.role) {
      AppRole.administrator => PantallaInicioAdministrador(
          user: user,
          onLogout: onLogout,
        ),
      AppRole.seller => PantallaInicioVendedor(
          user: user,
          onLogout: onLogout,
        ),
      AppRole.warehouse => PantallaInicioBodeguero(
          user: user,
          onLogout: onLogout,
        ),
    };
  }
}

import 'package:flutter/material.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';
import 'package:book_manager/caracteristicas/autenticacion/pantallas/pantalla_autenticacion.dart';
import 'package:book_manager/caracteristicas/autenticacion/servicios/servicio_autenticacion.dart';
import 'package:book_manager/caracteristicas/inicio/pantallas/pantalla_inicio.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<AppUser?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthService.instance.currentUser();
  }

  void _refreshSession() {
    setState(() {
      _sessionFuture = AuthService.instance.currentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return AuthScreen(onAuthenticated: _refreshSession);
        }

        return HomeScreen(user: user, onLogout: _refreshSession);
      },
    );
  }
}

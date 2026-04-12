import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthResult {
  final bool success;
  final String message;

  const AuthResult({required this.success, required this.message});
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _nameKey = 'auth_user_name';
  static const _emailKey = 'auth_user_email';
  static const _roleKey = 'auth_user_role';
  static const _passwordKey = 'auth_user_password';
  static const _loggedInKey = 'auth_logged_in';

  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    final email = prefs.getString(_emailKey);

    if (!isLoggedIn || email == null) return null;

    return AppUser(
      name: prefs.getString(_nameKey) ?? 'Administrador',
      email: email,
      role: prefs.getString(_roleKey) ?? 'Administrador',
    );
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString(_emailKey);

    if (storedEmail != null &&
        storedEmail.toLowerCase() == email.toLowerCase()) {
      return const AuthResult(
        success: false,
        message: 'Ya existe una cuenta con ese correo.',
      );
    }

    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_roleKey, 'Administrador');
    await prefs.setString(_passwordKey, password);
    await prefs.setBool(_loggedInKey, true);

    return const AuthResult(success: true, message: 'Cuenta creada.');
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final loginEmail = email.trim().isEmpty ? 'demo@local.test' : email.trim();

    await prefs.setString(_nameKey, 'Usuario de prueba');
    await prefs.setString(_emailKey, loginEmail);
    await prefs.setString(_roleKey, 'Administrador');
    await prefs.setBool(_loggedInKey, true);

    return const AuthResult(success: true, message: 'Bienvenido.');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }

  Future<void> resetLocalAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_passwordKey);
    await prefs.setBool(_loggedInKey, false);
  }
}

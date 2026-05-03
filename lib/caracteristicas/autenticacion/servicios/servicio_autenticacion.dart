import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';

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
  static const _usersKey = 'auth_users';

  Future<AppUser?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
    final email = prefs.getString(_emailKey);

    if (!isLoggedIn || email == null) return null;

    final account = _findAccount(accounts, email);
    return account?.user;
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    final result = await createUser(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    if (!result.success) return result;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    await prefs.setBool(_loggedInKey, true);

    return const AuthResult(success: true, message: 'Cuenta creada.');
  }

  Future<AuthResult> createUser({
    required String name,
    required String email,
    required String password,
    required AppRole role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    if (_findAccount(accounts, email) != null) {
      return const AuthResult(
        success: false,
        message: 'Ya existe una cuenta con ese correo.',
      );
    }

    accounts.add(
      _StoredAccount(
        user: AppUser(name: name, email: email, role: role),
        password: password,
      ),
    );
    await _saveAccounts(prefs, accounts);

    return const AuthResult(success: true, message: 'Cuenta creada.');
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);

    if (accounts.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Primero crea una cuenta para este dispositivo.',
      );
    }

    final loginEmail = email.trim();
    final account = _findAccount(accounts, loginEmail);
    if (account == null || account.password != password) {
      return const AuthResult(
        success: false,
        message: 'Correo o clave incorrectos.',
      );
    }

    await prefs.setString(_emailKey, account.user.email);
    await prefs.setBool(_loggedInKey, true);

    return const AuthResult(success: true, message: 'Bienvenido.');
  }

  Future<List<AppUser>> users() async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    return accounts.map((account) => account.user).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<AuthResult> updateUser({
    required String originalEmail,
    required String name,
    required String email,
    required AppRole role,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accounts = await _loadAccounts(prefs);
    final index = accounts.indexWhere(
      (account) =>
          account.user.email.toLowerCase() == originalEmail.toLowerCase(),
    );

    if (index == -1) {
      return const AuthResult(
        success: false,
        message: 'No se encontró el usuario.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final emailInUse = accounts.any(
      (account) =>
          account.user.email.toLowerCase() == normalizedEmail &&
          account.user.email.toLowerCase() != originalEmail.toLowerCase(),
    );
    if (emailInUse) {
      return const AuthResult(
        success: false,
        message: 'Ya existe una cuenta con ese correo.',
      );
    }

    final currentAccount = accounts[index];
    final updatedAccount = _StoredAccount(
      user: AppUser(name: name, email: email, role: role),
      password:
          password?.isNotEmpty == true ? password! : currentAccount.password,
    );
    final nextAccounts = [...accounts]..[index] = updatedAccount;

    if (!_hasAdministrator(nextAccounts)) {
      return const AuthResult(
        success: false,
        message: 'Debe existir al menos un administrador.',
      );
    }

    await _saveAccounts(prefs, nextAccounts);

    final currentEmail = prefs.getString(_emailKey);
    if (currentEmail?.toLowerCase() == originalEmail.toLowerCase()) {
      await prefs.setString(_emailKey, updatedAccount.user.email);
    }

    return const AuthResult(success: true, message: 'Usuario actualizado.');
  }

  Future<AuthResult> deleteUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final currentEmail = prefs.getString(_emailKey);

    if (currentEmail?.toLowerCase() == email.toLowerCase()) {
      return const AuthResult(
        success: false,
        message: 'No puedes eliminar el usuario con sesión activa.',
      );
    }

    final accounts = await _loadAccounts(prefs);
    final nextAccounts = accounts
        .where(
          (account) => account.user.email.toLowerCase() != email.toLowerCase(),
        )
        .toList();

    if (nextAccounts.length == accounts.length) {
      return const AuthResult(
        success: false,
        message: 'No se encontró el usuario.',
      );
    }

    if (!_hasAdministrator(nextAccounts)) {
      return const AuthResult(
        success: false,
        message: 'Debe existir al menos un administrador.',
      );
    }

    await _saveAccounts(prefs, nextAccounts);
    return const AuthResult(success: true, message: 'Usuario eliminado.');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, false);
  }

  Future<void> resetLocalAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usersKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_passwordKey);
    await prefs.setBool(_loggedInKey, false);
  }

  Future<List<_StoredAccount>> _loadAccounts(SharedPreferences prefs) async {
    final usersJson = prefs.getString(_usersKey);
    if (usersJson != null) {
      final decoded = jsonDecode(usersJson);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map(
                (map) => _StoredAccount.fromMap(Map<String, dynamic>.from(map)))
            .toList();
      }
    }

    final legacyEmail = prefs.getString(_emailKey);
    final legacyPassword = prefs.getString(_passwordKey);
    if (legacyEmail == null || legacyPassword == null) return [];

    final legacyAccount = _StoredAccount(
      user: AppUser(
        name: prefs.getString(_nameKey) ?? 'Administrador',
        email: legacyEmail,
        role: appRoleFromStorage(prefs.getString(_roleKey)),
      ),
      password: legacyPassword,
    );
    await _saveAccounts(prefs, [legacyAccount]);
    return [legacyAccount];
  }

  Future<void> _saveAccounts(
    SharedPreferences prefs,
    List<_StoredAccount> accounts,
  ) async {
    await prefs.setString(
      _usersKey,
      jsonEncode(accounts.map((account) => account.toMap()).toList()),
    );
  }

  _StoredAccount? _findAccount(List<_StoredAccount> accounts, String email) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in accounts) {
      if (account.user.email.toLowerCase() == normalizedEmail) {
        return account;
      }
    }
    return null;
  }

  bool _hasAdministrator(List<_StoredAccount> accounts) {
    return accounts.any((account) => account.user.isAdministrator);
  }
}

class _StoredAccount {
  final AppUser user;
  final String password;

  const _StoredAccount({
    required this.user,
    required this.password,
  });

  Map<String, String> toMap() {
    return {
      ...user.toMap(),
      'password': password,
    };
  }

  factory _StoredAccount.fromMap(Map<String, dynamic> map) {
    return _StoredAccount(
      user: AppUser.fromMap(
        map.map((key, value) => MapEntry(key, value?.toString() ?? '')),
      ),
      password: map['password']?.toString() ?? '',
    );
  }
}

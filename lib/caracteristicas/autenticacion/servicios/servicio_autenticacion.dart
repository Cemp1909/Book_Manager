import 'package:book_manager/caracteristicas/autenticacion/servicios/servicio_correo_verificacion.dart';
import 'package:book_manager/datos/api/api_client.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? verificationCode;
  final bool authenticated;

  const AuthResult({
    required this.success,
    required this.message,
    this.verificationCode,
    this.authenticated = false,
  });
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final ApiClient _api = ApiClient.instance;
  String? _currentEmail;
  bool _isLoggedIn = false;

  Future<AppUser?> currentUser() async {
    if (!_isLoggedIn || _currentEmail == null) return null;

    final account = await _findAccount(_currentEmail!);
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
      requireApproval: true,
    );
    if (!result.success) return result;

    if (result.authenticated) {
      _currentEmail = email.trim().toLowerCase();
      _isLoggedIn = true;
    }

    return result;
  }

  Future<AuthResult> createUser({
    required String name,
    required String email,
    required String password,
    required AppRole role,
    bool requireApproval = false,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final accounts = await _loadAccounts();
    if (_findAccountInList(accounts, normalizedEmail) != null) {
      return const AuthResult(
        success: false,
        message: 'Ya existe una cuenta con ese correo.',
      );
    }

    final isFirstAccount = accounts.isEmpty;
    final status = isFirstAccount || !requireApproval
        ? AccountStatus.active
        : AccountStatus.pendingEmail;
    final verificationCode = status == AccountStatus.pendingEmail
        ? _generateVerificationCode(email)
        : null;

    if (verificationCode != null) {
      try {
        await VerificationEmailService.instance.sendCode(
          email: normalizedEmail,
          code: verificationCode,
        );
      } on ApiException catch (error) {
        return AuthResult(success: false, message: error.message);
      } catch (_) {
        return const AuthResult(
          success: false,
          message: 'No se pudo enviar el codigo de verificacion.',
        );
      }
    }

    try {
      final roleId = await _ensureRole(role);
      final response = await _api.post('/api/v1/usuarios', {
        'nombre': name.trim(),
        'correo': normalizedEmail,
        'contrasena': password,
        'estado': _statusToStorage(status, verificationCode),
      });
      final userId = _intValue(response['id']);
      if (userId != null) {
        await _api.post('/api/v1/usuario-rol', {
          'id_usuario': userId,
          'id_rol': roleId,
        });
      }
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'No se pudo guardar el usuario en Oracle.',
      );
    }

    if (status == AccountStatus.pendingEmail) {
      return const AuthResult(
        success: true,
        message:
            'Te enviamos un codigo al correo. Verificalo y espera aprobacion del administrador.',
      );
    }

    return const AuthResult(
      success: true,
      message: 'Cuenta creada.',
      authenticated: true,
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final accounts = await _loadAccounts();

    if (accounts.isEmpty) {
      return const AuthResult(
        success: false,
        message: 'Primero crea una cuenta.',
      );
    }

    final loginEmail = email.trim().toLowerCase();
    final account = _findAccountInList(accounts, loginEmail);
    if (account == null || account.password != password) {
      return const AuthResult(
        success: false,
        message: 'Correo o clave incorrectos.',
      );
    }
    if (account.user.status != AccountStatus.active) {
      return AuthResult(
        success: false,
        message: switch (account.user.status) {
          AccountStatus.pendingEmail =>
            'Debes verificar el codigo enviado al correo.',
          AccountStatus.pendingApproval =>
            'Tu cuenta esta pendiente de aprobacion del administrador.',
          AccountStatus.rejected =>
            'Tu solicitud fue rechazada por el administrador.',
          AccountStatus.active => 'Cuenta activa.',
        },
      );
    }

    _currentEmail = account.user.email;
    _isLoggedIn = true;

    return const AuthResult(
      success: true,
      message: 'Bienvenido.',
      authenticated: true,
    );
  }

  Future<AuthResult> verifyEmail({
    required String email,
    required String code,
  }) async {
    final account = await _findAccount(email);
    if (account == null) {
      return const AuthResult(
        success: false,
        message: 'No se encontro la cuenta.',
      );
    }

    if (account.verificationCode != code.trim()) {
      return const AuthResult(
        success: false,
        message: 'Codigo incorrecto.',
      );
    }

    await _updateUserStatus(
      account.id,
      AccountStatus.pendingApproval,
    );

    return const AuthResult(
      success: true,
      message: 'Correo verificado. Ahora espera aprobacion del administrador.',
    );
  }

  Future<AuthResult> requestPasswordReset({
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final account = await _findAccount(normalizedEmail);
    if (account == null) {
      return const AuthResult(
        success: false,
        message: 'No se encontro una cuenta con ese correo.',
      );
    }

    final verificationCode = _generateVerificationCode(normalizedEmail);
    try {
      await VerificationEmailService.instance.sendCode(
        email: normalizedEmail,
        code: verificationCode,
      );
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'No se pudo enviar el codigo de recuperacion.',
      );
    }

    return AuthResult(
      success: true,
      message: 'Enviamos un codigo de recuperacion al correo.',
      verificationCode: verificationCode,
    );
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String password,
  }) async {
    if (password.length < 6) {
      return const AuthResult(
        success: false,
        message: 'La clave debe tener minimo 6 caracteres.',
      );
    }

    final account = await _findAccount(email);
    if (account == null) {
      return const AuthResult(
        success: false,
        message: 'No se encontro la cuenta.',
      );
    }

    try {
      await _api.put('/api/v1/usuarios/${account.id}', {
        'nombre': account.user.name,
        'correo': account.user.email,
        'contrasena': password,
        'estado':
            _statusToStorage(account.user.status, account.verificationCode),
      });
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'No se pudo actualizar la clave.',
      );
    }

    return const AuthResult(
      success: true,
      message: 'Clave actualizada. Ya puedes iniciar sesion.',
    );
  }

  Future<AuthResult> approveUser(String email) async {
    return _setUserStatus(email, AccountStatus.active, 'Usuario aprobado.');
  }

  Future<AuthResult> rejectUser(String email) async {
    return _setUserStatus(email, AccountStatus.rejected, 'Usuario rechazado.');
  }

  Future<List<AppUser>> users() async {
    final accounts = await _loadAccounts();
    return accounts.map((account) => account.user).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<int> pendingApprovalCount() async {
    final accounts = await _loadAccounts();
    return accounts
        .where(
            (account) => account.user.status == AccountStatus.pendingApproval)
        .length;
  }

  Future<AuthResult> updateUser({
    required String originalEmail,
    required String name,
    required String email,
    required AppRole role,
    String? password,
  }) async {
    final accounts = await _loadAccounts();
    final account = _findAccountInList(accounts, originalEmail);

    if (account == null) {
      return const AuthResult(
        success: false,
        message: 'No se encontro el usuario.',
      );
    }

    final normalizedEmail = email.trim().toLowerCase();
    final emailInUse = accounts.any(
      (item) =>
          item.user.email.toLowerCase() == normalizedEmail &&
          item.user.email.toLowerCase() != originalEmail.toLowerCase(),
    );
    if (emailInUse) {
      return const AuthResult(
        success: false,
        message: 'Ya existe una cuenta con ese correo.',
      );
    }

    final nextAccounts = [
      for (final item in accounts)
        item.id == account.id
            ? account.copyWith(
                user: AppUser(
                  name: name.trim(),
                  email: normalizedEmail,
                  role: role,
                  status: account.user.status,
                ),
                password: password?.isNotEmpty == true ? password : null,
              )
            : item,
    ];
    if (!_hasAdministrator(nextAccounts)) {
      return const AuthResult(
        success: false,
        message: 'Debe existir al menos un administrador.',
      );
    }

    try {
      await _api.put('/api/v1/usuarios/${account.id}', {
        'nombre': name.trim(),
        'correo': normalizedEmail,
        'contrasena':
            password?.isNotEmpty == true ? password : account.password,
        'estado':
            _statusToStorage(account.user.status, account.verificationCode),
      });
      await _replaceUserRole(account.id, role);
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'No se pudo actualizar el usuario.',
      );
    }

    if (_currentEmail?.toLowerCase() == originalEmail.toLowerCase()) {
      _currentEmail = normalizedEmail;
    }

    return const AuthResult(success: true, message: 'Usuario actualizado.');
  }

  Future<AuthResult> deleteUser(String email) async {
    if (_currentEmail?.toLowerCase() == email.toLowerCase()) {
      return const AuthResult(
        success: false,
        message: 'No puedes eliminar el usuario con sesion activa.',
      );
    }

    final accounts = await _loadAccounts();
    final account = _findAccountInList(accounts, email);
    if (account == null) {
      return const AuthResult(
        success: false,
        message: 'No se encontro el usuario.',
      );
    }

    final nextAccounts =
        accounts.where((item) => item.id != account.id).toList();
    if (!_hasAdministrator(nextAccounts)) {
      return const AuthResult(
        success: false,
        message: 'Debe existir al menos un administrador.',
      );
    }

    try {
      await _deleteUserRoles(account.id);
      await _api.delete('/api/v1/usuarios/${account.id}');
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'No se pudo eliminar el usuario.',
      );
    }

    return const AuthResult(success: true, message: 'Usuario eliminado.');
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _currentEmail = null;
  }

  Future<void> resetLocalAccount() async {
    await logout();
  }

  Future<List<_StoredAccount>> _loadAccounts() async {
    late final List<Map<String, dynamic>> users;
    late final List<Map<String, dynamic>> roles;
    late final List<Map<String, dynamic>> userRoles;

    users = await _rows('/api/v1/usuarios?limit=500');
    roles = await _rows('/api/v1/roles?limit=100');
    userRoles = await _rows('/api/v1/usuario-rol?limit=1000');

    final roleNameById = {
      for (final role in roles)
        _stringValue(role, 'ID_ROL', 'id_rol'):
            _stringValue(role, 'NOMBRE', 'nombre'),
    };
    final roleByUserId = <String, AppRole>{};
    for (final userRole in userRoles) {
      final userId = _stringValue(userRole, 'ID_USUARIO', 'id_usuario');
      final roleId = _stringValue(userRole, 'ID_ROL', 'id_rol');
      roleByUserId[userId] = appRoleFromStorage(roleNameById[roleId]);
    }

    return users.map((user) {
      final id = _intValue(user['ID_USUARIO'] ?? user['id_usuario']) ?? 0;
      final parsedStatus = _parseStatus(_stringValue(user, 'ESTADO', 'estado'));
      return _StoredAccount(
        id: id,
        user: AppUser(
          name: _stringValue(user, 'NOMBRE', 'nombre'),
          email: _stringValue(user, 'CORREO', 'correo').toLowerCase(),
          role: roleByUserId[id.toString()] ?? AppRole.administrator,
          status: parsedStatus.status,
        ),
        password: _stringValue(user, 'CONTRASENA', 'contrasena'),
        verificationCode: parsedStatus.verificationCode,
      );
    }).toList();
  }

  Future<_StoredAccount?> _findAccount(String email) async {
    final accounts = await _loadAccounts();
    return _findAccountInList(accounts, email);
  }

  _StoredAccount? _findAccountInList(
    List<_StoredAccount> accounts,
    String email,
  ) {
    final normalizedEmail = email.trim().toLowerCase();
    for (final account in accounts) {
      if (account.user.email.toLowerCase() == normalizedEmail) {
        return account;
      }
    }
    return null;
  }

  bool _hasAdministrator(List<_StoredAccount> accounts) {
    return accounts.any(
      (account) =>
          account.user.isAdministrator &&
          account.user.status == AccountStatus.active,
    );
  }

  Future<AuthResult> _setUserStatus(
    String email,
    AccountStatus status,
    String message,
  ) async {
    final accounts = await _loadAccounts();
    final account = _findAccountInList(accounts, email);
    if (account == null) {
      return const AuthResult(
        success: false,
        message: 'No se encontro el usuario.',
      );
    }

    final nextAccounts = [
      for (final item in accounts)
        item.id == account.id
            ? item.copyWith(user: item.user.copyWith(status: status))
            : item,
    ];
    if (!_hasAdministrator(nextAccounts)) {
      return const AuthResult(
        success: false,
        message: 'Debe existir al menos un administrador activo.',
      );
    }

    await _updateUserStatus(account.id, status);
    return AuthResult(success: true, message: message);
  }

  Future<void> _updateUserStatus(int userId, AccountStatus status) async {
    final accounts = await _loadAccounts();
    final account = accounts.firstWhere((item) => item.id == userId);
    await _api.put('/api/v1/usuarios/$userId', {
      'nombre': account.user.name,
      'correo': account.user.email,
      'contrasena': account.password,
      'estado': _statusToStorage(status, null),
    });
  }

  Future<int> _ensureRole(AppRole role) async {
    final roles = await _rows('/api/v1/roles?limit=100');
    final existing = roles.firstWhere(
      (item) =>
          _stringValue(item, 'NOMBRE', 'nombre').toLowerCase() ==
          role.label.toLowerCase(),
      orElse: () => const {},
    );
    final existingId = _intValue(existing['ID_ROL'] ?? existing['id_rol']);
    if (existingId != null) return existingId;

    final response = await _api.post('/api/v1/roles', {
      'nombre': role.label,
      'descripcion': 'Rol ${role.label}',
    });
    return _intValue(response['id']) ?? 0;
  }

  Future<void> _replaceUserRole(int userId, AppRole role) async {
    await _deleteUserRoles(userId);
    await _api.post('/api/v1/usuario-rol', {
      'id_usuario': userId,
      'id_rol': await _ensureRole(role),
    });
  }

  Future<void> _deleteUserRoles(int userId) async {
    final userRoles = await _rows('/api/v1/usuario-rol?limit=1000');
    final matches = userRoles.where(
      (item) =>
          _stringValue(item, 'ID_USUARIO', 'id_usuario') == userId.toString(),
    );
    for (final match in matches) {
      final id = _intValue(match['ID_USUARIO_ROL'] ?? match['id_usuario_rol']);
      if (id != null) await _api.delete('/api/v1/usuario-rol/$id');
    }
  }

  Future<List<Map<String, dynamic>>> _rows(String path) async {
    final response = await _api.get(path);
    final data = response['data'];
    if (data is! List) return const [];
    return data.whereType<Map>().map((row) {
      return Map<String, dynamic>.from(row);
    }).toList();
  }

  String _stringValue(
    Map<String, dynamic> map,
    String upperKey,
    String lowerKey,
  ) {
    return (map[upperKey] ?? map[lowerKey] ?? '').toString();
  }

  int? _intValue(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _statusToStorage(AccountStatus status, String? verificationCode) {
    if (verificationCode?.isNotEmpty == true) {
      return '${status.name}:$verificationCode';
    }
    return status.name;
  }

  _ParsedStatus _parseStatus(String value) {
    final parts = value.split(':');
    return _ParsedStatus(
      accountStatusFromStorage(parts.first),
      parts.length > 1 ? parts[1] : null,
    );
  }

  String _generateVerificationCode(String email) {
    final seed = DateTime.now().millisecondsSinceEpoch +
        email.trim().toLowerCase().codeUnits.fold(0, (sum, item) => sum + item);
    return (seed % 900000 + 100000).toString();
  }
}

class _ParsedStatus {
  final AccountStatus status;
  final String? verificationCode;

  const _ParsedStatus(this.status, this.verificationCode);
}

class _StoredAccount {
  final int id;
  final AppUser user;
  final String password;
  final String? verificationCode;

  const _StoredAccount({
    required this.id,
    required this.user,
    required this.password,
    this.verificationCode,
  });

  _StoredAccount copyWith({
    AppUser? user,
    String? password,
    String? verificationCode,
  }) {
    return _StoredAccount(
      id: id,
      user: user ?? this.user,
      password: password ?? this.password,
      verificationCode: verificationCode ?? this.verificationCode,
    );
  }
}

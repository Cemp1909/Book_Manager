enum AppRole {
  administrator,
  seller,
  warehouse,
}

AppRole appRoleFromStorage(String? value) {
  return AppRole.values.firstWhere(
    (role) => role.label.toLowerCase() == value?.toLowerCase(),
    orElse: () => AppRole.administrator,
  );
}

extension AppRoleX on AppRole {
  String get label {
    return switch (this) {
      AppRole.administrator => 'Administrador',
      AppRole.seller => 'Vendedor',
      AppRole.warehouse => 'Bodeguero',
    };
  }
}

class AppUser {
  final String name;
  final String email;
  final AppRole role;

  const AppUser({
    required this.name,
    required this.email,
    this.role = AppRole.administrator,
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.label,
    };
  }

  factory AppUser.fromMap(Map<String, String> map) {
    return AppUser(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: appRoleFromStorage(map['role']),
    );
  }

  bool get isAdministrator => role == AppRole.administrator;
  bool get isSeller => role == AppRole.seller;
  bool get isWarehouse => role == AppRole.warehouse;

  bool get canViewDashboard => !isWarehouse;
  bool get canManageSettings => isAdministrator;
  bool get canViewInventory => true;
  bool get canManageInventory => isAdministrator;
  bool get canEditStockOnly => isWarehouse;
  bool get canSeePrices => !isWarehouse;
  bool get canSeeInventoryDetails => !isWarehouse;
  bool get canCreateOrders => isAdministrator || isSeller;
  bool get canEditOrders => isAdministrator || isSeller;
  bool get canAdvanceOrders => isAdministrator;
  bool get canViewOrders => !isWarehouse;
  bool get canViewDispatches => !isWarehouse;
  bool get canDispatchOrders => isAdministrator;
  bool get canViewCombos => !isWarehouse;
  bool get canEditCombos => isAdministrator;
  bool get canUseScanner => true;
}

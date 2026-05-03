enum ActivityType {
  inventory,
  orders,
  users,
  settings,
}

extension ActivityTypeX on ActivityType {
  String get label {
    return switch (this) {
      ActivityType.inventory => 'Inventario',
      ActivityType.orders => 'Pedidos',
      ActivityType.users => 'Usuarios',
      ActivityType.settings => 'Configuracion',
    };
  }
}

ActivityType activityTypeFromStorage(String? value) {
  return ActivityType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => ActivityType.inventory,
  );
}

class AppActivity {
  final String id;
  final ActivityType type;
  final String title;
  final String detail;
  final String actorName;
  final String actorRole;
  final DateTime createdAt;

  const AppActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.actorName,
    required this.actorRole,
    required this.createdAt,
  });

  Map<String, String> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'detail': detail,
      'actorName': actorName,
      'actorRole': actorRole,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppActivity.fromMap(Map<String, dynamic> map) {
    return AppActivity(
      id: map['id']?.toString() ?? '',
      type: activityTypeFromStorage(map['type']?.toString()),
      title: map['title']?.toString() ?? '',
      detail: map['detail']?.toString() ?? '',
      actorName: map['actorName']?.toString() ?? 'Sistema',
      actorRole: map['actorRole']?.toString() ?? 'Operacion',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

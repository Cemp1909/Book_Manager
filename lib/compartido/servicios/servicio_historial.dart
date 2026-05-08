import 'package:flutter/material.dart';
import 'package:book_manager/datos/api/api_client.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';

class ActivityLogService extends ChangeNotifier {
  ActivityLogService._();

  static final ActivityLogService instance = ActivityLogService._();
  static const _maxActivities = 120;

  final List<AppActivity> _activities = [];
  final ApiClient _api = ApiClient.instance;
  bool _loaded = false;

  List<AppActivity> get activities => List.unmodifiable(_activities);

  List<AppActivity> activitiesForEntity({
    required String entityType,
    required String entityId,
  }) {
    return _activities
        .where(
          (activity) =>
              activity.entityType == entityType &&
              activity.entityId == entityId,
        )
        .toList();
  }

  Future<void> load() async {
    if (_loaded) return;

    try {
      final response = await _api.get('/api/v1/historial-actividad?limit=120');
      final data = response['data'];
      if (data is List) {
        _activities
          ..clear()
          ..addAll(data.whereType<Map>().map((row) {
            return _activityFromOracle(Map<String, dynamic>.from(row));
          }));
      }
    } catch (_) {
      _activities.clear();
    }

    _activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _loaded = true;
    notifyListeners();
  }

  Future<void> record({
    required ActivityType type,
    required String title,
    required String detail,
    AppUser? actor,
    String entityType = '',
    String entityId = '',
    String entityName = '',
  }) async {
    await load();

    final now = DateTime.now();
    _activities.insert(
      0,
      AppActivity(
        id: now.microsecondsSinceEpoch.toString(),
        type: type,
        title: title,
        detail: detail,
        actorName: actor?.name ?? 'Sistema',
        actorRole: actor?.role.label ?? 'Operacion',
        createdAt: now,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
      ),
    );

    if (_activities.length > _maxActivities) {
      _activities.removeRange(_maxActivities, _activities.length);
    }

    try {
      await _api.post('/api/v1/historial-actividad', {
        'tipo': type.name,
        'titulo': title,
        'detalle': detail,
        'id_usuario': null,
        'nombre_usuario': actor?.name ?? 'Sistema',
        'rol_usuario': actor?.role.label ?? 'Operacion',
        'fecha_hora': now.toIso8601String(),
        'tipo_entidad': entityType,
        'id_entidad': entityId,
        'nombre_entidad': entityName,
      });
    } catch (_) {}
    notifyListeners();
  }

  Future<void> clear() async {
    await load();
    _activities.clear();
    notifyListeners();
  }

  AppActivity _activityFromOracle(Map<String, dynamic> map) {
    return AppActivity(
      id: (map['ID_ACTIVIDAD'] ?? map['id_actividad'] ?? '').toString(),
      type: activityTypeFromStorage((map['TIPO'] ?? map['tipo'])?.toString()),
      title: (map['TITULO'] ?? map['titulo'] ?? '').toString(),
      detail: (map['DETALLE'] ?? map['detalle'] ?? '').toString(),
      actorName: (map['NOMBRE_USUARIO'] ?? map['nombre_usuario'] ?? 'Sistema')
          .toString(),
      actorRole:
          (map['ROL_USUARIO'] ?? map['rol_usuario'] ?? 'Operacion').toString(),
      createdAt: DateTime.tryParse(
            (map['FECHA_HORA'] ?? map['fecha_hora'] ?? '').toString(),
          ) ??
          DateTime.now(),
      entityType: (map['TIPO_ENTIDAD'] ?? map['tipo_entidad'] ?? '').toString(),
      entityId: (map['ID_ENTIDAD'] ?? map['id_entidad'] ?? '').toString(),
      entityName:
          (map['NOMBRE_ENTIDAD'] ?? map['nombre_entidad'] ?? '').toString(),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:book_manager/datos/modelos/actividad_app.dart';
import 'package:book_manager/datos/modelos/usuario_app.dart';

class ActivityLogService extends ChangeNotifier {
  ActivityLogService._();

  static final ActivityLogService instance = ActivityLogService._();
  static const _activitiesKey = 'activity_log_items';
  static const _maxActivities = 120;

  final List<AppActivity> _activities = [];
  bool _loaded = false;

  List<AppActivity> get activities => List.unmodifiable(_activities);

  Future<void> load() async {
    if (_loaded) return;

    final prefs = await SharedPreferences.getInstance();
    final rawActivities = prefs.getString(_activitiesKey);
    if (rawActivities != null) {
      final decoded = jsonDecode(rawActivities);
      if (decoded is List) {
        _activities
          ..clear()
          ..addAll(
            decoded
                .whereType<Map>()
                .map(
                  (map) => AppActivity.fromMap(
                    Map<String, dynamic>.from(map),
                  ),
                )
                .toList(),
          );
      }
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
      ),
    );

    if (_activities.length > _maxActivities) {
      _activities.removeRange(_maxActivities, _activities.length);
    }

    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    await load();
    _activities.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _activitiesKey,
      jsonEncode(_activities.map((activity) => activity.toMap()).toList()),
    );
  }
}

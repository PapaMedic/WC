import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FireMapCachedResponse {
  final Map<String, dynamic> json;
  final DateTime cachedAt;

  const FireMapCachedResponse({
    required this.json,
    required this.cachedAt,
  });
}

class FireMapCacheService {
  static const String _incidentsKey = 'fire_map_cached_incidents';
  static const String _incidentsCachedAtKey = 'fire_map_cached_incidents_at';

  Future<void> saveIncidents(Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_incidentsKey, jsonEncode(json));
    await prefs.setString(
      _incidentsCachedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<FireMapCachedResponse?> loadIncidents() async {
    final prefs = await SharedPreferences.getInstance();
    return _load(prefs, _incidentsKey, _incidentsCachedAtKey);
  }

  FireMapCachedResponse? _load(
    SharedPreferences prefs,
    String jsonKey,
    String cachedAtKey,
  ) {
    final rawJson = prefs.getString(jsonKey);
    final cachedAt = DateTime.tryParse(prefs.getString(cachedAtKey) ?? '');
    if (rawJson == null || cachedAt == null) return null;

    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return null;

    return FireMapCachedResponse(
      json: decoded.map((key, value) => MapEntry(key.toString(), value)),
      cachedAt: cachedAt,
    );
  }
}

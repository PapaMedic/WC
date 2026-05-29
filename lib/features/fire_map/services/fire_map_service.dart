import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:wildland_companion_v2/features/fire_map/models/fire_incident.dart';
import 'package:wildland_companion_v2/features/fire_map/services/fire_map_cache_service.dart';

class FireMapResult<T> {
  final T data;
  final bool isCached;
  final DateTime lastUpdated;
  final String? message;

  const FireMapResult({
    required this.data,
    required this.isCached,
    required this.lastUpdated,
    this.message,
  });
}

class FireMapService {
  FireMapService({
    http.Client? client,
    FireMapCacheService? cacheService,
  })  : _client = client ?? http.Client(),
        _cacheService = cacheService ?? FireMapCacheService();

  static const String _incidentLayerUrl =
      'https://services5.arcgis.com/b7cJ4YYc9GM63RSz/arcgis/rest/services/'
      'USA_Active_Wildfires___Current_Incidents/FeatureServer/1/query';
  static const String _incidentFallbackLayerUrl =
      'https://services9.arcgis.com/RHVPKKiFTONKtxq3/arcgis/rest/services/'
      'USA_Wildfires_v1/FeatureServer/0/query';
  final http.Client _client;
  final FireMapCacheService _cacheService;

  Future<FireMapResult<List<FireIncident>>> fetchActiveIncidents() async {
    try {
      final json = await _getJson(_incidentLayerUrl, const {
        'f': 'json',
        'where': '1=1',
        'outFields': '*',
        'returnGeometry': 'true',
        'outSR': '4326',
        'resultRecordCount': '2000',
      });
      var incidents = _parseIncidents(json);
      var cacheJson = json;
      String? message;

      if (incidents.isEmpty) {
        _debugLog(
          'Requested active wildfire layer returned 0 valid incidents. '
          'Trying current NIFC/WFIGS fallback layer.',
        );
        final fallbackJson = await _getJson(_incidentFallbackLayerUrl, const {
          'f': 'json',
          'where': '1=1',
          'outFields': '*',
          'returnGeometry': 'true',
          'outSR': '4326',
          'resultRecordCount': '2000',
        });
        final fallbackIncidents = _parseIncidents(fallbackJson);
        if (fallbackIncidents.isNotEmpty) {
          incidents = fallbackIncidents;
          cacheJson = fallbackJson;
          message =
              'Primary ArcGIS active fire layer returned no features. Showing current NIFC/WFIGS feed.';
        }
      }

      await _cacheService.saveIncidents(cacheJson);
      return FireMapResult(
        data: incidents,
        isCached: false,
        lastUpdated: DateTime.now(),
        message: message,
      );
    } catch (error) {
      final cached = await _cacheService.loadIncidents();
      if (cached == null) rethrow;
      return FireMapResult(
        data: _parseIncidents(cached.json),
        isCached: true,
        lastUpdated: cached.cachedAt,
        message: 'Live incident feed unavailable. Showing cached data. $error',
      );
    }
  }

  Future<Map<String, dynamic>> _getJson(
    String baseUrl,
    Map<String, String> queryParameters,
  ) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
    _debugLog('ArcGIS request URL: $uri');
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 18));
    _debugLog('ArcGIS HTTP status: ${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FireMapException(
        'ArcGIS request failed: ${response.statusCode} ${response.reasonPhrase}',
      );
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (error) {
      _debugLog(
        'ArcGIS JSON parse failed. First 500 chars: '
        '${_firstResponseChars(response.body)}',
      );
      throw FireMapException('Unable to parse ArcGIS JSON response: $error');
    }

    if (decoded is! Map) {
      _debugLog(
        'ArcGIS response was not a JSON object. First 500 chars: '
        '${_firstResponseChars(response.body)}',
      );
      throw const FireMapException('Invalid ArcGIS response.');
    }
    final json = decoded.map((key, value) => MapEntry(key.toString(), value));
    if (json['error'] != null) {
      throw FireMapException(_formatArcGisError(json['error']));
    }
    return json;
  }

  List<FireIncident> _parseIncidents(Map<String, dynamic> json) {
    final features = json['features'];
    if (features is! List) {
      _debugLog('Fetched 0 ArcGIS features');
      _debugLog('Parsed 0 valid fire incidents');
      return [];
    }

    _debugLog('Fetched ${features.length} ArcGIS features');

    final incidents = features
        .whereType<Map>()
        .map((feature) => FireIncident.fromArcGisFeature(
              feature.map((key, value) => MapEntry(key.toString(), value)),
            ))
        .where((incident) => incident.hasValidCoordinates)
        .toList();

    _debugLog('Parsed ${incidents.length} valid fire incidents');
    return incidents;
  }

  String _firstResponseChars(String value) {
    return value.length <= 500 ? value : value.substring(0, 500);
  }

  String _formatArcGisError(Object? error) {
    if (error is Map) {
      final message = error['message'] ?? 'Unknown ArcGIS error';
      final details = error['details'];
      if (details is List && details.isNotEmpty) {
        return 'ArcGIS error: $message (${details.join('; ')})';
      }
      return 'ArcGIS error: $message';
    }
    return 'ArcGIS error: $error';
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint(message);
  }
}

class FireMapException implements Exception {
  final String message;

  const FireMapException(this.message);

  @override
  String toString() => message;
}

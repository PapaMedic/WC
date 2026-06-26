// Fire Map service layer for external data and caching.
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
      'https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/'
      'WFIGS_Incident_Locations_Current/FeatureServer/0/query';
  static const List<String> _incidentFields = [
    'OBJECTID',
    'IncidentName',
    'IncidentSize',
    'PercentContained',
    'IncidentTypeCategory',
    'FireDiscoveryDateTime',
    'ModifiedOnDateTime_dt',
    'UniqueFireIdentifier',
    'LocalIncidentIdentifier',
    'IrwinID',
    'POOState',
    'POOCounty',
    'POOCity',
    'POOJurisdictionalAgency',
    'FireCause',
    'FireCauseGeneral',
    'IncidentShortDescription',
    'ActiveFireCandidate',
    'FireOutDateTime',
    'ContainmentDateTime',
  ];
  static final String _incidentOutFields = _incidentFields.join(',');

  final http.Client _client;
  final FireMapCacheService _cacheService;

  Future<FireMapResult<List<FireIncident>>?> loadCachedIncidents() async {
    final cached = await _cacheService.loadIncidents();
    if (cached == null) return null;
    return FireMapResult(
      data: _parseIncidents(cached.json),
      isCached: true,
      lastUpdated: cached.cachedAt,
    );
  }

  Future<FireMapResult<List<FireIncident>>> fetchActiveIncidents() async {
    try {
      // ArcGIS expects outFields as a comma-separated query string, not a JSON
      // array. Keeping this explicit prevents schema errors from resurfacing.
      final json = await _getJson(_incidentLayerUrl, {
        'where': "IncidentTypeCategory IN ('WF','RX','CX')",
        'returnGeometry': 'true',
        'outSR': '4326',
        'f': 'json',
        'outFields': _incidentOutFields,
      });
      final incidents = _parseIncidents(json);

      if (incidents.isNotEmpty) {
        await _cacheService.saveIncidents(json);
      } else {
        _debugLog(
          'Live ArcGIS response parsed 0 valid incidents. Existing cache was not overwritten.',
        );
      }

      return FireMapResult(
        data: incidents,
        isCached: false,
        lastUpdated: DateTime.now(),
      );
    } on FireMapException catch (error) {
      if (kDebugMode && error.isInvalidOutFields) {
        try {
          // Development-only escape hatch for ArcGIS schema drift. Production
          // avoids broad field queries unless the verified schema works.
          _debugLog(
              'ArcGIS outFields schema fallback used: retrying with outFields=*');
          final json = await _getJson(_incidentLayerUrl, {
            'where': "IncidentTypeCategory IN ('WF','RX','CX')",
            'returnGeometry': 'true',
            'outSR': '4326',
            'f': 'json',
            'outFields': '*',
          });
          final incidents = _parseIncidents(json);

          if (incidents.isNotEmpty) {
            await _cacheService.saveIncidents(json);
          } else {
            _debugLog(
              'ArcGIS schema fallback parsed 0 valid incidents. Existing cache was not overwritten.',
            );
          }

          return FireMapResult(
            data: incidents,
            isCached: false,
            lastUpdated: DateTime.now(),
            message: 'ArcGIS schema fallback was used for the live feed.',
          );
        } catch (fallbackError) {
          return _loadCachedAfterFailure(fallbackError);
        }
      }

      return _loadCachedAfterFailure(error);
    } catch (error) {
      return _loadCachedAfterFailure(error);
    }
  }

  Future<FireMapResult<List<FireIncident>>> _loadCachedAfterFailure(
    Object error,
  ) async {
    final cached = await _cacheService.loadIncidents();
    if (cached == null) throw error;
    return FireMapResult(
      data: _parseIncidents(cached.json),
      isCached: true,
      lastUpdated: cached.cachedAt,
      message: 'Live incident feed unavailable. Showing cached data. $error',
    );
  }

  Future<Map<String, dynamic>> _getJson(
    String baseUrl,
    Map<String, String> queryParameters,
  ) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParameters);
    _debugLog('ArcGIS request URL: ${_redactSensitiveQueryValues(uri)}');
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 18));
    _debugLog('ArcGIS HTTP status: ${response.statusCode}');

    Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (error) {
      _debugLog(
        'ArcGIS JSON parse failed. First 500 chars: '
        '${_firstResponseChars(response.body)}',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logArcGisFailure(
          statusCode: response.statusCode,
          uri: uri,
          outFields: queryParameters['outFields'] ?? '',
        );
      }
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
    final arcGisError = json['error'];
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logArcGisFailure(
        statusCode: response.statusCode,
        uri: uri,
        outFields: queryParameters['outFields'] ?? '',
        error: arcGisError,
      );
      throw FireMapException(
        'ArcGIS request failed: ${response.statusCode} ${response.reasonPhrase}',
        code: _arcGisErrorCode(arcGisError),
        arcGisMessage: _arcGisErrorMessage(arcGisError),
        details: _arcGisErrorDetails(arcGisError),
      );
    }

    if (arcGisError != null) {
      _logArcGisFailure(
        statusCode: response.statusCode,
        uri: uri,
        outFields: queryParameters['outFields'] ?? '',
        error: arcGisError,
      );
      throw FireMapException(
        _formatArcGisError(arcGisError),
        code: _arcGisErrorCode(arcGisError),
        arcGisMessage: _arcGisErrorMessage(arcGisError),
        details: _arcGisErrorDetails(arcGisError),
      );
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

  void _logArcGisFailure({
    required int statusCode,
    required Uri uri,
    required String outFields,
    Object? error,
  }) {
    _debugLog('ArcGIS request failed.');
    _debugLog('ArcGIS HTTP status: $statusCode');
    _debugLog('ArcGIS final request URI: ${_redactSensitiveQueryValues(uri)}');
    _debugLog('ArcGIS error code: ${_arcGisErrorCode(error) ?? '-'}');
    _debugLog('ArcGIS error message: ${_arcGisErrorMessage(error) ?? '-'}');
    _debugLog('ArcGIS error details: ${_arcGisErrorDetails(error).join('; ')}');
    _debugLog('ArcGIS outFields: $outFields');
  }

  Uri _redactSensitiveQueryValues(Uri uri) {
    if (uri.queryParameters.isEmpty) return uri;

    final redacted = <String, String>{};
    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.toLowerCase();
      redacted[entry.key] =
          key == 'token' || key == 'api_key' ? '<redacted>' : entry.value;
    }
    return uri.replace(queryParameters: redacted);
  }

  int? _arcGisErrorCode(Object? error) {
    if (error is! Map) return null;
    final code = error['code'];
    if (code is int) return code;
    if (code is num) return code.toInt();
    if (code is String) return int.tryParse(code);
    return null;
  }

  String? _arcGisErrorMessage(Object? error) {
    if (error is! Map) return null;
    return _toLogString(error['message']);
  }

  List<String> _arcGisErrorDetails(Object? error) {
    if (error is! Map) return const [];
    final details = error['details'];
    if (details is List) {
      return details
          .map(_toLogString)
          .whereType<String>()
          .where((detail) => detail.isNotEmpty)
          .toList();
    }
    final detail = _toLogString(details);
    return detail == null || detail.isEmpty ? const [] : [detail];
  }

  String? _toLogString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
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
  final int? code;
  final String? arcGisMessage;
  final List<String> details;

  const FireMapException(
    this.message, {
    this.code,
    this.arcGisMessage,
    this.details = const [],
  });

  bool get isInvalidOutFields {
    final combined = [
      message,
      if (arcGisMessage != null) arcGisMessage!,
      ...details,
    ].join(' ').toLowerCase();
    return combined.contains('outfields') && combined.contains('invalid');
  }

  @override
  String toString() => message;
}

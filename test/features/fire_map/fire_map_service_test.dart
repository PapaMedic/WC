// Tests covering fire map service test.
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wildland_companion_v2/features/fire_map/models/fire_incident.dart';
import 'package:wildland_companion_v2/features/fire_map/services/fire_map_cache_service.dart';
import 'package:wildland_companion_v2/features/fire_map/services/fire_map_service.dart';

void main() {
  group('FireIncident.fromArcGisFeature', () {
    test('parses a valid WFIGS feature', () {
      final incident = FireIncident.fromArcGisFeature(
        _feature(
          attributes: {
            'OBJECTID': 7,
            'IncidentName': 'Pine Ridge',
            'IncidentSize': '1234.5',
            'PercentContained': '42',
            'IncidentTypeCategory': 'WF',
            'FireDiscoveryDateTime': 1717000000000,
            'ModifiedOnDateTime_dt': '1717100000000',
            'UniqueFireIdentifier': '2024-AZABC-000123',
            'LocalIncidentIdentifier': '000123',
            'IrwinID': '{irwin-guid}',
            'POOJurisdictionalAgency': 'USFS',
            'IncidentShortDescription': 'Backing fire activity',
          },
          x: -111.25,
          y: 34.5,
        ),
      );

      expect(incident.id, '2024-AZABC-000123');
      expect(incident.irwinId, '{irwin-guid}');
      expect(incident.name, 'Pine Ridge');
      expect(incident.acres, 1234.5);
      expect(incident.containmentPercent, 42);
      expect(incident.incidentType, 'WF');
      expect(incident.modifiedDate,
          DateTime.fromMillisecondsSinceEpoch(1717100000000));
      expect(incident.jurisdiction, 'USFS');
      expect(incident.importantUpdates, 'Backing fire activity');
    });

    test('keeps null PercentContained null', () {
      final incident = FireIncident.fromArcGisFeature(
        _feature(
          attributes: {
            'IncidentName': 'Null Containment',
            'PercentContained': null,
            'UniqueFireIdentifier': 'uid',
          },
        ),
      );

      expect(incident.containmentPercent, isNull);
    });

    test('parses integer and double IncidentSize values', () {
      final intIncident = FireIncident.fromArcGisFeature(
        _feature(attributes: {'IncidentSize': 12}),
      );
      final doubleIncident = FireIncident.fromArcGisFeature(
        _feature(attributes: {'IncidentSize': 12.75}),
      );

      expect(intIncident.acres, 12);
      expect(doubleIncident.acres, 12.75);
    });

    test('reads longitude and latitude from geometry x and y', () {
      final incident = FireIncident.fromArcGisFeature(
        _feature(
            attributes: {'UniqueFireIdentifier': 'uid'}, x: -120.1, y: 45.2),
      );

      expect(incident.longitude, -120.1);
      expect(incident.latitude, 45.2);
    });

    test('uses LocalIncidentIdentifier as fallback and not IrwinID', () {
      final incident = FireIncident.fromArcGisFeature(
        _feature(
          attributes: {
            'LocalIncidentIdentifier': 'LOCAL-42',
            'IrwinID': 'IRWIN-42',
          },
        ),
      );

      expect(incident.id, 'LOCAL-42');
      expect(incident.irwinId, 'IRWIN-42');
    });
  });

  group('FireMapService.fetchActiveIncidents', () {
    test('sends verified WFIGS query parameters and caches successful data',
        () async {
      final cache = _FakeFireMapCacheService();
      final client = _QueueClient([
        http.Response(jsonEncode(_jsonWithFeature(name: 'Live Fire')), 200),
      ]);
      final service = FireMapService(client: client, cacheService: cache);

      final result = await service.fetchActiveIncidents();

      expect(result.isCached, isFalse);
      expect(result.data.single.name, 'Live Fire');
      expect(cache.savedJson?['features'], isA<List>());

      final request = client.requests.single;
      expect(request.queryParameters['where'],
          "IncidentTypeCategory IN ('WF','RX','CX')");
      expect(request.queryParameters['returnGeometry'], 'true');
      expect(request.queryParameters['outSR'], '4326');
      expect(request.queryParameters['f'], 'json');
      expect(request.queryParameters['outFields'], _expectedOutFields);
    });

    test('throws on ArcGIS JSON error response when no cache exists', () async {
      final service = FireMapService(
        client: _QueueClient([
          http.Response(
            jsonEncode({
              'error': {
                'code': 400,
                'message': 'Cannot perform query. Invalid query parameters.',
                'details': ["'where' parameter is invalid"],
              },
            }),
            200,
          ),
        ]),
        cacheService: _FakeFireMapCacheService(),
      );

      expect(service.fetchActiveIncidents, throwsA(isA<FireMapException>()));
    });

    test('retries once with outFields=* when ArcGIS rejects outFields',
        () async {
      final cache = _FakeFireMapCacheService();
      final client = _QueueClient([
        http.Response(jsonEncode(_invalidOutFieldsError), 200),
        http.Response(jsonEncode(_jsonWithFeature(name: 'Fallback Fire')), 200),
      ]);
      final service = FireMapService(client: client, cacheService: cache);

      final result = await service.fetchActiveIncidents();

      expect(result.isCached, isFalse);
      expect(result.data.single.name, 'Fallback Fire');
      expect(result.message, contains('schema fallback'));
      expect(client.requests, hasLength(2));
      expect(client.requests.first.queryParameters['outFields'],
          _expectedOutFields);
      expect(client.requests.last.queryParameters['outFields'], '*');
      expect(cache.savedJson?['features'], isA<List>());
    });

    test('replaces cache after a successful live response', () async {
      final cache = _FakeFireMapCacheService(
        cached: _cachedResponse(_jsonWithFeature(name: 'Old Fire')),
      );
      final service = FireMapService(
        client: _QueueClient([
          http.Response(jsonEncode(_jsonWithFeature(name: 'New Fire')), 200),
        ]),
        cacheService: cache,
      );

      final result = await service.fetchActiveIncidents();

      expect(result.isCached, isFalse);
      expect(result.data.single.name, 'New Fire');
      expect(
        (cache.savedJson!['features'] as List).single['attributes']
            ['IncidentName'],
        'New Fire',
      );
    });

    test('preserves previous cache after a failed request', () async {
      final oldJson = _jsonWithFeature(name: 'Cached Fire');
      final cache = _FakeFireMapCacheService(cached: _cachedResponse(oldJson));
      final service = FireMapService(
        client: _QueueClient([
          http.Response('service unavailable', 503),
        ]),
        cacheService: cache,
      );

      final result = await service.fetchActiveIncidents();

      expect(result.isCached, isTrue);
      expect(result.data.single.name, 'Cached Fire');
      expect(result.message, contains('Live incident feed unavailable'));
      expect(cache.savedJson, isNull);
    });
  });
}

const String _expectedOutFields =
    'OBJECTID,IncidentName,IncidentSize,PercentContained,IncidentTypeCategory,'
    'FireDiscoveryDateTime,ModifiedOnDateTime_dt,UniqueFireIdentifier,'
    'LocalIncidentIdentifier,IrwinID,POOState,POOCounty,POOCity,'
    'POOJurisdictionalAgency,FireCause,FireCauseGeneral,'
    'IncidentShortDescription,ActiveFireCandidate,FireOutDateTime,'
    'ContainmentDateTime';

const Map<String, Object> _invalidOutFieldsError = {
  'error': {
    'code': 400,
    'message': 'Cannot perform query. Invalid query parameters.',
    'details': ["'outFields' parameter is invalid"],
  },
};

Map<String, dynamic> _feature({
  Map<String, Object?> attributes = const {},
  double x = -110,
  double y = 35,
}) {
  return {
    'attributes': attributes,
    'geometry': {'x': x, 'y': y},
  };
}

Map<String, dynamic> _jsonWithFeature({required String name}) {
  return {
    'features': [
      _feature(
        attributes: {
          'OBJECTID': 1,
          'IncidentName': name,
          'IncidentSize': 10,
          'PercentContained': 20,
          'IncidentTypeCategory': 'WF',
          'UniqueFireIdentifier': '$name-uid',
          'ModifiedOnDateTime_dt': 1717100000000,
        },
      ),
    ],
  };
}

FireMapCachedResponse _cachedResponse(Map<String, dynamic> json) {
  return FireMapCachedResponse(
    json: json,
    cachedAt: DateTime.fromMillisecondsSinceEpoch(1717000000000),
  );
}

class _FakeFireMapCacheService extends FireMapCacheService {
  FireMapCachedResponse? cached;
  Map<String, dynamic>? savedJson;

  _FakeFireMapCacheService({this.cached});

  @override
  Future<FireMapCachedResponse?> loadIncidents() async => cached;

  @override
  Future<void> saveIncidents(Map<String, dynamic> json) async {
    savedJson = json;
    cached = FireMapCachedResponse(json: json, cachedAt: DateTime.now());
  }
}

class _QueueClient extends http.BaseClient {
  final List<http.Response> _responses;
  final List<Uri> requests = [];

  _QueueClient(this._responses);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request.url);
    if (_responses.isEmpty) {
      throw StateError('No queued HTTP response for ${request.url}');
    }

    final response = _responses.removeAt(0);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}

// Fire Map data model and serialization helpers.
class FireIncident {
  final String id;
  final String? irwinId;
  final String name;
  final double latitude;
  final double longitude;
  final double? acres;
  final double? containmentPercent;
  final DateTime? discoveryDate;
  final DateTime? modifiedDate;
  final DateTime? containmentDate;
  final DateTime? controlDate;
  final DateTime? finalFireReportApprovedDate;
  final String? jurisdiction;
  final String? agency;
  final String? incidentType;
  final String? status;
  final String? importantUpdates;
  final Map<String, dynamic> rawProperties;

  const FireIncident({
    required this.id,
    required this.irwinId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.acres,
    required this.containmentPercent,
    required this.discoveryDate,
    required this.modifiedDate,
    required this.containmentDate,
    required this.controlDate,
    required this.finalFireReportApprovedDate,
    required this.jurisdiction,
    required this.agency,
    required this.incidentType,
    required this.status,
    required this.importantUpdates,
    required this.rawProperties,
  });

  bool get hasValidCoordinates {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  bool get isRx {
    final type = (incidentType ?? '').trim().toUpperCase();
    final category = (rawProperties['IncidentTypeCategory'] ?? '')
        .toString()
        .trim()
        .toUpperCase();
    return type == 'RX' ||
        category == 'RX' ||
        type.contains('PRESCRIB') ||
        category.contains('PRESCRIB');
  }

  bool get isFlaggedInactive {
    final inactive = _firstPresent(rawProperties, const [
      'IsActive',
      'Active',
      'IsValid',
      'IncidentIsActive',
      'IsIncidentActive',
    ]);
    if (inactive is bool) return !inactive;
    if (inactive is num) return inactive == 0;
    if (inactive is String) {
      final normalized = inactive.trim().toLowerCase();
      return normalized == 'false' ||
          normalized == '0' ||
          normalized == 'inactive' ||
          normalized == 'no';
    }
    return false;
  }

  factory FireIncident.fromArcGisFeature(Map<String, dynamic> feature) {
    final attributes = _mapValue(feature['attributes']);
    final geometry = _mapValue(feature['geometry']);
    final x = _toDouble(geometry['x']);
    final y = _toDouble(geometry['y']);
    final uniqueFireIdentifier =
        _toStringValue(attributes['UniqueFireIdentifier']);
    final localIncidentIdentifier =
        _toStringValue(attributes['LocalIncidentIdentifier']);
    final irwinId = _toStringValue(attributes['IrwinID']);
    final objectId = _toStringValue(
      attributes['OBJECTID'],
    );
    final name = _toStringValue(
          _firstPresent(attributes, const [
            'IncidentName',
          ]),
        ) ??
        'Unnamed Fire';

    return FireIncident(
      id: uniqueFireIdentifier ??
          localIncidentIdentifier ??
          objectId ??
          '${name}_${x ?? 0}_${y ?? 0}',
      irwinId: irwinId,
      name: name,
      latitude: y ?? double.nan,
      longitude: x ?? double.nan,
      acres: _toDouble(
        _firstPresent(attributes, const [
          'IncidentSize',
        ]),
      ),
      containmentPercent: _toDouble(
        _firstPresent(attributes, const [
          'PercentContained',
        ]),
      ),
      discoveryDate: _toDate(
        _firstPresent(attributes, const [
          'FireDiscoveryDateTime',
        ]),
      ),
      modifiedDate: _toDate(
        _firstPresent(attributes, const [
          'ModifiedOnDateTime_dt',
        ]),
      ),
      containmentDate: _toDate(
        _firstPresent(attributes, const [
          'ContainmentDateTime',
        ]),
      ),
      controlDate: _toDate(
        _firstPresent(attributes, const [
          'FireOutDateTime',
        ]),
      ),
      finalFireReportApprovedDate: null,
      jurisdiction: _toStringValue(
        _firstPresent(attributes, const [
          'POOJurisdictionalAgency',
          'POOCounty',
          'POOState',
        ]),
      ),
      agency: _toStringValue(
        _firstPresent(attributes, const [
          'POOJurisdictionalAgency',
        ]),
      ),
      incidentType: _toStringValue(
        _firstPresent(attributes, const [
          'IncidentTypeCategory',
        ]),
      ),
      status: _toStringValue(
        _firstPresent(attributes, const [
          'ActiveFireCandidate',
          'FireOutDateTime',
        ]),
      ),
      importantUpdates: _toStringValue(
        _firstPresent(attributes, const [
          'IncidentShortDescription',
        ]),
      ),
      rawProperties: attributes,
    );
  }
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}

Object? _firstPresent(Map<String, dynamic> values, List<String> keys) {
  for (final key in keys) {
    if (values.containsKey(key) && values[key] != null) return values[key];
  }
  final lowerValues = {
    for (final entry in values.entries) entry.key.toLowerCase(): entry.value,
  };
  for (final key in keys) {
    final value = lowerValues[key.toLowerCase()];
    if (value != null) return value;
  }
  return null;
}

double? _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

String? _toStringValue(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

DateTime? _toDate(Object? value) {
  if (value == null) return null;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is double) {
    return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  }
  if (value is String) {
    final trimmed = value.trim();
    final millis = int.tryParse(trimmed);
    if (millis != null) return DateTime.fromMillisecondsSinceEpoch(millis);
    return DateTime.tryParse(trimmed);
  }
  return null;
}

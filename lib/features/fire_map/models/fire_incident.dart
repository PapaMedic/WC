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
    final irwinId = _toStringValue(
      _firstPresent(attributes, const [
        'IrwinID',
        'IRWINID',
        'irwinId',
        'UniqueFireIdentifier',
      ]),
    );
    final objectId = _toStringValue(
      _firstPresent(attributes, const ['OBJECTID', 'ObjectId', 'FID']),
    );
    final name = _toStringValue(
          _firstPresent(attributes, const [
            'IncidentName',
            'incidentName',
            'FireName',
            'Name',
          ]),
        ) ??
        'Unnamed Fire';

    return FireIncident(
      id: irwinId ?? objectId ?? '${name}_${x ?? 0}_${y ?? 0}',
      irwinId: irwinId,
      name: name,
      latitude: y ?? double.nan,
      longitude: x ?? double.nan,
      acres: _toDouble(
        _firstPresent(attributes, const [
          'DailyAcres',
          'GISAcres',
          'CalculatedAcres',
          'Acres',
        ]),
      ),
      containmentPercent: _toDouble(
        _firstPresent(attributes, const [
          'PercentContained',
          'PercentContainment',
          'ContainmentPercent',
        ]),
      ),
      discoveryDate: _toDate(
        _firstPresent(attributes, const [
          'FireDiscoveryDateTime',
          'DiscoveryDate',
          'StartDate',
          'attr_FireDiscoveryDateTime',
        ]),
      ),
      modifiedDate: _toDate(
        _firstPresent(attributes, const [
          'ModifiedOnDateTime',
          'ModifiedOn',
          'CurrentDateTime',
          'CreateDate',
        ]),
      ),
      containmentDate: _toDate(
        _firstPresent(attributes, const [
          'ContainmentDateTime',
          'ContainmentDate',
          'ContainedDate',
          'attr_ContainmentDateTime',
        ]),
      ),
      controlDate: _toDate(
        _firstPresent(attributes, const [
          'ControlDateTime',
          'ControlDate',
          'ControlledDate',
          'attr_ControlDateTime',
        ]),
      ),
      finalFireReportApprovedDate: _toDate(
        _firstPresent(attributes, const [
          'FFReportApprovedDate',
          'FinalFireReportApprovedDate',
          'FinalReportApprovedDate',
          'attr_FFReportApprovedDate',
        ]),
      ),
      jurisdiction: _toStringValue(
        _firstPresent(attributes, const [
          'POOProtectingUnit',
          'ProtectingUnit',
          'Jurisdiction',
          'UnitID',
          'attr_POOProtectingUnit',
          'attr_POOJurisdictionalAgency',
        ]),
      ),
      agency: _toStringValue(
        _firstPresent(attributes, const [
          'POOProtectingAgency',
          'Agency',
          'InitialResponseAcres',
          'attr_POOProtectingAgency',
          'attr_FFReportApprovedByUnit',
        ]),
      ),
      incidentType: _toStringValue(
        _firstPresent(attributes, const [
          'IncidentTypeCategory',
          'IncidentTypeKind',
          'IncidentType',
          'attr_IncidentTypeCategory',
          'poly_FeatureCategory',
        ]),
      ),
      status: _toStringValue(
        _firstPresent(attributes, const [
          'IncidentStatus',
          'FireStatus',
          'FeatureStatus',
          'attr_FireOutDateTime',
          'poly_FeatureStatus',
        ]),
      ),
      importantUpdates: _toStringValue(
        _firstPresent(attributes, const [
          'IncidentShortDescription',
          'StrategicDecisionPublishText',
          'ICS209ReportStatus',
          'Remarks',
          'Comments',
          'attr_IncidentShortDescription',
          'attr_StrategicDecisionPublishText',
          'attr_FireBehaviorGeneral',
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
  if (value is String) return double.tryParse(value);
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
  if (value is String) return DateTime.tryParse(value);
  return null;
}

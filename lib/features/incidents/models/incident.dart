// Incidents data model and serialization helpers.
class Incident {
  static const statusActive = 'active';
  static const statusClosed = 'closed';
  static const statusDeletedArchived = 'deletedArchived';

  final String id;
  final String incidentName;
  final String incidentNumber;
  final String resourceOrderNumber;
  final String financialCode;
  final String status;
  final bool isSelected;
  final DateTime createdAt;
  final String? source;
  final String? sourceIrwinId;
  final String? sourceStatus;
  final String? acres;
  final String? containmentPercent;
  final String? jurisdiction;
  final String? agency;
  final String? notes;

  Incident({
    required this.id,
    required this.incidentName,
    required this.incidentNumber,
    required this.resourceOrderNumber,
    required this.financialCode,
    this.status = statusActive,
    this.isSelected = false,
    required this.createdAt,
    this.source,
    this.sourceIrwinId,
    this.sourceStatus,
    this.acres,
    this.containmentPercent,
    this.jurisdiction,
    this.agency,
    this.notes,
  });

  bool get isActive => _normalizedStatus == statusActive;
  bool get isClosed => _normalizedStatus == statusClosed;
  bool get isDeletedArchived => _normalizedStatus == statusDeletedArchived;

  String get displayStatus {
    switch (_normalizedStatus) {
      case statusActive:
        return 'Active';
      case statusClosed:
        return 'Closed';
      case statusDeletedArchived:
        return 'Deleted / Archived';
      default:
        return status;
    }
  }

  String get _normalizedStatus {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return statusActive;
      case 'closed':
        return statusClosed;
      case 'deletedarchived':
      case 'deleted_archived':
      case 'deleted archived':
        return statusDeletedArchived;
      default:
        return status.trim();
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'incidentName': incidentName,
        'incidentNumber': incidentNumber,
        'resourceOrderNumber': resourceOrderNumber,
        'financialCode': financialCode,
        'status': status,
        'isSelected': isSelected,
        'createdAt': createdAt.toIso8601String(),
        'source': source,
        'sourceIrwinId': sourceIrwinId,
        'sourceStatus': sourceStatus,
        'acres': acres,
        'containmentPercent': containmentPercent,
        'jurisdiction': jurisdiction,
        'agency': agency,
        'notes': notes,
      };

  factory Incident.fromJson(Map<String, dynamic> json) {
    final rawIncidentNumber = json['incidentNumber'] ?? '';
    final rawSourceIrwinId = json['sourceIrwinId'];
    final migratedIrwinId = _looksLikeIrwinId(rawIncidentNumber) &&
            (rawSourceIrwinId == null || rawSourceIrwinId.toString().isEmpty)
        ? rawIncidentNumber
        : rawSourceIrwinId;
    final migratedIncidentNumber =
        migratedIrwinId == rawIncidentNumber ? '' : rawIncidentNumber;

    return Incident(
      id: json['id'] ?? '',
      incidentName: json['incidentName'] ?? '',
      incidentNumber: migratedIncidentNumber,
      resourceOrderNumber: json['resourceOrderNumber'] ?? '',
      financialCode: json['financialCode'] ?? '',
      status: json['status'] ?? 'Active',
      isSelected: json['isSelected'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      source: json['source'],
      sourceIrwinId: migratedIrwinId,
      sourceStatus: json['sourceStatus'],
      acres: json['acres'],
      containmentPercent: json['containmentPercent'],
      jurisdiction: json['jurisdiction'],
      agency: json['agency'],
      notes: json['notes'],
    );
  }

  Incident copyWith({
    String? incidentName,
    String? incidentNumber,
    String? resourceOrderNumber,
    String? financialCode,
    String? status,
    bool? isSelected,
    String? source,
    String? sourceIrwinId,
    String? sourceStatus,
    String? acres,
    String? containmentPercent,
    String? jurisdiction,
    String? agency,
    String? notes,
  }) {
    return Incident(
      id: id,
      incidentName: incidentName ?? this.incidentName,
      incidentNumber: incidentNumber ?? this.incidentNumber,
      resourceOrderNumber: resourceOrderNumber ?? this.resourceOrderNumber,
      financialCode: financialCode ?? this.financialCode,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt,
      source: source ?? this.source,
      sourceIrwinId: sourceIrwinId ?? this.sourceIrwinId,
      sourceStatus: sourceStatus ?? this.sourceStatus,
      acres: acres ?? this.acres,
      containmentPercent: containmentPercent ?? this.containmentPercent,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      agency: agency ?? this.agency,
      notes: notes ?? this.notes,
    );
  }

  static bool _looksLikeIrwinId(Object? value) {
    final text = value?.toString().trim() ?? '';
    return RegExp(
      r'^\{?[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\}?$',
    ).hasMatch(text);
  }
}

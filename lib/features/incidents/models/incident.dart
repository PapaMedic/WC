class Incident {
  final String id;
  final String incidentName;
  final String incidentNumber;
  final String resourceOrderNumber;
  final String financialCode;
  final String status;
  final bool isSelected;
  final DateTime createdAt;

  Incident({
    required this.id,
    required this.incidentName,
    required this.incidentNumber,
    required this.resourceOrderNumber,
    required this.financialCode,
    this.status = 'Active',
    this.isSelected = false,
    required this.createdAt,
  });

  bool get isActive => status == 'Active';
  bool get isClosed => status == 'Closed';

  Map<String, dynamic> toJson() => {
        'id': id,
        'incidentName': incidentName,
        'incidentNumber': incidentNumber,
        'resourceOrderNumber': resourceOrderNumber,
        'financialCode': financialCode,
        'status': status,
        'isSelected': isSelected,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id'] ?? '',
      incidentName: json['incidentName'] ?? '',
      incidentNumber: json['incidentNumber'] ?? '',
      resourceOrderNumber: json['resourceOrderNumber'] ?? '',
      financialCode: json['financialCode'] ?? '',
      status: json['status'] ?? 'Active',
      isSelected: json['isSelected'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Incident copyWith({
    String? status,
    bool? isSelected,
  }) {
    return Incident(
      id: id,
      incidentName: incidentName,
      incidentNumber: incidentNumber,
      resourceOrderNumber: resourceOrderNumber,
      financialCode: financialCode,
      status: status ?? this.status,
      isSelected: isSelected ?? this.isSelected,
      createdAt: createdAt,
    );
  }
}
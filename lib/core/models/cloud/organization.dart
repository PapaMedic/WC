import 'package:cloud_firestore/cloud_firestore.dart';

class Organization {
  final String organizationId;
  final String workspaceId;
  final String name;
  final String organizationType;
  final String agency;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final int seatLimit;
  final int activeSeatCount;

  const Organization({
    required this.organizationId,
    required this.workspaceId,
    required this.name,
    required this.organizationType,
    this.agency = '',
    required this.createdAt,
    required this.createdBy,
    this.isActive = true,
    this.subscriptionPlan = 'organization',
    this.subscriptionStatus = 'trial',
    this.seatLimit = 0,
    this.activeSeatCount = 0,
  });

  Map<String, dynamic> toFirestore() => {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
        'name': name,
        'organizationType': organizationType,
        'agency': agency,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        'isActive': isActive,
        'subscriptionPlan': subscriptionPlan,
        'subscriptionStatus': subscriptionStatus,
        'seatLimit': seatLimit,
        'activeSeatCount': activeSeatCount,
      };

  factory Organization.fromFirestore(Map<String, dynamic> data) {
    return Organization(
      organizationId: data['organizationId'] ?? '',
      workspaceId: data['workspaceId'] ?? '',
      name: data['name'] ?? 'Organization',
      organizationType: data['organizationType'] ?? 'other',
      agency: data['agency'] ?? '',
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      createdBy: data['createdBy'] ?? '',
      isActive: data['isActive'] ?? true,
      subscriptionPlan: data['subscriptionPlan'] ?? 'organization',
      subscriptionStatus: data['subscriptionStatus'] ?? 'trial',
      seatLimit: (data['seatLimit'] as num?)?.toInt() ?? 0,
      activeSeatCount: (data['activeSeatCount'] as num?)?.toInt() ?? 0,
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

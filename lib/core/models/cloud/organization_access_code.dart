import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationAccessCode {
  final String codeHash;
  final String organizationId;
  final String workspaceId;
  final String label;
  final String defaultRole;
  final bool isActive;
  final bool requiresApproval;
  final DateTime? expiresAt;
  final int? maxUses;
  final int useCount;
  final String createdBy;
  final DateTime createdAt;

  const OrganizationAccessCode({
    required this.codeHash,
    required this.organizationId,
    required this.workspaceId,
    required this.label,
    this.defaultRole = 'member',
    this.isActive = true,
    this.requiresApproval = true,
    this.expiresAt,
    this.maxUses,
    this.useCount = 0,
    required this.createdBy,
    required this.createdAt,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get hasUsesRemaining => maxUses == null || useCount < maxUses!;

  bool get canBeUsed => isActive && !isExpired && hasUsesRemaining;

  Map<String, dynamic> toFirestore() => {
        'organizationId': organizationId,
        'workspaceId': workspaceId,
        'label': label,
        'defaultRole': defaultRole,
        'isActive': isActive,
        'requiresApproval': requiresApproval,
        'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt!),
        'maxUses': maxUses,
        'useCount': useCount,
        'createdBy': createdBy,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory OrganizationAccessCode.fromFirestore(
    String codeHash,
    Map<String, dynamic> data,
  ) {
    return OrganizationAccessCode(
      codeHash: codeHash,
      organizationId: data['organizationId'] ?? '',
      workspaceId: data['workspaceId'] ?? '',
      label: data['label'] ?? 'Access code',
      defaultRole: data['defaultRole'] ?? 'member',
      isActive: data['isActive'] ?? true,
      requiresApproval: data['requiresApproval'] ?? true,
      expiresAt: _readDate(data['expiresAt']),
      maxUses: (data['maxUses'] as num?)?.toInt(),
      useCount: (data['useCount'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

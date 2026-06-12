import 'package:cloud_firestore/cloud_firestore.dart';

enum WorkspaceType {
  personal,
  organization,
}

extension WorkspaceTypeX on WorkspaceType {
  String get value => switch (this) {
        WorkspaceType.personal => 'personal',
        WorkspaceType.organization => 'organization',
      };

  static WorkspaceType fromValue(String? value) {
    return value == WorkspaceType.organization.value
        ? WorkspaceType.organization
        : WorkspaceType.personal;
  }
}

class Workspace {
  final String workspaceId;
  final WorkspaceType type;
  final String ownerUid;
  final String? organizationId;
  final String name;
  final DateTime createdAt;
  final bool isActive;

  const Workspace({
    required this.workspaceId,
    required this.type,
    required this.ownerUid,
    this.organizationId,
    required this.name,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toFirestore() => {
        'workspaceId': workspaceId,
        'type': type.value,
        'ownerUid': ownerUid,
        'organizationId': organizationId,
        'name': name,
        'createdAt': Timestamp.fromDate(createdAt),
        'isActive': isActive,
      };

  factory Workspace.fromFirestore(Map<String, dynamic> data) {
    return Workspace(
      workspaceId: data['workspaceId'] ?? '',
      type: WorkspaceTypeX.fromValue(data['type']),
      ownerUid: data['ownerUid'] ?? '',
      organizationId: data['organizationId'],
      name: data['name'] ?? 'Workspace',
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

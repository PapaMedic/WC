import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';

class AppUser {
  final String uid;
  final String displayName;
  final String email;
  final String accountType;
  final String activeWorkspaceId;
  final WorkspaceType activeWorkspaceType;
  final String personalWorkspaceId;
  final List<String> organizationIds;
  final Map<String, String> roleByOrganization;
  final String subscriptionPlan;
  final String subscriptionStatus;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.accountType,
    required this.activeWorkspaceId,
    required this.activeWorkspaceType,
    required this.personalWorkspaceId,
    this.organizationIds = const [],
    this.roleByOrganization = const {},
    this.subscriptionPlan = 'free',
    this.subscriptionStatus = 'none',
    this.isActive = true,
    required this.createdAt,
    this.lastLoginAt,
  });

  bool get hasProfile => activeWorkspaceId.isNotEmpty;
  bool get isSolo => organizationIds.isEmpty;
  bool get canViewFinance {
    if (activeWorkspaceType == WorkspaceType.personal) return true;
    return _activeOrganizationRoleAllows({'finance', 'admin', 'owner'});
  }

  bool get canViewAdmin {
    if (activeWorkspaceType == WorkspaceType.personal) return false;
    return _activeOrganizationRoleAllows({'admin', 'owner'});
  }

  String roleForOrganization(String organizationId) {
    return roleByOrganization[organizationId] ?? 'member';
  }

  bool _activeOrganizationRoleAllows(Set<String> roles) {
    for (final organizationId in organizationIds) {
      final role = roleForOrganization(organizationId);
      if (roles.contains(role)) return true;
    }
    return false;
  }

  Map<String, dynamic> toFirestore() => {
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'accountType': accountType,
        'activeWorkspaceId': activeWorkspaceId,
        'activeWorkspaceType': activeWorkspaceType.value,
        'personalWorkspaceId': personalWorkspaceId,
        'organizationIds': organizationIds,
        'roleByOrganization': roleByOrganization,
        'subscriptionPlan': subscriptionPlan,
        'subscriptionStatus': subscriptionStatus,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
        'lastLoginAt':
            lastLoginAt == null ? null : Timestamp.fromDate(lastLoginAt!),
      };

  factory AppUser.fromFirestore(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      accountType: data['accountType'] ?? 'solo',
      activeWorkspaceId: data['activeWorkspaceId'] ?? '',
      activeWorkspaceType:
          WorkspaceTypeX.fromValue(data['activeWorkspaceType']),
      personalWorkspaceId: data['personalWorkspaceId'] ?? '',
      organizationIds: List<String>.from(data['organizationIds'] ?? const []),
      roleByOrganization: Map<String, String>.from(
        data['roleByOrganization'] ?? const {},
      ),
      subscriptionPlan: data['subscriptionPlan'] ?? 'free',
      subscriptionStatus: data['subscriptionStatus'] ?? 'none',
      isActive: data['isActive'] ?? true,
      createdAt: _readDate(data['createdAt']) ?? DateTime.now(),
      lastLoginAt: _readDate(data['lastLoginAt']),
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

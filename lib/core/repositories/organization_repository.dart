import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/models/cloud/organization.dart';
import 'package:wildland_companion_v2/core/models/cloud/organization_access_code.dart';
import 'package:wildland_companion_v2/core/models/cloud/organization_join_request.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';

class OrganizationJoinResult {
  final bool joined;
  final bool pendingApproval;
  final String message;
  final String? workspaceId;

  const OrganizationJoinResult({
    required this.joined,
    required this.pendingApproval,
    required this.message,
    this.workspaceId,
  });
}

class OrganizationRepository {
  final FirebaseFirestore _firestore;

  OrganizationRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static String normalizeCode(String code) {
    return code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  static String hashAccessCode(String code) {
    final normalized = normalizeCode(code);
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  Future<Organization?> getOrganization(String organizationId) async {
    final snapshot =
        await _firestore.collection('organizations').doc(organizationId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return Organization.fromFirestore(data);
  }

  Future<List<Organization>> getOrganizations(List<String> ids) async {
    final organizations = <Organization>[];
    for (final id in ids) {
      final organization = await getOrganization(id);
      if (organization != null) organizations.add(organization);
    }
    return organizations;
  }

  Future<OrganizationAccessCode?> getAccessCode(String enteredCode) async {
    final codeHash = hashAccessCode(enteredCode);
    final snapshot = await _firestore
        .collection('organizationAccessCodes')
        .doc(codeHash)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return OrganizationAccessCode.fromFirestore(codeHash, data);
  }

  Future<OrganizationJoinResult> joinWithCode({
    required AppUser user,
    required String enteredCode,
    bool switchWorkspace = true,
  }) async {
    final accessCode = await getAccessCode(enteredCode);
    if (accessCode == null || !accessCode.canBeUsed) {
      return const OrganizationJoinResult(
        joined: false,
        pendingApproval: false,
        message: 'Organization access code is invalid or expired.',
      );
    }

    if (user.organizationIds.contains(accessCode.organizationId)) {
      return OrganizationJoinResult(
        joined: true,
        pendingApproval: false,
        workspaceId: accessCode.workspaceId,
        message: 'You already belong to this organization.',
      );
    }

    if (accessCode.requiresApproval) {
      await _createJoinRequest(user: user, accessCode: accessCode);
      return const OrganizationJoinResult(
        joined: false,
        pendingApproval: true,
        message:
            'Request sent. An organization admin must approve your access.',
      );
    }

    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(user.uid);
      final codeRef = _firestore
          .collection('organizationAccessCodes')
          .doc(accessCode.codeHash);
      final orgRef =
          _firestore.collection('organizations').doc(accessCode.organizationId);

      transaction.set(
        userRef,
        {
          'accountType': 'hybrid',
          'organizationIds': FieldValue.arrayUnion([accessCode.organizationId]),
          'roleByOrganization.${accessCode.organizationId}':
              accessCode.defaultRole,
          if (switchWorkspace) ...{
            'activeWorkspaceId': accessCode.workspaceId,
            'activeWorkspaceType': WorkspaceType.organization.value,
          },
        },
        SetOptions(merge: true),
      );
      transaction.update(codeRef, {'useCount': FieldValue.increment(1)});
      transaction.set(
        orgRef,
        {'activeSeatCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    });

    return OrganizationJoinResult(
      joined: true,
      pendingApproval: false,
      workspaceId: accessCode.workspaceId,
      message: 'Organization joined.',
    );
  }

  Future<void> _createJoinRequest({
    required AppUser user,
    required OrganizationAccessCode accessCode,
  }) async {
    final requestRef = _firestore
        .collection('organizations')
        .doc(accessCode.organizationId)
        .collection('joinRequests')
        .doc(user.uid);

    final request = OrganizationJoinRequest(
      requestId: requestRef.id,
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      requestedRole: accessCode.defaultRole,
      requestedAt: DateTime.now(),
    );

    await requestRef.set(request.toFirestore(), SetOptions(merge: true));
  }

  Future<List<OrganizationJoinRequest>> getPendingJoinRequests(
    String organizationId,
  ) async {
    final snapshot = await _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('joinRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => OrganizationJoinRequest.fromFirestore(doc.data()))
        .toList();
  }

  Future<void> approveJoinRequest({
    required String organizationId,
    required String requestId,
    required String reviewedBy,
    required String workspaceId,
    required String requestedRole,
  }) async {
    final requestRef = _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('joinRequests')
        .doc(requestId);
    final requestSnapshot = await requestRef.get();
    final requestData = requestSnapshot.data();
    if (requestData == null) return;
    final request = OrganizationJoinRequest.fromFirestore(requestData);

    await _firestore.runTransaction((transaction) async {
      transaction.set(
        _firestore.collection('users').doc(request.uid),
        {
          'accountType': 'hybrid',
          'organizationIds': FieldValue.arrayUnion([organizationId]),
          'roleByOrganization.$organizationId': requestedRole,
        },
        SetOptions(merge: true),
      );
      transaction.set(
        requestRef,
        {
          'status': 'approved',
          'reviewedBy': reviewedBy,
          'reviewedAt': Timestamp.now(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> denyJoinRequest({
    required String organizationId,
    required String requestId,
    required String reviewedBy,
  }) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('joinRequests')
        .doc(requestId)
        .set(
      {
        'status': 'denied',
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
      },
      SetOptions(merge: true),
    );
  }
}

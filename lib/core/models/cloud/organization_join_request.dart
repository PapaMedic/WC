import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationJoinRequest {
  final String requestId;
  final String uid;
  final String displayName;
  final String email;
  final String requestedRole;
  final String status;
  final DateTime requestedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  const OrganizationJoinRequest({
    required this.requestId,
    required this.uid,
    required this.displayName,
    required this.email,
    this.requestedRole = 'member',
    this.status = 'pending',
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  Map<String, dynamic> toFirestore() => {
        'requestId': requestId,
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'requestedRole': requestedRole,
        'status': status,
        'requestedAt': Timestamp.fromDate(requestedAt),
        'reviewedBy': reviewedBy,
        'reviewedAt':
            reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
      };

  factory OrganizationJoinRequest.fromFirestore(Map<String, dynamic> data) {
    return OrganizationJoinRequest(
      requestId: data['requestId'] ?? '',
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      requestedRole: data['requestedRole'] ?? 'member',
      status: data['status'] ?? 'pending',
      requestedAt: _readDate(data['requestedAt']) ?? DateTime.now(),
      reviewedBy: data['reviewedBy'],
      reviewedAt: _readDate(data['reviewedAt']),
    );
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

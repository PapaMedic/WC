import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> userRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Stream<AppUser?> watchUser(String uid) {
    return userRef(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      return AppUser.fromFirestore(data);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final snapshot = await userRef(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return AppUser.fromFirestore(data);
  }

  Future<void> saveUser(AppUser user) {
    return userRef(user.uid).set(user.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateActiveWorkspace({
    required String uid,
    required String workspaceId,
    required String workspaceType,
  }) {
    return userRef(uid).set(
      {
        'activeWorkspaceId': workspaceId,
        'activeWorkspaceType': workspaceType,
      },
      SetOptions(merge: true),
    );
  }
}

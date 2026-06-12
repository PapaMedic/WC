import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:wildland_companion_v2/core/models/cloud/app_user.dart';
import 'package:wildland_companion_v2/core/models/cloud/workspace.dart';
import 'package:wildland_companion_v2/core/repositories/organization_repository.dart';
import 'package:wildland_companion_v2/core/repositories/user_repository.dart';
import 'package:wildland_companion_v2/core/repositories/workspace_repository.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _auth;
  final UserRepository _userRepository;
  final WorkspaceRepository _workspaceRepository;
  final OrganizationRepository _organizationRepository;
  final FirebaseFirestore _firestore;

  AuthService({
    firebase_auth.FirebaseAuth? auth,
    UserRepository? userRepository,
    WorkspaceRepository? workspaceRepository,
    OrganizationRepository? organizationRepository,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _userRepository = userRepository ?? UserRepository(),
        _workspaceRepository = workspaceRepository ?? WorkspaceRepository(),
        _organizationRepository =
            organizationRepository ?? OrganizationRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();
  firebase_auth.User? get currentFirebaseUser => _auth.currentUser;

  Future<void> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<firebase_auth.User> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw firebase_auth.FirebaseAuthException(
        code: 'missing-user',
        message: 'Account was created but no user session was returned.',
      );
    }
    await user.updateDisplayName(displayName.trim());
    return user;
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Future<void> createSoloProfile({
    required String uid,
    required String displayName,
    required String email,
  }) async {
    final now = DateTime.now();
    final workspaceRef = _firestore.collection('workspaces').doc();
    final workspace = Workspace(
      workspaceId: workspaceRef.id,
      type: WorkspaceType.personal,
      ownerUid: uid,
      name: displayName.trim().isEmpty
          ? 'Personal Workspace'
          : '${displayName.trim()} Personal Workspace',
      createdAt: now,
    );
    final appUser = AppUser(
      uid: uid,
      displayName: displayName.trim(),
      email: email.trim(),
      accountType: 'solo',
      activeWorkspaceId: workspace.workspaceId,
      activeWorkspaceType: WorkspaceType.personal,
      personalWorkspaceId: workspace.workspaceId,
      createdAt: now,
      lastLoginAt: now,
    );

    await _workspaceRepository.saveWorkspace(workspace);
    await _userRepository.saveUser(appUser);
  }

  Future<OrganizationJoinResult> createProfileWithOrganizationCode({
    required String uid,
    required String displayName,
    required String email,
    required String code,
  }) async {
    await createSoloProfile(uid: uid, displayName: displayName, email: email);
    final user = await _userRepository.getUser(uid);
    if (user == null) {
      throw StateError('User profile could not be loaded after setup.');
    }
    return _organizationRepository.joinWithCode(
      user: user,
      enteredCode: code,
      switchWorkspace: true,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SignUpProfileInput {
  final String firstName;
  final String lastName;
  final String username;

  const SignUpProfileInput({
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  String get displayName => '$firstName $lastName'.trim();
  String get normalizedUsername => username.trim().toLowerCase();
}

class UsernameAlreadyTakenException implements Exception {
  final String message;

  const UsernameAlreadyTakenException([
    this.message = 'That username is already taken.',
  ]);
}

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _firebaseAuth.userChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  DocumentReference<Map<String, dynamic>> _userProfileRef(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _usernameRef(String usernameLower) {
    return _firestore.collection('usernames').doc(usernameLower);
  }

  Future<T> _traceOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (error) {
      _logDebugException(
        operationName: operationName,
        exception: error,
        code: error.code,
        message: error.message,
      );
      rethrow;
    } on FirebaseException catch (error) {
      _logDebugException(
        operationName: operationName,
        exception: error,
        code: error.code,
        message: error.message,
      );
      rethrow;
    } on UsernameAlreadyTakenException catch (error) {
      _logDebugException(
        operationName: operationName,
        exception: error,
        code: 'username-already-in-use',
        message: error.message,
      );
      rethrow;
    } catch (error) {
      _logDebugException(
        operationName: operationName,
        exception: error,
        code: null,
        message: null,
      );
      rethrow;
    }
  }

  void _logDebugException({
    required String operationName,
    required Object exception,
    required String? code,
    required String? message,
  }) {
    if (!kDebugMode) return;

    debugPrint(
      'Auth operation failed: '
      'operation=$operationName, '
      'exceptionType=${exception.runtimeType}, '
      'code=${code ?? '-'}, '
      'message=${message ?? '-'}',
    );
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _traceOperation(
      'signInWithEmailAndPassword',
      () => _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required SignUpProfileInput profile,
  }) async {
    final credential = await _traceOperation(
      'createUserWithEmailAndPassword',
      () => _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );

    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-create-failed',
        message: 'The account was created, but no user session was returned.',
      );
    }

    await completeCurrentUserProfile(profile: profile);
  }

  Future<bool> currentUserHasProfile() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;

    final snapshot = await _traceOperation(
      'checkUserProfile',
      () => _userProfileRef(user.uid).get(),
    );
    return snapshot.exists;
  }

  Future<void> completeCurrentUserProfile({
    required SignUpProfileInput profile,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'Sign in before creating a profile.',
      );
    }

    await _traceOperation(
      'updateDisplayName',
      () => user.updateDisplayName(profile.displayName),
    );
    await _createUserProfile(user: user, profile: profile);

    final refreshedUser = _firebaseAuth.currentUser ?? user;
    if (!refreshedUser.emailVerified) {
      await _traceOperation(
        'sendEmailVerification',
        () => refreshedUser.sendEmailVerification(),
      );
    }
  }

  Future<void> _createUserProfile({
    required User user,
    required SignUpProfileInput profile,
  }) async {
    final usernameLower = profile.normalizedUsername;
    final usernameRef = _usernameRef(usernameLower);
    final userRef = _userProfileRef(user.uid);
    final now = FieldValue.serverTimestamp();

    await _traceOperation(
      'createUserProfile',
      () => _firestore.runTransaction((transaction) async {
        final usernameSnapshot = await transaction.get(usernameRef);
        if (usernameSnapshot.exists &&
            usernameSnapshot.data()?['uid'] != user.uid) {
          throw const UsernameAlreadyTakenException();
        }

        transaction.set(usernameRef, {
          'uid': user.uid,
          'username': usernameLower,
          'usernameLower': usernameLower,
          'createdAt': now,
        });

        transaction.set(userRef, {
          'uid': user.uid,
          'email': user.email,
          'firstName': profile.firstName.trim(),
          'lastName': profile.lastName.trim(),
          'displayName': profile.displayName,
          'username': usernameLower,
          'usernameLower': usernameLower,
          'emailVerified': user.emailVerified,
          'createdAt': now,
          'updatedAt': now,
        });
      }),
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _traceOperation(
      'sendPasswordResetEmail',
      () => _firebaseAuth.sendPasswordResetEmail(email: email.trim()),
    );
  }

  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    await _traceOperation(
      'sendEmailVerification',
      () => user.sendEmailVerification(),
    );
  }

  Future<User?> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return null;

    await _traceOperation('reloadCurrentUser', user.reload);

    final refreshedUser = _firebaseAuth.currentUser;
    if (refreshedUser != null && await currentUserHasProfile()) {
      await _traceOperation(
        'updateUserProfileEmailVerified',
        () => _userProfileRef(refreshedUser.uid).set({
          'emailVerified': refreshedUser.emailVerified,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );
    }

    return refreshedUser;
  }

  Future<void> signOut() {
    return _traceOperation('signOut', _firebaseAuth.signOut);
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:wildland_companion_v2/features/auth/data/auth_repository.dart';

String authUserMessage(FirebaseAuthException error) {
  return switch (error.code) {
    'email-already-in-use' => 'An account already exists with this email.',
    'weak-password' => 'Please choose a stronger password.',
    'invalid-email' => 'Enter a valid email address.',
    'network-request-failed' =>
      'Unable to connect. Check your internet connection.',
    'invalid-credential' ||
    'user-not-found' ||
    'wrong-password' =>
      'Email or password is incorrect.',
    _ => error.message ?? 'Authentication failed. Try again.',
  };
}

String profileUserMessage(FirebaseException error) {
  return switch (error.code) {
    'permission-denied' =>
      'Unable to create your profile because database access was denied.',
    'already-exists' => 'That username is already taken.',
    'unavailable' => 'The profile service is temporarily unavailable.',
    'deadline-exceeded' => 'The profile request timed out. Please try again.',
    _ => error.message ?? 'Unable to create your profile. Please try again.',
  };
}

String usernameUserMessage(UsernameAlreadyTakenException error) {
  return error.message;
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static bool _isInitialized = false;
  static Object? _lastError;

  static bool get isInitialized => _isInitialized;
  static Object? get lastError => _lastError;

  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      _lastError = null;
    } catch (error, stackTrace) {
      _isInitialized = false;
      _lastError = error;
      debugPrint('Firebase initialization skipped: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}

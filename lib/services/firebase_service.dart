import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase Service
/// Handles Firebase initialization and configuration
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  FirebaseService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Initialize Firebase
  /// Call this before using any Firebase services
  Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) {
        print('Firebase already initialized');
      }
      return;
    }

    try {
      await Firebase.initializeApp();
      _initialized = true;
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase: $e');
      }
      rethrow;
    }
  }
}

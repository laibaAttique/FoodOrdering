import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';

/// Authentication Provider
/// Manages authentication state across the app
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((user) {
      _user = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  /// Load user profile from Firestore
  Future<void> _loadUserProfile(String uid) async {
    try {
      _userProfile = await _firestoreService.getUserProfile(uid);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Create Firebase auth account
      final userCredential = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        // Update display name
        await _authService.updateDisplayName(name);

        // Create user profile in Firestore
        final userModel = UserModel(
          uid: userCredential!.user!.uid,
          name: name,
          email: email,
          phone: phone,
          createdAt: DateTime.now(),
        );

        await _firestoreService.saveUserProfile(userModel);
        
        // Save user ID locally
        await _storageService.saveUserId(userCredential.user!.uid);

        _user = userCredential.user;
        _userProfile = userModel;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userCredential = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      if (userCredential?.user != null) {
        // Save user ID locally
        await _storageService.saveUserId(userCredential!.user!.uid);

        _user = userCredential.user;
        await _loadUserProfile(userCredential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send password reset email
  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _authService.signOut();
      await _storageService.clearUserId();

      _user = null;
      _userProfile = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      if (_user == null) return false;

      _isLoading = true;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
        await _authService.updateDisplayName(name);
      }
      if (phone != null) updates['phone'] = phone;
      if (photoUrl != null) updates['photoUrl'] = photoUrl;
      updates['updatedAt'] = DateTime.now().toIso8601String();

      await _firestoreService.updateUserProfile(_user!.uid, updates);
      await _loadUserProfile(_user!.uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

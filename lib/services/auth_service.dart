import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Authentication Service
/// Handles all Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        print('User signed up: ${userCredential.user?.uid}');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Sign up error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected sign up error: $e');
      }
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (kDebugMode) {
        print('User signed in: ${userCredential.user?.uid}');
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Sign in error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected sign in error: $e');
      }
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      
      if (kDebugMode) {
        print('Password reset email sent to: $email');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Password reset error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected password reset error: $e');
      }
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      if (kDebugMode) {
        print('User signed out');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Sign out error: $e');
      }
      throw 'Failed to sign out. Please try again.';
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String displayName) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.reload();
      
      if (kDebugMode) {
        print('Display name updated to: $displayName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update display name error: $e');
      }
      throw 'Failed to update name. Please try again.';
    }
  }

  /// Update user email
  Future<void> updateEmail(String newEmail) async {
    try {
      await _auth.currentUser?.verifyBeforeUpdateEmail(newEmail);
      
      if (kDebugMode) {
        print('Email update verification sent to: $newEmail');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Update email error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected update email error: $e');
      }
      throw 'Failed to update email. Please try again.';
    }
  }

  /// Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      
      if (kDebugMode) {
        print('Password updated successfully');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Update password error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected update password error: $e');
      }
      throw 'Failed to update password. Please try again.';
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      
      if (kDebugMode) {
        print('User account deleted');
      }
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('Delete account error: ${e.code} - ${e.message}');
      }
      throw _handleAuthException(e);
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected delete account error: $e');
      }
      throw 'Failed to delete account. Please try again.';
    }
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'requires-recent-login':
        return 'Please log in again to perform this action.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

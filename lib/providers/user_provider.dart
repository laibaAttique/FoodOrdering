import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

/// User Provider
/// Manages user profile and preferences
class UserProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _userProfile;
  bool _isLoading = false;

  // Getters
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  List<String> get savedAddresses => _userProfile?.savedAddresses ?? [];

  /// Load user profile
  Future<void> loadUserProfile(String uid) async {
    try {
      _isLoading = true;
      notifyListeners();

      _userProfile = await _firestoreService.getUserProfile(uid);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile(String uid, Map<String, dynamic> updates) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firestoreService.updateUserProfile(uid, updates);
      await loadUserProfile(uid);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating profile: $e');
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Add delivery address
  Future<bool> addAddress(String uid, String address) async {
    try {
      final addresses = List<String>.from(savedAddresses);
      addresses.add(address);
      
      return await updateProfile(uid, {'savedAddresses': addresses});
    } catch (e) {
      if (kDebugMode) {
        print('Error adding address: $e');
      }
      return false;
    }
  }

  /// Remove delivery address
  Future<bool> removeAddress(String uid, String address) async {
    try {
      final addresses = List<String>.from(savedAddresses);
      addresses.remove(address);
      
      return await updateProfile(uid, {'savedAddresses': addresses});
    } catch (e) {
      if (kDebugMode) {
        print('Error removing address: $e');
      }
      return false;
    }
  }

  /// Clear user data
  void clearUserData() {
    _userProfile = null;
    notifyListeners();
  }
}

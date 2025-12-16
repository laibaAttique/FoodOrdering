import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';

/// Storage Service
/// Handles local storage using SharedPreferences
/// Used for offline cart persistence
class StorageService {
  static const String _cartKey = 'user_cart';
  static const String _userIdKey = 'current_user_id';

  /// Save cart to local storage
  Future<void> saveCartLocally(List<CartItem> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = cartItems.map((item) => item.toMap()).toList();
      await prefs.setString(_cartKey, jsonEncode(cartJson));
      
      if (kDebugMode) {
        print('Cart saved locally: ${cartItems.length} items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cart locally: $e');
      }
    }
  }

  /// Get cart from local storage
  Future<List<CartItem>> getCartLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString(_cartKey);
      
      if (cartString != null) {
        final List<dynamic> cartJson = jsonDecode(cartString);
        final cartItems = cartJson.map((item) => CartItem.fromMap(item)).toList();
        
        if (kDebugMode) {
          print('Cart loaded locally: ${cartItems.length} items');
        }
        
        return cartItems;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cart locally: $e');
      }
      return [];
    }
  }

  /// Clear local cart
  Future<void> clearCartLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartKey);
      
      if (kDebugMode) {
        print('Local cart cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing local cart: $e');
      }
    }
  }

  /// Save current user ID
  Future<void> saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user ID: $e');
      }
    }
  }

  /// Get current user ID
  Future<String?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userIdKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user ID: $e');
      }
      return null;
    }
  }

  /// Clear user ID
  Future<void> clearUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userIdKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing user ID: $e');
      }
    }
  }

  /// Clear all local data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      if (kDebugMode) {
        print('All local data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing all data: $e');
      }
    }
  }
}

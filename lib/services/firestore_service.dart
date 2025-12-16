import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/user_model.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/rating_model.dart';

/// Firestore Service
/// Handles all database operations with Firestore
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _usersCollection => _db.collection('users');
  CollectionReference get _foodItemsCollection => _db.collection('foodItems');
  CollectionReference get _ordersCollection => _db.collection('orders');
  CollectionReference get _ratingsCollection => _db.collection('ratings');

  // ==================== USER OPERATIONS ====================

  /// Create or update user profile
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
      if (kDebugMode) {
        print('User profile saved: ${user.uid}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user profile: $e');
      }
      throw 'Failed to save user profile';
    }
  }

  /// Get user profile
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      await _usersCollection.doc(uid).update(updates);
      if (kDebugMode) {
        print('User profile updated: $uid');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      throw 'Failed to update profile';
    }
  }

  // ==================== FOOD ITEMS OPERATIONS ====================

  /// Get all food items
  Future<List<FoodItem>> getAllFoodItems() async {
    try {
      final snapshot = await _foodItemsCollection
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting food items: $e');
      }
      return [];
    }
  }

  /// Get food items by category
  Future<List<FoodItem>> getFoodItemsByCategory(String category) async {
    try {
      final snapshot = await _foodItemsCollection
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting food items by category: $e');
      }
      return [];
    }
  }

  /// Get seasonal food items
  Future<List<FoodItem>> getSeasonalItems() async {
    try {
      final snapshot = await _foodItemsCollection
          .where('isSeasonal', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting seasonal items: $e');
      }
      return [];
    }
  }

  /// Get promotional food items
  Future<List<FoodItem>> getPromotionalItems() async {
    try {
      final snapshot = await _foodItemsCollection
          .where('isPromotional', isEqualTo: true)
          .where('isAvailable', isEqualTo: true)
          .get();
      
      return snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting promotional items: $e');
      }
      return [];
    }
  }

  /// Search food items
  Future<List<FoodItem>> searchFoodItems(String query) async {
    try {
      final snapshot = await _foodItemsCollection
          .where('isAvailable', isEqualTo: true)
          .get();
      
      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => FoodItem.fromMap(doc.data() as Map<String, dynamic>))
          .where((item) =>
              item.name.toLowerCase().contains(lowerQuery) ||
              item.category.toLowerCase().contains(lowerQuery) ||
              item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error searching food items: $e');
      }
      return [];
    }
  }

  // ==================== CART OPERATIONS ====================

  /// Save cart to Firestore
  Future<void> saveCart(String userId, List<CartItem> cartItems) async {
    try {
      final cartData = {
        'userId': userId,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await _db.collection('carts').doc(userId).set(cartData);
      if (kDebugMode) {
        print('Cart saved for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cart: $e');
      }
    }
  }

  /// Get cart from Firestore
  Future<List<CartItem>> getCart(String userId) async {
    try {
      final doc = await _db.collection('carts').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List;
        return items.map((item) => CartItem.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error getting cart: $e');
      }
      return [];
    }
  }

  /// Clear cart
  Future<void> clearCart(String userId) async {
    try {
      await _db.collection('carts').doc(userId).delete();
      if (kDebugMode) {
        print('Cart cleared for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cart: $e');
      }
    }
  }

  // ==================== ORDER OPERATIONS ====================

  /// Create new order
  Future<String> createOrder(OrderModel order) async {
    try {
      final docRef = await _ordersCollection.add(order.toMap());
      if (kDebugMode) {
        print('Order created: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating order: $e');
      }
      throw 'Failed to create order: $e';
    }
  }

  /// Get user orders
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      final snapshot = await _ordersCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user orders: $e');
      }
      return [];
    }
  }

  /// Get active orders
  Future<List<OrderModel>> getActiveOrders(String userId) async {
    try {
      final snapshot = await _ordersCollection
          .where('userId', isEqualTo: userId)
          .where('status', whereIn: [
            OrderStatus.placed.toString(),
            OrderStatus.confirmed.toString(),
            OrderStatus.preparing.toString(),
            OrderStatus.ready.toString(),
            OrderStatus.outForDelivery.toString(),
          ])
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting active orders: $e');
      }
      return [];
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _ordersCollection.doc(orderId).update({
        'status': status.toString(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      if (kDebugMode) {
        print('Order status updated: $orderId -> $status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating order status: $e');
      }
      throw 'Failed to update order status';
    }
  }

  /// Stream order updates
  Stream<OrderModel?> streamOrder(String orderId) {
    return _ordersCollection.doc(orderId).snapshots().map((doc) {
      if (doc.exists) {
        return OrderModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  // ==================== RATING OPERATIONS ====================

  /// Submit rating
  Future<void> submitRating(RatingModel rating) async {
    try {
      await _ratingsCollection.doc(rating.id).set(rating.toMap());
      if (kDebugMode) {
        print('Rating submitted: ${rating.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting rating: $e');
      }
      throw 'Failed to submit rating';
    }
  }

  /// Get rating for order
  Future<RatingModel?> getRatingForOrder(String orderId) async {
    try {
      final snapshot = await _ratingsCollection
          .where('orderId', isEqualTo: orderId)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return RatingModel.fromMap(snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting rating: $e');
      }
      return null;
    }
  }

  // ==================== ANALYTICS ====================

  /// Get user order history for recommendations
  Future<List<OrderModel>> getUserOrderHistory(String userId, {int limit = 10}) async {
    try {
      final snapshot = await _ordersCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: OrderStatus.delivered.toString())
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting order history: $e');
      }
      return [];
    }
  }
}

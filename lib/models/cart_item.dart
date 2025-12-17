import 'food_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Cart Item Model
/// Represents a food item in the shopping cart with quantity
class CartItem {
  final String id; // Unique cart item ID
  final FoodItem foodItem;
  int quantity;
  final String? specialInstructions;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.foodItem,
    this.quantity = 1,
    this.specialInstructions,
    required this.addedAt,
  });

  // Calculate total price for this cart item
  double get totalPrice => foodItem.effectivePrice * quantity;

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodItemId': foodItem.id,
      'foodItem': foodItem.toMap(),
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  // Create from map
  factory CartItem.fromMap(Map<String, dynamic> map) {
    DateTime _parseDate(dynamic value) {
      if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    final foodItemMap = (map['foodItem'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    return CartItem(
      id: map['id'] ?? '',
      foodItem: FoodItem.fromMap(foodItemMap),
      quantity: map['quantity'] ?? 1,
      specialInstructions: map['specialInstructions'],
      addedAt: _parseDate(map['addedAt']),
    );
  }

  // Copy with method
  CartItem copyWith({
    String? id,
    FoodItem? foodItem,
    int? quantity,
    String? specialInstructions,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

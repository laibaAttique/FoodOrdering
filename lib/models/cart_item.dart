import 'food_item.dart';

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
    return CartItem(
      id: map['id'] ?? '',
      foodItem: FoodItem.fromMap(map['foodItem']),
      quantity: map['quantity'] ?? 1,
      specialInstructions: map['specialInstructions'],
      addedAt: DateTime.parse(map['addedAt']),
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

/// Food Item Model
/// Represents a single food item in the cafeteria
class FoodItem {
  final String id;
  final String name;
  final String category; // "Desi Food", "Fast Food", "Chinese", "Snacks", "Beverages"
  final String subCategory; // "Most Liked", "Seasonal", "Suggestions"
  final double price;
  final double? discountPrice; // For promotional offers
  final String imageUrl; // Firebase Storage URL or emoji
  final String description;
  final String? nutritionalInfo;
  final double rating;
  final int reviews;
  final bool isAvailable;
  final bool isSeasonal;
  final bool isPromotional;
  final List<String> tags; // e.g., ["spicy", "vegetarian", "popular"]
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    this.subCategory = '',
    required this.price,
    this.discountPrice,
    required this.imageUrl,
    required this.description,
    this.nutritionalInfo,
    this.rating = 0.0,
    this.reviews = 0,
    this.isAvailable = true,
    this.isSeasonal = false,
    this.isPromotional = false,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Get effective price (discount or regular)
  double get effectivePrice => discountPrice ?? price;

  // Check if item has discount
  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  // Get discount percentage
  int get discountPercentage {
    if (!hasDiscount) return 0;
    return (((price - discountPrice!) / price) * 100).round();
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'subCategory': subCategory,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
      'description': description,
      'nutritionalInfo': nutritionalInfo,
      'rating': rating,
      'reviews': reviews,
      'isAvailable': isAvailable,
      'isSeasonal': isSeasonal,
      'isPromotional': isPromotional,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      subCategory: map['subCategory'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      discountPrice: map['discountPrice']?.toDouble(),
      imageUrl: map['imageUrl'] ?? '🍕',
      description: map['description'] ?? '',
      nutritionalInfo: map['nutritionalInfo'],
      rating: (map['rating'] ?? 0).toDouble(),
      reviews: map['reviews'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
      isSeasonal: map['isSeasonal'] ?? false,
      isPromotional: map['isPromotional'] ?? false,
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Copy with method for updates
  FoodItem copyWith({
    String? id,
    String? name,
    String? category,
    String? subCategory,
    double? price,
    double? discountPrice,
    String? imageUrl,
    String? description,
    String? nutritionalInfo,
    double? rating,
    int? reviews,
    bool? isAvailable,
    bool? isSeasonal,
    bool? isPromotional,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      nutritionalInfo: nutritionalInfo ?? this.nutritionalInfo,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      isAvailable: isAvailable ?? this.isAvailable,
      isSeasonal: isSeasonal ?? this.isSeasonal,
      isPromotional: isPromotional ?? this.isPromotional,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Get items by category
List<FoodItem> getFoodItemsByCategory(String category) {
  // This function is deprecated - use FirestoreService instead
  return [];
}

/// Get all unique categories
List<String> getAllCategories() {
  return ['Most Liked', 'Seasonal Offers', 'Suggestions to Try'];
}

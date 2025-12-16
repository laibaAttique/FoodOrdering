/// Rating Model
/// Represents user feedback for an order
class RatingModel {
  final String id;
  final String orderId;
  final String userId;
  final double rating; // 1-5 stars
  final String? comment;
  final List<String>? itemRatings; // Individual item ratings
  final DateTime createdAt;

  RatingModel({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.rating,
    this.comment,
    this.itemRatings,
    required this.createdAt,
  });

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'itemRatings': itemRatings,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from Firestore document
  factory RatingModel.fromMap(Map<String, dynamic> map) {
    return RatingModel(
      id: map['id'] ?? '',
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'],
      itemRatings: map['itemRatings'] != null 
          ? List<String>.from(map['itemRatings']) 
          : null,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}

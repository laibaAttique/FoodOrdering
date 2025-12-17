import 'cart_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Order Status Enum
enum OrderStatus {
  placed,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

/// Order Type Enum
enum OrderType {
  delivery,
  pickup,
}

/// Order Model
/// Represents a complete food order
class OrderModel {
  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;
  final OrderType orderType;
  final OrderStatus status;
  final String? deliveryAddress;
  final String? deliveryInstructions;
  final String? deliveryPersonId;
  final Map<String, double>? deliveryLocation; // lat, lng
  final String paymentMethod; // "Cash on Delivery"
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? readyAt;
  final DateTime? deliveredAt;
  final String? cancelReason;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    this.deliveryFee = 0,
    this.discount = 0,
    required this.total,
    required this.orderType,
    this.status = OrderStatus.placed,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.deliveryPersonId,
    this.deliveryLocation,
    this.paymentMethod = 'Cash on Delivery',
    required this.createdAt,
    this.confirmedAt,
    this.readyAt,
    this.deliveredAt,
    this.cancelReason,
  });

  // Get status display text
  String get statusText {
    switch (status) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready for ${orderType == OrderType.pickup ? 'Pickup' : 'Delivery'}';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  // Check if order is active
  bool get isActive {
    return status != OrderStatus.delivered && status != OrderStatus.cancelled;
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'discount': discount,
      'total': total,
      'orderType': orderType.toString(),
      'status': status.toString(),
      'deliveryAddress': deliveryAddress,
      'deliveryInstructions': deliveryInstructions,
      'deliveryPersonId': deliveryPersonId,
      'deliveryLocation': deliveryLocation,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt.toIso8601String(),
      'confirmedAt': confirmedAt?.toIso8601String(),
      'readyAt': readyAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'cancelReason': cancelReason,
    };
  }

  // Create from Firestore document
  factory OrderModel.fromMap(Map<String, dynamic> map) {
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

    Map<String, double>? _parseLocation(dynamic value) {
      if (value == null) return null;
      if (value is Map) {
        final lat = value['lat'];
        final lng = value['lng'];
        if (lat == null || lng == null) return null;
        if (lat is num && lng is num) {
          return {'lat': lat.toDouble(), 'lng': lng.toDouble()};
        }
      }
      return null;
    }

    final rawItems = (map['items'] as List?) ?? const [];

    return OrderModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: rawItems
          .whereType<Map>()
          .map((item) => CartItem.fromMap(item.cast<String, dynamic>()))
          .toList(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      orderType: OrderType.values.firstWhere(
        (e) => e.toString() == map['orderType'],
        orElse: () => OrderType.delivery,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => OrderStatus.placed,
      ),
      deliveryAddress: map['deliveryAddress'],
      deliveryInstructions: map['deliveryInstructions'],
      deliveryPersonId: map['deliveryPersonId'],
      deliveryLocation: _parseLocation(map['deliveryLocation']),
      paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
      createdAt: _parseDate(map['createdAt']),
      confirmedAt: map['confirmedAt'] != null ? _parseDate(map['confirmedAt']) : null,
      readyAt: map['readyAt'] != null ? _parseDate(map['readyAt']) : null,
      deliveredAt: map['deliveredAt'] != null ? _parseDate(map['deliveredAt']) : null,
      cancelReason: map['cancelReason'],
    );
  }

  // Copy with method
  OrderModel copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    double? total,
    OrderType? orderType,
    OrderStatus? status,
    String? deliveryAddress,
    String? deliveryInstructions,
    String? deliveryPersonId,
    Map<String, double>? deliveryLocation,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? readyAt,
    DateTime? deliveredAt,
    String? cancelReason,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      orderType: orderType ?? this.orderType,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      deliveryPersonId: deliveryPersonId ?? this.deliveryPersonId,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      readyAt: readyAt ?? this.readyAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }
}

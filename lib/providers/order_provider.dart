import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import '../services/firestore_service.dart';

/// Order Provider
/// Manages order state and operations
class OrderProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final Uuid _uuid = const Uuid();

  List<OrderModel> _orders = [];
  List<OrderModel> _activeOrders = [];
  bool _isLoading = false;
  String? _userId;

  // Getters
  List<OrderModel> get orders => _orders;
  List<OrderModel> get activeOrders => _activeOrders;
  bool get isLoading => _isLoading;
  bool get hasActiveOrders => _activeOrders.isNotEmpty;

  /// Set user ID and load orders
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    if (userId != null) {
      await loadOrders();
    } else {
      _orders = [];
      _activeOrders = [];
      notifyListeners();
    }
  }

  /// Load user orders
  Future<void> loadOrders() async {
    if (_userId == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      _orders = await _firestoreService.getUserOrders(_userId!);
      _activeOrders = await _firestoreService.getActiveOrders(_userId!);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading orders: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create new order
  Future<String?> createOrder({
    required List<CartItem> items,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required OrderType orderType,
    String? deliveryAddress,
    String? deliveryInstructions,
    double discount = 0,
  }) async {
    if (_userId == null) return null;

    try {
      _isLoading = true;
      notifyListeners();

      final order = OrderModel(
        id: _uuid.v4(),
        userId: _userId!,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        total: total,
        orderType: orderType,
        status: OrderStatus.placed,
        deliveryAddress: deliveryAddress,
        deliveryInstructions: deliveryInstructions,
        paymentMethod: 'Cash on Delivery',
        createdAt: DateTime.now(),
      );

      final orderId = await _firestoreService.createOrder(order);
      
      // Reload orders
      await loadOrders();

      _isLoading = false;
      notifyListeners();

      return orderId;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating order: $e');
      }
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get order by ID
  OrderModel? getOrderById(String orderId) {
    try {
      return _orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  /// Stream order updates
  Stream<OrderModel?> streamOrder(String orderId) {
    return _firestoreService.streamOrder(orderId);
  }

  /// Refresh orders
  Future<void> refreshOrders() async {
    await loadOrders();
  }
}

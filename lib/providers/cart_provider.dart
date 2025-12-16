import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item.dart';
import '../models/food_item.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

/// Cart Provider
/// Manages shopping cart state with automatic persistence
class CartProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _userId;

  // Getters
  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  int get totalQuantity => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get subtotal => _items.fold(
        0,
        (sum, item) => sum + item.totalPrice,
      );

  double get deliveryFee => subtotal > 0 ? 50.0 : 0.0; // PKR 50 delivery fee
  
  double get total => subtotal + deliveryFee;

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// Set user ID and load cart
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    if (userId != null) {
      await loadCart();
    } else {
      _items = [];
      notifyListeners();
    }
  }

  /// Load cart from storage
  Future<void> loadCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to load from Firestore first (if user is logged in)
      if (_userId != null) {
        final firestoreCart = await _firestoreService.getCart(_userId!);
        if (firestoreCart.isNotEmpty) {
          _items = firestoreCart;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // Fallback to local storage
      final localCart = await _storageService.getCartLocally();
      _items = localCart;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cart: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save cart to storage
  Future<void> _saveCart() async {
    try {
      // Save to local storage
      await _storageService.saveCartLocally(_items);

      // Save to Firestore if user is logged in
      if (_userId != null) {
        await _firestoreService.saveCart(_userId!, _items);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cart: $e');
      }
    }
  }

  /// Add item to cart
  Future<void> addItem(FoodItem foodItem, {int quantity = 1}) async {
    try {
      // Check if item already exists in cart
      final existingIndex = _items.indexWhere(
        (item) => item.foodItem.id == foodItem.id,
      );

      if (existingIndex >= 0) {
        // Update quantity
        _items[existingIndex].quantity += quantity;
      } else {
        // Add new item
        final cartItem = CartItem(
          id: _uuid.v4(),
          foodItem: foodItem,
          quantity: quantity,
          addedAt: DateTime.now(),
        );
        _items.add(cartItem);
      }

      notifyListeners();
      await _saveCart();
    } catch (e) {
      if (kDebugMode) {
        print('Error adding item to cart: $e');
      }
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String cartItemId) async {
    try {
      _items.removeWhere((item) => item.id == cartItemId);
      notifyListeners();
      await _saveCart();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing item from cart: $e');
      }
    }
  }

  /// Update item quantity
  Future<void> updateQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        await removeItem(cartItemId);
        return;
      }

      final index = _items.indexWhere((item) => item.id == cartItemId);
      if (index >= 0) {
        _items[index].quantity = newQuantity;
        notifyListeners();
        await _saveCart();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating quantity: $e');
      }
    }
  }

  /// Increment item quantity
  Future<void> incrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      await updateQuantity(cartItemId, _items[index].quantity + 1);
    }
  }

  /// Decrement item quantity
  Future<void> decrementQuantity(String cartItemId) async {
    final index = _items.indexWhere((item) => item.id == cartItemId);
    if (index >= 0) {
      await updateQuantity(cartItemId, _items[index].quantity - 1);
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    try {
      _items = [];
      notifyListeners();

      await _storageService.clearCartLocally();
      if (_userId != null) {
        await _firestoreService.clearCart(_userId!);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing cart: $e');
      }
    }
  }

  /// Get cart item by ID
  CartItem? getItemById(String cartItemId) {
    try {
      return _items.firstWhere((item) => item.id == cartItemId);
    } catch (e) {
      return null;
    }
  }

  /// Check if item is in cart
  bool isInCart(String foodItemId) {
    return _items.any((item) => item.foodItem.id == foodItemId);
  }

  /// Get quantity of specific food item in cart
  int getItemQuantity(String foodItemId) {
    try {
      final cartItem = _items.firstWhere(
        (item) => item.foodItem.id == foodItemId,
      );
      return cartItem.quantity;
    } catch (e) {
      return 0;
    }
  }
}

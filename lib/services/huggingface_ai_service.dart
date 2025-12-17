import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import 'firestore_service.dart';

/// HuggingFace AI Service
/// Uses sentence-transformers embeddings for intelligent food recommendations
/// based on semantic similarity between orders and menu items
class HuggingFaceAIService {
  // HuggingFace Inference API endpoint (updated to new router endpoint)
  static const String _apiUrl = 
    'https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2';
  
  // API Token - loaded from environment variable
  // Set HUGGINGFACE_API_KEY in your .env file or environment
  static const String _apiToken = String.fromEnvironment('HUGGINGFACE_API_KEY', defaultValue: '');
  
  final FirestoreService _firestoreService = FirestoreService();
  
  // Cache for embeddings to avoid repeated API calls
  final Map<String, List<double>> _embeddingCache = {};

  /// Get embedding vector for a text using HuggingFace API
  /// Note: HuggingFace API requires proper token permissions
  /// Currently using local smart recommendations as fallback
  Future<List<double>?> _getEmbedding(String text) async {
    // Check cache first
    if (_embeddingCache.containsKey(text)) {
      print('🔵 HuggingFace: Using cached embedding');
      return _embeddingCache[text];
    }
    
    try {
      print('🟡 HuggingFace: Calling API...');
      
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'inputs': text}),
      ).timeout(const Duration(seconds: 8));

      print('🟡 HuggingFace: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          List<double> embedding;
          if (data[0] is List) {
            embedding = List<double>.from((data[0] as List).map((e) => (e as num).toDouble()));
          } else {
            embedding = List<double>.from(data.map((e) => (e as num).toDouble()));
          }
          _embeddingCache[text] = embedding;
          print('✅ HuggingFace: Got embedding with ${embedding.length} dimensions');
          return embedding;
        }
      } else {
        print('❌ HuggingFace API error: ${response.statusCode}');
        // API error - will use local fallback
      }
    } catch (e) {
      print('❌ HuggingFace API failed: $e');
      // Network/CORS error - will use local fallback
    }
    // Return null to trigger local fallback
    return null;
  }

  /// Calculate cosine similarity between two embedding vectors
  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Get AI-powered suggestions based on cart items using embeddings
  Future<AISuggestionResult> getCartBasedSuggestions(List<CartItem> cartItems) async {
    print('🛒 HuggingFace: getCartBasedSuggestions called with ${cartItems.length} items');
    
    if (cartItems.isEmpty) {
      return AISuggestionResult(
        suggestions: [],
        aiMessage: "Add items to your cart to get personalized suggestions!",
        isAIPowered: false,
      );
    }

    try {
      // Get all available food items
      final allItems = await _firestoreService.getAllFoodItems();
      print('🛒 HuggingFace: Got ${allItems.length} total items from Firestore');
      
      final cartItemIds = cartItems.map((c) => c.foodItem.id).toSet();
      
      // Filter out items already in cart
      final availableItems = allItems.where((item) => !cartItemIds.contains(item.id)).toList();
      print('🛒 HuggingFace: ${availableItems.length} available items after filtering');
      
      if (availableItems.isEmpty) {
        return AISuggestionResult(
          suggestions: [],
          aiMessage: "You've added everything! Great choices!",
          isAIPowered: false,
        );
      }

      // Create cart context string for embedding
      final cartContext = cartItems.map((c) => 
        "${c.foodItem.name} ${c.foodItem.category} ${c.foodItem.tags.join(' ')}"
      ).join(", ");
      
      print('🛒 HuggingFace: Cart context: $cartContext');

      // Get embedding for cart context
      final cartEmbedding = await _getEmbedding(cartContext);
      print('🛒 HuggingFace: Cart embedding result: ${cartEmbedding != null ? "SUCCESS" : "FAILED"}');
      
      if (cartEmbedding != null) {
        // Score each available item by similarity to cart
        final scored = <FoodItem, double>{};
        
        // Only get embeddings for first 10 items to avoid too many API calls
        for (final item in availableItems.take(15)) {
          final itemText = "${item.name} ${item.category} ${item.tags.join(' ')}";
          final itemEmbedding = await _getEmbedding(itemText);
          
          if (itemEmbedding != null) {
            final similarity = _cosineSimilarity(cartEmbedding, itemEmbedding);
            
            // Boost complementary items (different category = variety)
            double score = similarity;
            if (!cartItems.any((c) => c.foodItem.category == item.category)) {
              score += 0.1; // Bonus for variety
            }
            
            // Boost drinks if no drinks in cart
            if (item.category == 'Beverages' && 
                !cartItems.any((c) => c.foodItem.category == 'Beverages')) {
              score += 0.15;
            }
            
            scored[item] = score;
          }
        }
        
        print('🛒 HuggingFace: Scored ${scored.length} items');
        
        // Sort by score and take top 4
        final sorted = scored.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final suggestions = sorted.take(4).map((e) => e.key).toList();
        print('🛒 HuggingFace: Returning ${suggestions.length} AI-powered suggestions');
        
        if (suggestions.isNotEmpty) {
          // Generate smart message based on cart
          final cartCategories = cartItems.map((c) => c.foodItem.category).toSet();
          String message;
          
          if (cartCategories.contains('Chinese')) {
            message = "🥢 Perfect additions to your Chinese meal!";
          } else if (cartCategories.contains('Fast Food')) {
            message = "🍟 Complete your fast food combo!";
          } else if (cartCategories.contains('Desi Food')) {
            message = "🍛 Great sides for your desi feast!";
          } else {
            message = "✨ AI recommends these for you!";
          }
          
          return AISuggestionResult(
            suggestions: suggestions,
            aiMessage: message,
            isAIPowered: true,
          );
        }
      }
      
      // Fallback to local suggestions if API fails
      return _getLocalCartSuggestions(cartItems, availableItems);
    } catch (e) {
      if (kDebugMode) {
        print('AI Suggestion error: $e');
      }
      final allItems = await _firestoreService.getAllFoodItems();
      final cartItemIds = cartItems.map((c) => c.foodItem.id).toSet();
      final availableItems = allItems.where((item) => !cartItemIds.contains(item.id)).toList();
      return _getLocalCartSuggestions(cartItems, availableItems);
    }
  }

  /// Get AI-powered suggestions based on order history using embeddings
  Future<AISuggestionResult> getHistoryBasedSuggestions(String userId) async {
    print('📜 HuggingFace: getHistoryBasedSuggestions called for user: $userId');
    
    try {
      final orderHistory = await _firestoreService.getUserOrderHistory(userId, limit: 10);
      final allItems = await _firestoreService.getAllFoodItems();
      
      print('📜 HuggingFace: Order history count: ${orderHistory.length}');
      print('📜 HuggingFace: All items count: ${allItems.length}');
      
      if (allItems.isEmpty) {
        print('📜 HuggingFace: No items available - returning empty');
        return AISuggestionResult(
          suggestions: [],
          aiMessage: "",
          isAIPowered: false,
        );
      }
      
      // If no order history, show popular items for new users
      if (orderHistory.isEmpty) {
        print('📜 HuggingFace: No order history - showing popular items for new user');
        final popularItems = allItems
            .where((item) => item.rating >= 4.5)
            .toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final suggestions = popularItems.take(4).toList();
        return AISuggestionResult(
          suggestions: suggestions,
          aiMessage: "🌟 Popular picks to get you started!",
          isAIPowered: false,
        );
      }

      // Create order history context for embedding
      final historyContext = orderHistory.take(5).map((order) {
        return order.items.map((c) => 
          "${c.foodItem.name} ${c.foodItem.category}"
        ).join(", ");
      }).join(" | ");
      
      print('📜 HuggingFace: History context: $historyContext');

      // Get embedding for history context
      final historyEmbedding = await _getEmbedding(historyContext);
      print('📜 HuggingFace: History embedding result: ${historyEmbedding != null ? "SUCCESS" : "FAILED"}');
      
      if (historyEmbedding != null) {
        // Get items user has already ordered
        final orderedItemIds = <String>{};
        for (final order in orderHistory) {
          for (final item in order.items) {
            orderedItemIds.add(item.foodItem.id);
          }
        }
        
        // Score each item by similarity to order history
        final scored = <FoodItem, double>{};
        
        for (final item in allItems) {
          final itemText = "${item.name} ${item.category} ${item.tags.join(' ')}";
          final itemEmbedding = await _getEmbedding(itemText);
          
          if (itemEmbedding != null) {
            final similarity = _cosineSimilarity(historyEmbedding, itemEmbedding);
            
            // Boost items user hasn't tried yet
            double score = similarity;
            if (!orderedItemIds.contains(item.id)) {
              score += 0.2; // Bonus for new items
            }
            
            // Boost highly rated items
            score += item.rating * 0.02;
            
            scored[item] = score;
          }
        }
        
        // Sort by score and take top 4
        final sorted = scored.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final suggestions = sorted.take(4).map((e) => e.key).toList();
        
        if (suggestions.isNotEmpty) {
          // Detect user's favorite category
          final categoryCount = <String, int>{};
          for (final order in orderHistory) {
            for (final item in order.items) {
              final cat = item.foodItem.category;
              categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
            }
          }
          
          String? favoriteCategory;
          int maxCount = 0;
          categoryCount.forEach((cat, count) {
            if (count > maxCount) {
              maxCount = count;
              favoriteCategory = cat;
            }
          });
          
          String message;
          if (favoriteCategory == 'Chinese') {
            message = "🥢 Based on your love for Chinese food!";
          } else if (favoriteCategory == 'Fast Food') {
            message = "🍔 Since you enjoy fast food, try these!";
          } else if (favoriteCategory == 'Desi Food') {
            message = "🍛 Recommended for desi food lovers!";
          } else if (favoriteCategory == 'Beverages') {
            message = "🥤 Drinks you might enjoy!";
          } else {
            message = "✨ Personalized picks just for you!";
          }
          
          return AISuggestionResult(
            suggestions: suggestions,
            aiMessage: message,
            isAIPowered: true,
          );
        }
      }
      
      // Fallback to local suggestions
      return _getLocalHistorySuggestions(orderHistory, allItems);
    } catch (e) {
      if (kDebugMode) {
        print('AI History suggestion error: $e');
      }
      return AISuggestionResult(
        suggestions: [],
        aiMessage: "",
        isAIPowered: false,
      );
    }
  }

  /// Local fallback for cart-based suggestions
  AISuggestionResult _getLocalCartSuggestions(List<CartItem> cartItems, List<FoodItem> availableItems) {
    final cartCategories = cartItems.map((c) => c.foodItem.category).toSet();
    final cartNames = cartItems.map((c) => c.foodItem.name.toLowerCase()).toList();
    
    // Detect food types
    final hasChinese = cartCategories.contains('Chinese');
    final hasFastFood = cartCategories.contains('Fast Food');
    final hasDesiFood = cartCategories.contains('Desi Food');
    final hasDrink = cartCategories.contains('Beverages');
    
    // Score items
    final scored = <FoodItem, double>{};
    for (final item in availableItems) {
      double score = 0;
      final itemName = item.name.toLowerCase();
      
      // Chinese food logic
      if (hasChinese) {
        if (item.category == 'Chinese') score += 5;
        if (itemName.contains('spring') || itemName.contains('noodle') || itemName.contains('rice')) score += 8;
        if (item.category == 'Beverages' && !hasDrink) score += 6;
      }
      
      // Fast food logic
      if (hasFastFood) {
        if (itemName.contains('fries') || itemName.contains('loaded')) score += 10;
        if (item.category == 'Beverages' && !hasDrink) score += 8;
      }
      
      // Desi food logic
      if (hasDesiFood) {
        if (itemName.contains('lassi') || itemName.contains('raita')) score += 10;
        if (item.category == 'Beverages' && !hasDrink) score += 6;
      }
      
      // Always suggest drinks if none
      if (!hasDrink && item.category == 'Beverages') score += 4;
      
      // Rating bonus
      score += item.rating * 0.3;
      
      // Variety bonus
      if (!cartCategories.contains(item.category)) score += 2;
      
      scored[item] = score;
    }
    
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final suggestions = sorted.where((e) => e.value > 0).take(4).map((e) => e.key).toList();
    
    String message;
    if (hasChinese) {
      message = "🥢 Complete your Chinese meal!";
    } else if (hasFastFood) {
      message = "🍟 Perfect additions to your order!";
    } else if (hasDesiFood) {
      message = "🍛 Complete your desi feast!";
    } else if (!hasDrink) {
      message = "🥤 Add a drink to your order!";
    } else {
      message = "✨ You might also like these!";
    }
    
    return AISuggestionResult(
      suggestions: suggestions,
      aiMessage: message,
      isAIPowered: false,
    );
  }

  /// Local fallback for history-based suggestions
  AISuggestionResult _getLocalHistorySuggestions(List<OrderModel> orderHistory, List<FoodItem> allItems) {
    print('📜 Local fallback: Processing ${orderHistory.length} orders, ${allItems.length} items');
    
    final orderedItemIds = <String>{};
    final categoryCount = <String, int>{};
    
    for (final order in orderHistory) {
      for (final item in order.items) {
        orderedItemIds.add(item.foodItem.id);
        final cat = item.foodItem.category;
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      }
    }
    
    print('📜 Local fallback: Ordered items: ${orderedItemIds.length}, Categories: $categoryCount');
    
    // Find favorite category
    String? favoriteCategory;
    int maxCount = 0;
    categoryCount.forEach((cat, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteCategory = cat;
      }
    });
    
    print('📜 Local fallback: Favorite category: $favoriteCategory');
    
    // Score items - ensure we always get suggestions
    final scored = <FoodItem, double>{};
    for (final item in allItems) {
      double score = item.rating * 0.5; // Base score from rating
      
      // Boost favorite category items not yet ordered
      if (favoriteCategory != null && item.category == favoriteCategory && !orderedItemIds.contains(item.id)) {
        score += 10;
      }
      
      // Boost highly rated items user hasn't tried
      if (item.rating >= 4.5 && !orderedItemIds.contains(item.id)) {
        score += 5;
      }
      
      // Boost items from same category as ordered items
      if (categoryCount.containsKey(item.category)) {
        score += 3;
      }
      
      scored[item] = score;
    }
    
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 4 regardless of score
    final suggestions = sorted.take(4).map((e) => e.key).toList();
    
    print('📜 Local fallback: Returning ${suggestions.length} suggestions');
    
    String message = favoriteCategory != null 
      ? "✨ Since you love $favoriteCategory, try these!"
      : "🌟 Recommended for you!";
    
    return AISuggestionResult(
      suggestions: suggestions,
      aiMessage: message,
      isAIPowered: false,
    );
  }
}

/// Result class for AI suggestions
class AISuggestionResult {
  final List<FoodItem> suggestions;
  final String aiMessage;
  final bool isAIPowered;

  AISuggestionResult({
    required this.suggestions,
    required this.aiMessage,
    required this.isAIPowered,
  });
}

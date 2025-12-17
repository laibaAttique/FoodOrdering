import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/food_item.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import 'firestore_service.dart';

/// AI Suggestion Service
/// Uses Google Gemini API to provide intelligent food recommendations
/// based on user's order history and current cart items
class AISuggestionService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  // TODO: Replace with your own API key from https://makersuite.google.com/app/apikey
  static const String _apiKey = 'gen-lang-client-0039529357';
  
  final FirestoreService _firestoreService = FirestoreService();

  /// Get AI-powered suggestions based on cart items
  Future<AISuggestionResult> getCartBasedSuggestions(List<CartItem> cartItems) async {
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
      final cartItemIds = cartItems.map((c) => c.foodItem.id).toSet();
      
      // Filter out items already in cart
      final availableItems = allItems.where((item) => !cartItemIds.contains(item.id)).toList();
      
      if (availableItems.isEmpty) {
        return AISuggestionResult(
          suggestions: [],
          aiMessage: "You've added everything! Great choices!",
          isAIPowered: false,
        );
      }

      // Build context for AI
      final cartContext = cartItems.map((c) => 
        "${c.foodItem.name} (${c.foodItem.category}) - ${c.quantity}x"
      ).join(", ");
      
      final availableContext = availableItems.take(20).map((item) =>
        "${item.id}|${item.name}|${item.category}|${item.price}|${item.tags.join(',')}"
      ).join("\n");

      final prompt = '''
You are a smart food recommendation AI for a university cafeteria app called BitesBuzz.

Current cart items: $cartContext

Available items to recommend:
$availableContext

Based on the cart items, suggest 3-4 complementary food items that would go well together. 
Consider:
1. Meal completeness (if they have main course, suggest drinks/sides)
2. Flavor pairing (spicy with cooling drinks, etc.)
3. Popular combinations students usually order together

Respond in this exact JSON format only, no other text:
{
  "message": "A short friendly suggestion message (max 50 words)",
  "item_ids": ["id1", "id2", "id3"]
}
''';

      final response = await _callGeminiAPI(prompt);
      
      if (response != null) {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (jsonMatch != null) {
          final jsonData = json.decode(jsonMatch.group(0)!);
          final suggestedIds = List<String>.from(jsonData['item_ids'] ?? []);
          final message = jsonData['message'] as String? ?? "Here are some suggestions for you!";
          
          final suggestedItems = availableItems
              .where((item) => suggestedIds.contains(item.id))
              .toList();
          
          if (suggestedItems.isNotEmpty) {
            return AISuggestionResult(
              suggestions: suggestedItems,
              aiMessage: message,
              isAIPowered: true,
            );
          }
        }
      }
      
      // Fallback to smart local suggestions
      return _getLocalCartSuggestions(cartItems, availableItems);
    } catch (e) {
      if (kDebugMode) {
        print('AI Suggestion error: $e');
      }
      // Fallback to local suggestions
      final allItems = await _firestoreService.getAllFoodItems();
      final cartItemIds = cartItems.map((c) => c.foodItem.id).toSet();
      final availableItems = allItems.where((item) => !cartItemIds.contains(item.id)).toList();
      return _getLocalCartSuggestions(cartItems, availableItems);
    }
  }

  /// Get AI-powered suggestions based on order history
  Future<AISuggestionResult> getHistoryBasedSuggestions(String userId) async {
    try {
      final orderHistory = await _firestoreService.getUserOrderHistory(userId, limit: 10);
      final allItems = await _firestoreService.getAllFoodItems();
      
      if (orderHistory.isEmpty) {
        // New user with no order history - return empty suggestions
        // The regular menu sections will show instead
        return AISuggestionResult(
          suggestions: [],
          aiMessage: "",
          isAIPowered: false,
        );
      }

      // Build order history context
      final historyContext = orderHistory.take(5).map((order) {
        final items = order.items.map((c) => c.foodItem.name).join(", ");
        return items;
      }).join(" | ");

      final availableContext = allItems.take(25).map((item) =>
        "${item.id}|${item.name}|${item.category}|${item.rating}|${item.tags.join(',')}"
      ).join("\n");

      final prompt = '''
You are a smart food recommendation AI for BitesBuzz university cafeteria.

User's recent order history: $historyContext

Available menu items:
$availableContext

Based on their order patterns, suggest 4 items they might enjoy. Consider:
1. Items similar to what they frequently order
2. New items in categories they like
3. Highly-rated items they haven't tried

Respond in this exact JSON format only:
{
  "message": "A personalized greeting with suggestion reason (max 40 words)",
  "item_ids": ["id1", "id2", "id3", "id4"]
}
''';

      final response = await _callGeminiAPI(prompt);
      
      if (response != null) {
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
        if (jsonMatch != null) {
          final jsonData = json.decode(jsonMatch.group(0)!);
          final suggestedIds = List<String>.from(jsonData['item_ids'] ?? []);
          final message = jsonData['message'] as String? ?? "Based on your taste, you might love these!";
          
          final suggestedItems = allItems
              .where((item) => suggestedIds.contains(item.id))
              .toList();
          
          if (suggestedItems.isNotEmpty) {
            return AISuggestionResult(
              suggestions: suggestedItems,
              aiMessage: message,
              isAIPowered: true,
            );
          }
        }
      }
      
      // Fallback
      return _getLocalHistorySuggestions(orderHistory, allItems);
    } catch (e) {
      if (kDebugMode) {
        print('AI History suggestion error: $e');
      }
      return AISuggestionResult(
        suggestions: [],
        aiMessage: "Check out our menu for delicious options!",
        isAIPowered: false,
      );
    }
  }

  /// Call Gemini API
  Future<String?> _callGeminiAPI(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text as String?;
      } else {
        if (kDebugMode) {
          print('Gemini API error: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Gemini API call failed: $e');
      }
      return null;
    }
  }

  /// Local fallback for cart-based suggestions
  AISuggestionResult _getLocalCartSuggestions(List<CartItem> cartItems, List<FoodItem> availableItems) {
    final cartCategories = cartItems.map((c) => c.foodItem.category).toSet();
    final cartTags = cartItems.expand((c) => c.foodItem.tags).toSet();
    
    // Score items based on complementary logic
    final scored = <FoodItem, double>{};
    for (final item in availableItems) {
      double score = 0;
      
      // Complementary category bonus
      if (cartCategories.contains('Fast Food') && item.category == 'Beverages') {
        score += 3;
      }
      if (cartCategories.contains('Desi Food') && item.category == 'Beverages') {
        score += 2;
      }
      if (!cartCategories.contains(item.category)) {
        score += 1; // Variety bonus
      }
      
      // Tag matching
      final commonTags = item.tags.where((t) => cartTags.contains(t)).length;
      score += commonTags * 0.5;
      
      // Rating bonus
      score += item.rating / 5;
      
      scored[item] = score;
    }
    
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final suggestions = sorted.take(4).map((e) => e.key).toList();
    
    String message = "Complete your meal with these great additions!";
    if (cartCategories.contains('Fast Food')) {
      message = "Perfect pairs for your order! Don't forget a drink!";
    } else if (cartCategories.contains('Desi Food')) {
      message = "Add a refreshing beverage to complement your meal!";
    }
    
    return AISuggestionResult(
      suggestions: suggestions,
      aiMessage: message,
      isAIPowered: false,
    );
  }

  /// Local fallback for history-based suggestions
  AISuggestionResult _getLocalHistorySuggestions(List<OrderModel> orderHistory, List<FoodItem> allItems) {
    final orderedItemIds = <String>{};
    final categoryFrequency = <String, int>{};
    
    for (final order in orderHistory) {
      for (final cartItem in order.items) {
        orderedItemIds.add(cartItem.foodItem.id);
        final cat = cartItem.foodItem.category;
        categoryFrequency[cat] = (categoryFrequency[cat] ?? 0) + 1;
      }
    }
    
    // Find favorite category
    String? favoriteCategory;
    int maxCount = 0;
    categoryFrequency.forEach((cat, count) {
      if (count > maxCount) {
        maxCount = count;
        favoriteCategory = cat;
      }
    });
    
    // Suggest items from favorite category that haven't been ordered
    final suggestions = allItems
        .where((item) => !orderedItemIds.contains(item.id))
        .where((item) => item.category == favoriteCategory || item.rating >= 4.0)
        .take(4)
        .toList();
    
    return AISuggestionResult(
      suggestions: suggestions,
      aiMessage: favoriteCategory != null 
          ? "Since you love $favoriteCategory, try these!"
          : "Recommended just for you!",
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

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
  /// Shows personalized suggestions after user's first order
  Future<AISuggestionResult> getHistoryBasedSuggestions(String userId) async {
    try {
      final orderHistory = await _firestoreService.getUserOrderHistory(userId, limit: 10);
      final allItems = await _firestoreService.getAllFoodItems();
      
      if (orderHistory.isEmpty || allItems.isEmpty) {
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

  /// Local fallback for cart-based suggestions - SMART pairing logic
  AISuggestionResult _getLocalCartSuggestions(List<CartItem> cartItems, List<FoodItem> availableItems) {
    final cartCategories = cartItems.map((c) => c.foodItem.category).toSet();
    final cartNames = cartItems.map((c) => c.foodItem.name.toLowerCase()).toSet();
    final cartTags = cartItems.expand((c) => c.foodItem.tags).toSet();
    
    // Check what's in cart for smart suggestions
    final hasBurger = cartNames.any((n) => n.contains('burger') || n.contains('zinger'));
    final hasPizza = cartNames.any((n) => n.contains('pizza'));
    final hasBiryani = cartNames.any((n) => n.contains('biryani') || n.contains('rice'));
    final hasNoodles = cartNames.any((n) => n.contains('noodle') || n.contains('chow'));
    final hasFries = cartNames.any((n) => n.contains('fries') || n.contains('loaded'));
    final hasDrink = cartCategories.contains('Beverages') || cartNames.any((n) => 
      n.contains('drink') || n.contains('cola') || n.contains('shake') || 
      n.contains('juice') || n.contains('lassi') || n.contains('chai') || n.contains('coffee'));
    
    // Score items based on SMART complementary logic
    final scored = <FoodItem, double>{};
    for (final item in availableItems) {
      double score = 0;
      final itemName = item.name.toLowerCase();
      final isFries = itemName.contains('fries') || itemName.contains('loaded');
      final isDrink = item.category == 'Beverages' || itemName.contains('drink') || 
          itemName.contains('shake') || itemName.contains('juice') || itemName.contains('lassi');
      final isSide = itemName.contains('spring') || itemName.contains('nugget') || 
          itemName.contains('wings') || itemName.contains('roll');
      
      // BURGER LOGIC: Suggest fries, cold drinks, sides
      if (hasBurger) {
        if (isFries && !hasFries) score += 10; // Fries go great with burgers
        if (isDrink && !hasDrink) score += 8;  // Need a drink with burger
        if (isSide) score += 5; // Sides complement burgers
      }
      
      // PIZZA LOGIC: Suggest drinks, garlic bread, wings
      if (hasPizza) {
        if (isDrink && !hasDrink) score += 8;
        if (isSide) score += 6;
        if (isFries && !hasFries) score += 4;
      }
      
      // BIRYANI/DESI FOOD LOGIC: Suggest raita, lassi, salad
      if (hasBiryani) {
        if (itemName.contains('lassi') || itemName.contains('raita')) score += 10;
        if (isDrink && !hasDrink) score += 6;
      }
      
      // NOODLES LOGIC: Suggest spring rolls, drinks
      if (hasNoodles) {
        if (itemName.contains('spring') || itemName.contains('roll')) score += 8;
        if (isDrink && !hasDrink) score += 6;
      }
      
      // General: Always suggest drinks if none in cart
      if (!hasDrink && isDrink) score += 5;
      
      // General: Fries are always a good suggestion for fast food
      if (cartCategories.contains('Fast Food') && isFries && !hasFries) score += 7;
      
      // Rating bonus
      score += item.rating / 2;
      
      // Avoid suggesting same category if already have many
      if (cartCategories.contains(item.category) && cartCategories.length == 1) {
        score -= 2; // Encourage variety
      }
      
      scored[item] = score;
    }
    
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final suggestions = sorted.take(4).map((e) => e.key).toList();
    
    // Smart message based on what's in cart
    String message;
    if (hasBurger && !hasFries && !hasDrink) {
      message = "🍟 Complete your burger meal with fries and a cold drink!";
    } else if (hasBurger && !hasFries) {
      message = "🍟 Your burger needs some crispy fries!";
    } else if (hasBurger && !hasDrink) {
      message = "🥤 Don't forget a refreshing drink with your burger!";
    } else if (hasPizza) {
      message = "🍕 Perfect sides to go with your pizza!";
    } else if (hasBiryani) {
      message = "🍚 Complete your desi meal with these!";
    } else if (!hasDrink) {
      message = "🥤 Add a drink to complete your order!";
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

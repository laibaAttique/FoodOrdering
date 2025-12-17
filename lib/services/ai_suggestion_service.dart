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
  // Using Gemini 2.5 Flash model for fast, accurate suggestions
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';
  
  // ⚠️ IMPORTANT: Replace this with your actual Gemini API key
  // Get your FREE API key from: https://aistudio.google.com/app/apikey
  // The local smart suggestions will work without an API key
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';
  
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
      if (kDebugMode) {
        print('=== AI HISTORY SUGGESTIONS DEBUG ===');
        print('Getting order history for user: $userId');
      }
      
      final orderHistory = await _firestoreService.getUserOrderHistory(userId, limit: 10);
      final allItems = await _firestoreService.getAllFoodItems();
      
      if (kDebugMode) {
        print('Order history count: ${orderHistory.length}');
        print('All items count: ${allItems.length}');
        if (orderHistory.isNotEmpty) {
          print('First order items: ${orderHistory.first.items.map((i) => i.foodItem.name).toList()}');
        }
      }
      
      if (orderHistory.isEmpty || allItems.isEmpty) {
        // New user with no order history - return empty suggestions
        // The regular menu sections will show instead
        if (kDebugMode) {
          print('No order history or no items - returning empty suggestions');
        }
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

  /// Call Gemini API with proper error handling
  Future<String?> _callGeminiAPI(String prompt) async {
    // Skip API call if using placeholder key - use local suggestions instead
    if (_apiKey.contains('YOUR_') || _apiKey.contains('Demo') || _apiKey.contains('Replace') || _apiKey.length < 20) {
      if (kDebugMode) {
        print('Gemini API: Using local suggestions (no valid API key configured)');
      }
      return null;
    }
    
    try {
      if (kDebugMode) {
        print('Gemini API: Calling with prompt length ${prompt.length}');
      }
      
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
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (kDebugMode) {
          print('Gemini API: Success - got response');
        }
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
    final cartNames = cartItems.map((c) => c.foodItem.name.toLowerCase()).toList();
    final cartTags = cartItems.expand((c) => c.foodItem.tags).toSet();
    
    if (kDebugMode) {
      print('=== AI CART SUGGESTIONS DEBUG ===');
      print('Cart items: $cartNames');
      print('Cart categories: $cartCategories');
      print('Available items count: ${availableItems.length}');
    }
    
    // Detect food types in cart - check BOTH name AND category
    final hasBurger = cartNames.any((n) => n.contains('burger') || n.contains('zinger'));
    final hasPizza = cartNames.any((n) => n.contains('pizza'));
    final hasBiryani = cartNames.any((n) => n.contains('biryani'));
    final hasRice = cartNames.any((n) => n.contains('rice') || n.contains('pulao'));
    final hasNoodles = cartNames.any((n) => n.contains('noodle') || n.contains('chow mein') || n.contains('hakka') || n.contains('chow'));
    final hasChinese = cartCategories.contains('Chinese') || cartNames.any((n) => n.contains('manchurian') || n.contains('chow') || n.contains('spring roll') || n.contains('fried rice') || (n.contains('sweet') && n.contains('sour')));
    final hasFries = cartNames.any((n) => n.contains('fries') || n.contains('loaded'));
    final hasDesiFood = cartCategories.contains('Desi Food') || hasBiryani;
    final hasFastFood = cartCategories.contains('Fast Food') || hasBurger || hasPizza;
    final hasDrink = cartCategories.contains('Beverages') || cartNames.any((n) => 
      n.contains('drink') || n.contains('cola') || n.contains('shake') || 
      n.contains('juice') || n.contains('lassi') || n.contains('chai') || n.contains('coffee'));
    
    if (kDebugMode) {
      print('hasChinese: $hasChinese, hasBurger: $hasBurger, hasPizza: $hasPizza');
      print('hasDesiFood: $hasDesiFood, hasFastFood: $hasFastFood, hasDrink: $hasDrink');
      print('hasNoodles: $hasNoodles, hasFries: $hasFries');
    }
    
    // Score items based on SMART complementary logic
    final scored = <FoodItem, double>{};
    for (final item in availableItems) {
      double score = 0;
      final itemName = item.name.toLowerCase();
      final itemCategory = item.category;
      
      // Item type detection
      final isFries = itemName.contains('fries') || itemName.contains('loaded');
      final isDrink = itemCategory == 'Beverages';
      final isColdDrink = isDrink && (itemName.contains('shake') || itemName.contains('juice') || itemName.contains('cold') || itemName.contains('lassi'));
      final isHotDrink = isDrink && (itemName.contains('chai') || itemName.contains('coffee'));
      final isSide = itemName.contains('spring roll') || itemName.contains('nugget') || itemName.contains('wings') || itemName.contains('samosa');
      final isChinese = itemName.contains('manchurian') || itemName.contains('chow') || itemName.contains('spring') || itemName.contains('noodle') || itemName.contains('fried rice');
      final isDesi = itemCategory == 'Desi Food' || itemName.contains('biryani') || itemName.contains('karahi') || itemName.contains('nihari');
      
      // ========== CHINESE FOOD LOGIC ==========
      if (hasChinese || hasNoodles) {
        // Chinese food pairs well with: spring rolls, fried rice, noodles, cold drinks
        if (itemName.contains('spring') && !cartNames.any((n) => n.contains('spring'))) score += 15;
        if ((itemName.contains('fried rice') || itemName.contains('rice')) && itemCategory == 'Chinese' && !cartNames.any((n) => n.contains('rice'))) score += 12;
        if ((itemName.contains('noodle') || itemName.contains('chow') || itemName.contains('hakka')) && !hasNoodles) score += 10;
        if (itemName.contains('sweet') && itemName.contains('sour')) score += 8;
        // Suggest other Chinese items
        if (itemCategory == 'Chinese' && !cartNames.any((n) => itemName.contains(n))) score += 6;
        if (isColdDrink && !hasDrink) score += 5;
        // Avoid suggesting more manchurian if already have it
        if (itemName.contains('manchurian') && cartNames.any((n) => n.contains('manchurian'))) score -= 15;
      }
      
      // ========== BURGER LOGIC ==========
      if (hasBurger) {
        if (isFries && !hasFries) score += 12;
        if (isColdDrink && !hasDrink) score += 10;
        if (itemName.contains('wings') || itemName.contains('nugget')) score += 6;
      }
      
      // ========== PIZZA LOGIC ==========
      if (hasPizza) {
        if (isColdDrink && !hasDrink) score += 10;
        if (itemName.contains('wings') || itemName.contains('garlic')) score += 8;
        if (isFries && !hasFries) score += 6;
      }
      
      // ========== DESI FOOD LOGIC ==========
      if (hasDesiFood || hasBiryani) {
        // Desi food pairs with: lassi, raita, salad, naan
        if (itemName.contains('lassi')) score += 12;
        if (itemName.contains('raita') || itemName.contains('salad')) score += 10;
        if (itemName.contains('naan') || itemName.contains('roti')) score += 8;
        if (isHotDrink) score += 5; // Chai goes with desi food
      }
      
      // ========== GENERAL RULES ==========
      // Always suggest a drink if none in cart
      if (!hasDrink && isDrink) score += 4;
      
      // Fast food gets fries suggestion
      if (hasFastFood && isFries && !hasFries) score += 8;
      
      // Rating bonus (small)
      score += item.rating * 0.3;
      
      // Variety bonus - suggest different categories
      if (!cartCategories.contains(itemCategory)) score += 2;
      
      // Penalize same exact type of food
      if (cartNames.any((n) => itemName.contains(n) || n.contains(itemName))) score -= 5;
      
      scored[item] = score;
    }
    
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Only take items with positive scores
    final suggestions = sorted.where((e) => e.value > 0).take(4).map((e) => e.key).toList();
    
    if (kDebugMode) {
      print('Top scored items:');
      for (var entry in sorted.take(6)) {
        print('  ${entry.key.name}: ${entry.value}');
      }
      print('Final suggestions: ${suggestions.map((s) => s.name).toList()}');
    }
    
    // Smart message based on what's in cart
    String message;
    if (hasChinese || hasNoodles) {
      message = "🥢 Complete your Chinese meal with these!";
    } else if (hasBurger && !hasFries && !hasDrink) {
      message = "🍟 Complete your burger meal with fries and a cold drink!";
    } else if (hasBurger && !hasFries) {
      message = "🍟 Your burger needs some crispy fries!";
    } else if (hasBurger && !hasDrink) {
      message = "🥤 Don't forget a refreshing drink with your burger!";
    } else if (hasPizza) {
      message = "🍕 Perfect sides to go with your pizza!";
    } else if (hasDesiFood || hasBiryani) {
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

  /// Local fallback for history-based suggestions - SMART recommendations
  AISuggestionResult _getLocalHistorySuggestions(List<OrderModel> orderHistory, List<FoodItem> allItems) {
    final orderedItemIds = <String>{};
    final orderedItemNames = <String>{};
    final categoryFrequency = <String, int>{};
    final itemFrequency = <String, int>{}; // Track how often each item was ordered
    
    for (final order in orderHistory) {
      for (final cartItem in order.items) {
        orderedItemIds.add(cartItem.foodItem.id);
        orderedItemNames.add(cartItem.foodItem.name.toLowerCase());
        final cat = cartItem.foodItem.category;
        categoryFrequency[cat] = (categoryFrequency[cat] ?? 0) + cartItem.quantity;
        itemFrequency[cartItem.foodItem.id] = (itemFrequency[cartItem.foodItem.id] ?? 0) + cartItem.quantity;
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
    
    // Detect user preferences from order history
    final likesChinese = orderedItemNames.any((n) => n.contains('manchurian') || n.contains('noodle') || n.contains('chow') || n.contains('spring'));
    final likesBurgers = orderedItemNames.any((n) => n.contains('burger') || n.contains('zinger'));
    final likesDesi = orderedItemNames.any((n) => n.contains('biryani') || n.contains('karahi') || n.contains('nihari'));
    final likesPizza = orderedItemNames.any((n) => n.contains('pizza'));
    
    // Score all items for personalized suggestions
    final scored = <FoodItem, double>{};
    for (final item in allItems) {
      double score = 0;
      final itemName = item.name.toLowerCase();
      
      // Boost items from favorite category that user HASN'T tried yet
      if (item.category == favoriteCategory && !orderedItemIds.contains(item.id)) {
        score += 15; // High priority - new items from favorite category
      }
      
      // Suggest similar items to what user likes
      if (likesChinese && (itemName.contains('manchurian') || itemName.contains('noodle') || itemName.contains('chow') || itemName.contains('spring') || itemName.contains('fried rice'))) {
        if (!orderedItemIds.contains(item.id)) score += 12;
      }
      if (likesBurgers && (itemName.contains('burger') || itemName.contains('zinger') || itemName.contains('fries') || itemName.contains('wings'))) {
        if (!orderedItemIds.contains(item.id)) score += 12;
      }
      if (likesDesi && (itemName.contains('biryani') || itemName.contains('karahi') || itemName.contains('nihari') || itemName.contains('haleem'))) {
        if (!orderedItemIds.contains(item.id)) score += 12;
      }
      if (likesPizza && (itemName.contains('pizza') || itemName.contains('garlic'))) {
        if (!orderedItemIds.contains(item.id)) score += 12;
      }
      
      // Highly rated items user hasn't tried
      if (!orderedItemIds.contains(item.id) && item.rating >= 4.5) {
        score += 8;
      }
      
      // Items user has ordered before and might want to reorder
      if (orderedItemIds.contains(item.id)) {
        final orderCount = itemFrequency[item.id] ?? 0;
        if (orderCount >= 2) {
          score += 5; // User orders this frequently - suggest reorder
        }
      }
      
      // Rating bonus
      score += item.rating * 0.5;
      
      scored[item] = score;
    }
    
    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final suggestions = sorted.where((e) => e.value > 0).take(4).map((e) => e.key).toList();
    
    // Generate personalized message
    String message;
    if (likesChinese) {
      message = "🥢 Based on your love for Chinese food, try these!";
    } else if (likesBurgers) {
      message = "🍔 Since you enjoy burgers, you might like these!";
    } else if (likesDesi) {
      message = "🍛 Based on your desi food orders, try these!";
    } else if (likesPizza) {
      message = "🍕 Pizza lover? Check out these recommendations!";
    } else if (favoriteCategory != null) {
      message = "✨ Since you love $favoriteCategory, try these!";
    } else {
      message = "🌟 Recommended just for you!";
    }
    
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

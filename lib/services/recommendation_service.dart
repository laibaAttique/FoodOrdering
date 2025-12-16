import 'package:flutter/foundation.dart';
import '../models/food_item.dart';
import '../models/order_model.dart';
import 'firestore_service.dart';

/// Recommendation Service
/// AI-based food recommendation engine
/// Analyzes user order history to generate personalized suggestions
class RecommendationService {
  final FirestoreService _firestoreService = FirestoreService();

  /// Get personalized recommendations for user
  Future<List<FoodItem>> getPersonalizedRecommendations(String userId) async {
    try {
      // Get user's order history
      final orderHistory = await _firestoreService.getUserOrderHistory(userId, limit: 20);
      
      if (orderHistory.isEmpty) {
        // New user - return popular items
        return await _getPopularItems();
      }

      // Analyze order patterns
      final itemFrequency = <String, int>{};
      final categoryFrequency = <String, int>{};
      final orderedItems = <String, FoodItem>{};

      for (final order in orderHistory) {
        for (final cartItem in order.items) {
          final foodItem = cartItem.foodItem;
          
          // Track item frequency
          itemFrequency[foodItem.id] = (itemFrequency[foodItem.id] ?? 0) + 1;
          
          // Track category frequency
          categoryFrequency[foodItem.category] = 
              (categoryFrequency[foodItem.category] ?? 0) + 1;
          
          // Store item details
          orderedItems[foodItem.id] = foodItem;
        }
      }

      // Get all available food items
      final allItems = await _firestoreService.getAllFoodItems();
      
      // Calculate recommendation scores
      final recommendations = <FoodItem, double>{};
      
      for (final item in allItems) {
        // Skip items user has ordered recently
        if (itemFrequency.containsKey(item.id) && itemFrequency[item.id]! > 2) {
          continue;
        }

        double score = 0.0;

        // Category preference (40% weight)
        final categoryScore = (categoryFrequency[item.category] ?? 0) / orderHistory.length;
        score += categoryScore * 0.4;

        // Rating (30% weight)
        score += (item.rating / 5.0) * 0.3;

        // Promotional items (20% weight)
        if (item.isPromotional) {
          score += 0.2;
        }

        // Seasonal items (10% weight)
        if (item.isSeasonal) {
          score += 0.1;
        }

        // Similar items to what user ordered (bonus)
        for (final orderedItem in orderedItems.values) {
          if (item.category == orderedItem.category && item.id != orderedItem.id) {
            score += 0.15;
          }
          
          // Check for similar tags
          final commonTags = item.tags.where((tag) => orderedItem.tags.contains(tag)).length;
          score += commonTags * 0.05;
        }

        recommendations[item] = score;
      }

      // Sort by score and return top recommendations
      final sortedRecommendations = recommendations.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topRecommendations = sortedRecommendations
          .take(10)
          .map((entry) => entry.key)
          .toList();

      if (kDebugMode) {
        print('Generated ${topRecommendations.length} recommendations for user $userId');
      }

      return topRecommendations;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating recommendations: $e');
      }
      return await _getPopularItems();
    }
  }

  /// Get popular items (fallback for new users)
  Future<List<FoodItem>> _getPopularItems() async {
    try {
      final allItems = await _firestoreService.getAllFoodItems();
      
      // Sort by rating and review count
      allItems.sort((a, b) {
        final scoreA = a.rating * a.reviews;
        final scoreB = b.rating * b.reviews;
        return scoreB.compareTo(scoreA);
      });

      return allItems.take(10).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting popular items: $e');
      }
      return [];
    }
  }

  /// Get items similar to a specific item
  Future<List<FoodItem>> getSimilarItems(FoodItem item) async {
    try {
      final allItems = await _firestoreService.getAllFoodItems();
      
      final similarItems = <FoodItem, double>{};
      
      for (final otherItem in allItems) {
        if (otherItem.id == item.id) continue;

        double similarity = 0.0;

        // Same category (50% weight)
        if (otherItem.category == item.category) {
          similarity += 0.5;
        }

        // Similar price range (20% weight)
        final priceDiff = (otherItem.effectivePrice - item.effectivePrice).abs();
        if (priceDiff < 50) {
          similarity += 0.2;
        }

        // Common tags (30% weight)
        final commonTags = otherItem.tags.where((tag) => item.tags.contains(tag)).length;
        similarity += (commonTags / item.tags.length) * 0.3;

        if (similarity > 0.3) {
          similarItems[otherItem] = similarity;
        }
      }

      // Sort by similarity and return top 5
      final sortedSimilar = similarItems.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedSimilar.take(5).map((entry) => entry.key).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting similar items: $e');
      }
      return [];
    }
  }

  /// Get trending items (most ordered in last 7 days)
  Future<List<FoodItem>> getTrendingItems() async {
    try {
      // In a real implementation, this would query orders from last 7 days
      // For now, return promotional items
      return await _firestoreService.getPromotionalItems();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting trending items: $e');
      }
      return [];
    }
  }
}

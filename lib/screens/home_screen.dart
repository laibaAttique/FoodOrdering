import 'package:flutter/material.dart';
import '../models/food_item.dart';

/// Home Screen
/// Main dashboard showing food items organized in categories
/// Users can browse items, search, and add to cart
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, this.userName}) : super(key: key);

  // User's name passed from signup
  final String? userName;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State class for HomeScreen
class _HomeScreenState extends State<HomeScreen> {
  // Store cart items count for badge
  int _cartItemCount = 0;
  
  // Store user name
  late String _displayName;

  @override
  void initState() {
    super.initState();
    // Use passed userName or default to "Guest"
    _displayName = widget.userName ?? 'Guest';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with search and cart
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        title: const Text(
          'BitesBuzz',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              // Navigate to search screen
              Navigator.pushNamed(context, '/search');
            },
          ),
          // Cart button with badge
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
                // Cart badge
                if (_cartItemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$_cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $_displayName! 👋',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'What would you like to order today?',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Quick category filter using ListView.builder
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: getAllCategories().length,
                      itemBuilder: (context, index) {
                        final category = getAllCategories()[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            onSelected: (selected) {
                              // TODO: Filter items by category
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Food items sections - dynamically built using ListView.builder
            ..._buildFoodSections(),
          ],
        ),
      ),
    );
  }

  /// Build food sections with ListView.builder
  /// Each section contains items from a specific category
  List<Widget> _buildFoodSections() {
    final categories = getAllCategories();
    return categories.map((category) {
      return _buildFoodSection(category);
    }).toList();
  }

  /// Build a single food section
  /// Uses ListView.builder for dynamic item rendering
  Widget _buildFoodSection(String category) {
    final items = getItemsByCategory(category);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/menu');
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFFFF6B35),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Horizontal scrollable list of food items
          // Using ListView.builder for dynamic rendering
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildFoodItemCard(items[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual food item card
  /// Displays: emoji, name, price, rating, and add button
  Widget _buildFoodItemCard(FoodItem item) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDDDDD)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food emoji/image placeholder
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                item.emoji,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
          // Food details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Price
                  Text(
                    'PKR ${item.price}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Rating
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFFFA500),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${item.rating} (${item.reviews})',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Add to cart button
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () {
                        _addToCart(item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        'Add',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle adding item to cart
  void _addToCart(FoodItem item) {
    setState(() {
      _cartItemCount++;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart! 🍕'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }
}

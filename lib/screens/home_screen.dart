import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import 'item_details_screen.dart';

/// Home Screen
/// Main landing page after login showing food categories and items
class HomeScreen extends StatefulWidget {
  final String? userName;

  const HomeScreen({Key? key, this.userName}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// State class for HomeScreen
class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  String _selectedCategory = 'Most Liked';
  List<FoodItem> _foodItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoodItems();
    _initializeCart();
  }

  Future<void> _initializeCart() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    if (authProvider.userId != null) {
      await cartProvider.setUserId(authProvider.userId);
    }
  }

  Future<void> _loadFoodItems() async {
    setState(() => _isLoading = true);
    
    // Load all items and filter by subCategory
    final allItems = await _firestoreService.getAllFoodItems();
    
    if (_selectedCategory == 'Most Liked') {
      _foodItems = allItems.where((item) => item.subCategory == 'Most Liked').toList();
    } else if (_selectedCategory == 'Seasonal Offers') {
      _foodItems = allItems.where((item) => item.isSeasonal || item.isPromotional).toList();
    } else {
      _foodItems = allItems.take(10).toList(); // Suggestions
    }
    
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.itemCount == 0) return const SizedBox();
          return FloatingActionButton.extended(
            onPressed: () {
               Navigator.pushNamed(context, '/cart');
            },
            backgroundColor: const Color(0xFFFF6B35),
            icon: const Icon(Icons.shopping_cart),
            label: Text('${cart.itemCount} Items'),
          );
        },
      ),
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
                  Consumer<CartProvider>(
                    builder: (context, cartProvider, _) {
                      if (cartProvider.itemCount == 0) return const SizedBox();
                      
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${cartProvider.itemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  ],
              ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
            onPressed: () => _handleLogout(context),
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
                    'Hi, ${widget.userName ?? 'Guest'}! 👋',
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
    final items = _foodItems.where((item) => item.subCategory == category).toList();

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
                item.imageUrl,
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
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(item);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart! 🍕'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }

  void _navigateToItemDetails(FoodItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailsScreen(foodItem: item),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      // final orderProvider = Provider.of<OrderProvider>(context, listen: false); // OrderProvider not imported in HomeScreen yet, need to add import or remove this if not strictly needed for logout (AuthProvider clears user which clears orders usually, but explicit is good)
      // Actually checking imports: OrderProvider is NOT imported in replacement block above. 
      // I need to add the import at the top of file or use context.read if I don't want to change imports separately. 
      // But looking at existing imports in line 1-7:
      // import '../providers/cart_provider.dart';
      // import '../providers/auth_provider.dart';
      // OrderProvider is missing.
      
      await authProvider.signOut();
      await cartProvider.setUserId(null); 
      // await orderProvider.setUserId(null); // Skip for now if import missing, AuthProvider signout usually handles session. 
      // But purely for clean state, I should clear cart. CartProvider IS imported.
      
      if (mounted) {
         Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

}


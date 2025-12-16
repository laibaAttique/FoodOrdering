import 'package:flutter/material.dart';
import '../models/food_item.dart';

/// Search Screen
/// Allows users to search for food items dynamically
/// Uses ListView.builder to display search results
class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

/// State class for SearchScreen - handles search logic
class _SearchScreenState extends State<SearchScreen> {
  // Search controller to capture user input
  final _searchController = TextEditingController();

  // List to store search results
  List<FoodItem> _searchResults = [];

  // Track if user has performed a search
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Listen to search input changes for real-time filtering
    _searchController.addListener(_performSearch);
  }

  /// Perform real-time search based on user input
  /// Searches through food items by name and category
  void _performSearch() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    // Filter food items by name or category
    final results = allFoodItems.where((item) {
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  @override
  void dispose() {
    // Clean up controller when widget is disposed
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Search Food',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar section
          Container(
            color: const Color(0xFFFF6B35),
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or category...',
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF666666)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF666666)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Search results or empty state
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  /// Build search results using ListView.builder
  /// Dynamically displays matching food items
  Widget _buildSearchResults() {
    // No search performed yet
    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: const Color(0xFFDDDDDD),
            ),
            const SizedBox(height: 16),
            const Text(
              'Start searching for food items',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Search by name (e.g., Pizza) or category',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
      );
    }

    // No results found
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_food,
              size: 64,
              color: const Color(0xFFDDDDDD),
            ),
            const SizedBox(height: 16),
            const Text(
              'No items found',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF999999),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFCCCCCC),
              ),
            ),
          ],
        ),
      );
    }

    // Display search results using ListView.builder
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return _buildSearchResultItem(_searchResults[index]);
      },
    );
  }

  /// Build individual search result item
  /// Displays food item in a list format with all details
  Widget _buildSearchResultItem(FoodItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Food emoji/image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  item.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Food details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food name
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Category
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Price and rating row
                  Row(
                    children: [
                      // Price
                      Text(
                        'PKR ${item.price}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                      ),
                      const Spacer(),
                      // Rating
                      const Icon(
                        Icons.star,
                        size: 12,
                        color: Color(0xFFFFA500),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${item.rating} (${item.reviews})',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Add button
            SizedBox(
              width: 40,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  _addToCart(item);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle adding item to cart
  void _addToCart(FoodItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart! 🍕'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }
}

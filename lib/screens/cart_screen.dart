import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/huggingface_ai_service.dart';
import '../widgets/ai_suggestions_widget.dart';

/// Cart Screen
/// Displays shopping cart with item management
class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final HuggingFaceAIService _aiService = HuggingFaceAIService();
  AISuggestionResult? _aiSuggestions;
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    // Delay AI loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAISuggestions();
    });
  }

  Future<void> _loadAISuggestions() async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.items.isEmpty) return;
    
    if (mounted) setState(() => _isLoadingAI = true);
    try {
      final result = await _aiService.getCartBasedSuggestions(cartProvider.items);
      if (mounted) {
        setState(() {
          _aiSuggestions = result;
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (cartProvider.isEmpty) {
            return _buildEmptyCart(context);
          }

          return Column(
            children: [
              // Cart items list with AI suggestions
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Cart items
                    ...cartProvider.items.map((cartItem) => 
                      _buildCartItem(context, cartItem, cartProvider)
                    ),
                    
                    // AI Suggestions Section
                    if (_isLoadingAI)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF6B35).withOpacity(0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'AI is finding suggestions...',
                              style: TextStyle(color: Color(0xFF666666), fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    else if (_aiSuggestions != null && _aiSuggestions!.suggestions.isNotEmpty)
                      AISuggestionsWidget(
                        suggestions: _aiSuggestions!.suggestions,
                        message: _aiSuggestions!.aiMessage,
                        isAIPowered: _aiSuggestions!.isAIPowered,
                        onRefresh: _loadAISuggestions,
                      ),
                  ],
                ),
              ),

              // Cart summary
              _buildCartSummary(context, cartProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add items to get started',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Browse Menu'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, cartItem, CartProvider cartProvider) {
    final foodItem = cartItem.foodItem;
    
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
            // Food image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  foodItem.imageUrl,
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
                  Text(
                    foodItem.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${foodItem.effectivePrice}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Quantity controls
                  Row(
                    children: [
                      // Decrease button
                      InkWell(
                        onTap: () {
                          cartProvider.decrementQuantity(cartItem.id);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFF6B35)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.remove,
                            size: 16,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Quantity
                      Text(
                        '${cartItem.quantity}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Increase button
                      InkWell(
                        onTap: () {
                          cartProvider.incrementQuantity(cartItem.id);
                        },
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              onPressed: () {
                _showRemoveDialog(context, cartItem, cartProvider);
              },
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  'PKR ${cartProvider.subtotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Delivery fee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Delivery Fee',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
                Text(
                  'PKR ${cartProvider.deliveryFee.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'PKR ${cartProvider.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Checkout button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.isLoggedIn) {
                    Navigator.pushNamed(context, '/checkout');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please login to checkout'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, cartItem, CartProvider cartProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${cartItem.foodItem.name} from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cartProvider.removeItem(cartItem.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Item removed from cart'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            child: const Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

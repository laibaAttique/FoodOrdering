import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_item.dart';
import '../providers/cart_provider.dart';
import '../services/huggingface_ai_service.dart';

/// AI Suggestions Widget
/// Displays AI-powered food recommendations with a modern UI
class AISuggestionsWidget extends StatefulWidget {
  final List<FoodItem> suggestions;
  final String message;
  final bool isAIPowered;
  final VoidCallback? onRefresh;

  const AISuggestionsWidget({
    Key? key,
    required this.suggestions,
    required this.message,
    this.isAIPowered = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<AISuggestionsWidget> createState() => _AISuggestionsWidgetState();
}

class _AISuggestionsWidgetState extends State<AISuggestionsWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF6B35).withOpacity(0.1),
            const Color(0xFFFF8C42).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B35).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // AI Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'AI Suggestions',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.isAIPowered)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.onRefresh != null)
                  IconButton(
                    onPressed: widget.onRefresh,
                    icon: const Icon(
                      Icons.refresh,
                      color: Color(0xFFFF6B35),
                    ),
                    tooltip: 'Refresh suggestions',
                  ),
              ],
            ),
          ),
          
          // Suggestions horizontal list
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              itemCount: widget.suggestions.length,
              itemBuilder: (context, index) {
                return _buildSuggestionCard(widget.suggestions[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(FoodItem item) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food emoji/image
          Container(
            width: double.infinity,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                item.imageUrl,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PKR ${item.effectivePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  const Spacer(),
                  // Add button
                  SizedBox(
                    width: double.infinity,
                    height: 28,
                    child: ElevatedButton(
                      onPressed: () => _addToCart(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B35),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 14, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Add',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ],
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

  void _addToCart(FoodItem item) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.addItem(item);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.name} added to cart!'),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFFFF6B35),
      ),
    );
  }
}

/// Async loader widget for AI suggestions
class AISuggestionsLoader extends StatefulWidget {
  final Future<AISuggestionResult> Function() loadSuggestions;

  const AISuggestionsLoader({
    Key? key,
    required this.loadSuggestions,
  }) : super(key: key);

  @override
  State<AISuggestionsLoader> createState() => _AISuggestionsLoaderState();
}

class _AISuggestionsLoaderState extends State<AISuggestionsLoader> {
  AISuggestionResult? _result;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.loadSuggestions();
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.all(16),
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
              'AI is thinking...',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null || _result == null) {
      return const SizedBox.shrink();
    }

    return AISuggestionsWidget(
      suggestions: _result!.suggestions,
      message: _result!.aiMessage,
      isAIPowered: _result!.isAIPowered,
      onRefresh: _loadSuggestions,
    );
  }
}

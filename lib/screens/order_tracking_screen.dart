import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final MapController _mapController = MapController();

  LatLng? _lastCenter;

  final Random _random = Random();

  LatLng _fallbackCenter() {
    return const LatLng(31.5204, 74.3587);
  }

  LatLng _centerForOrder(OrderModel order) {
    final loc = order.deliveryLocation;
    final lat = loc?['lat'];
    final lng = loc?['lng'];

    if (lat == null || lng == null) {
      return _fallbackCenter();
    }

    return LatLng(lat, lng);
  }

  void _moveIfNeeded(LatLng center) {
    if (_lastCenter == null || _lastCenter != center) {
      _lastCenter = center;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(center, 15);
      });
    }
  }

  Future<void> _simulateMove(BuildContext context, OrderModel order) async {
    final orderProvider = context.read<OrderProvider>();

    final current = _centerForOrder(order);
    final jitterLat = (_random.nextDouble() - 0.5) * 0.002;
    final jitterLng = (_random.nextDouble() - 0.5) * 0.002;

    final nextLat = current.latitude + jitterLat;
    final nextLng = current.longitude + jitterLng;

    await orderProvider.updateDeliveryLocation(
      order.id,
      lat: nextLat,
      lng: nextLng,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.read<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF6B35),
        elevation: 0,
        title: const Text(
          'Track Order',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<OrderModel?>(
        stream: orderProvider.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          final center = _centerForOrder(order);
          _moveIfNeeded(center);

          final hasLocation = order.deliveryLocation != null &&
              order.deliveryLocation?['lat'] != null &&
              order.deliveryLocation?['lng'] != null;

          return Column(
            children: [
              Expanded(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'bites_buzz',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: center,
                          width: 56,
                          height: 56,
                          child: Container(
                            decoration: BoxDecoration(
                              color: hasLocation
                                  ? const Color(0xFFFF6B35)
                                  : const Color(0xFF999999),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.delivery_dining,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, order.id.length >= 8 ? 8 : order.id.length)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.statusText,
                            style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.orderType == OrderType.delivery
                          ? 'Delivery'
                          : 'Pickup',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                    if (order.orderType == OrderType.delivery) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _simulateMove(context, order),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B35),
                            side: const BorderSide(color: Color(0xFFFF6B35)),
                          ),
                          child: const Text('Simulate Rider Movement'),
                        ),
                      ),
                    ],
                    if (!hasLocation) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Tracking will appear once a delivery location is available.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFF6B35),
        onPressed: () {
          final center = _lastCenter ?? _fallbackCenter();
          _mapController.move(center, 15);
        },
        child: const Icon(Icons.my_location, color: Colors.white),
      ),
    );
  }
}

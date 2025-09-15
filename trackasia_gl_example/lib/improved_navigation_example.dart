import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';

import 'page.dart';

/// Improved Navigation Example using native NavigationMapRoute
class ImprovedNavigationExamplePage extends ExamplePage {
  const ImprovedNavigationExamplePage({super.key}) : super(const Icon(Icons.navigation), 'Improved Navigation Example');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Improved Navigation Example'),
        backgroundColor: Colors.blue,
      ),
      body: const ImprovedNavigationExample(),
    );
  }
}

class ImprovedNavigationExample extends StatefulWidget {
  const ImprovedNavigationExample({super.key});

  @override
  State<ImprovedNavigationExample> createState() => _ImprovedNavigationExampleState();
}

class _ImprovedNavigationExampleState extends State<ImprovedNavigationExample> {
  TrackAsiaMapController? _mapController;
  NavigationMapRoute? _navigationMapRoute;
  NavigationRoute? _currentRoute;

  bool _isCalculatingRoute = false;
  bool _isNavigating = false;
  String _routeInfo = 'Chưa có tuyến đường';
  String _statusMessage = 'Sẵn sàng tính toán tuyến đường';

  // Sample waypoints matching MapWayPointFragment.kt defaults
  final List<LatLng> _sampleWaypoints = [
    const LatLng(10.728073, 106.624054), // Default location from MapWayPointFragment
    const LatLng(10.8231, 106.6297), // Airport from MapWayPointFragment
  ];

  void _onMapCreated(TrackAsiaMapController controller) {
    _mapController = controller;
    _navigationMapRoute = controller.createNavigationMapRoute();

    setState(() {
      _statusMessage = 'Bản đồ đã sẵn sàng';
    });
  }

  /// Calculate route using improved native integration
  Future<void> _calculateRoute() async {
    if (_mapController == null || _navigationMapRoute == null) {
      _showSnackBar('Bản đồ chưa sẵn sàng', isError: true);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _statusMessage = 'Đang tính toán tuyến đường...';
      _routeInfo = 'Đang xử lý...';
    });

    try {
      // Use the navigation extension to calculate route
      // This calls native NavigationMethodHandler.calculateRoute with proper API
      final route = await _mapController!.navigation.calculateRoute(
        waypoints: _sampleWaypoints,
        options: NavigationOptions(
          profile: NavigationProfile.car,
          language: 'vi',
          simulateRoute: true,
        ),
      );

      if (route != null) {
        setState(() {
          _currentRoute = route;
          _routeInfo = 'Khoảng cách: ${(route.distance / 1000).toStringAsFixed(1)} km\n'
              'Thời gian: ${(route.duration / 60).toStringAsFixed(0)} phút';
          _statusMessage = 'Tuyến đường đã được tính toán';
        });

        // Add route to map using native NavigationMapRoute
        await _navigationMapRoute!.addRoute(
          route,
          style: RouteStyle.primary(),
          isPrimary: true,
        );

        // Fit camera to show route
        await _navigationMapRoute!.fitCameraToRoutes(
          padding: const EdgeInsets.all(50),
        );

        _showSnackBar('Đã tính toán và hiển thị tuyến đường thành công');
      } else {
        setState(() {
          _statusMessage = 'Không thể tính toán tuyến đường';
        });
        _showSnackBar('Không thể tính toán tuyến đường', isError: true);
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi: ${e.toString()}';
      });
      _showSnackBar('Lỗi tính toán tuyến đường: $e', isError: true);
    } finally {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  /// Start navigation using native NavigationLauncher
  Future<void> _startNavigation() async {
    if (_currentRoute == null) {
      _showSnackBar('Chưa có tuyến đường để điều hướng', isError: true);
      return;
    }

    try {
      setState(() {
        _isNavigating = true;
        _statusMessage = 'Đang khởi động điều hướng...';
      });

      // Use the navigation extension to start navigation
      // This calls native NavigationMethodHandler.startNavigation -> NavigationLauncher.startNavigation
      await _mapController!.navigation.startNavigation(
        route: _currentRoute!,
        options: NavigationOptions(
          simulateRoute: true, // Enable simulation for testing
          enableVoiceGuidance: true,
          enableRerouting: true,
        ),
      );

      setState(() {
        _statusMessage = 'Điều hướng đã được khởi động';
      });

      _showSnackBar('Điều hướng đã bắt đầu (chế độ mô phỏng)');
    } catch (e) {
      setState(() {
        _statusMessage = 'Lỗi khởi động điều hướng: ${e.toString()}';
        _isNavigating = false;
        debugPrint('Lỗi khởi động điều hướng: ${e.toString()}');
      });
      _showSnackBar('Lỗi khởi động điều hướng: $e', isError: true);
      debugPrint('Lỗi khởi động điều hướng: ${e.toString()}');
    }
  }

  /// Add multiple routes with different profiles
  Future<void> _addMultipleRoutes() async {
    if (_mapController == null || _navigationMapRoute == null) {
      _showSnackBar('Bản đồ chưa sẵn sàng', isError: true);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _statusMessage = 'Đang tính toán nhiều tuyến đường...';
    });

    try {
      final routes = <NavigationRoute>[];
      final profiles = [NavigationProfile.car, NavigationProfile.walk, NavigationProfile.moto];

      // Calculate routes with different profiles
      for (final profile in profiles) {
        try {
          final route = await _mapController!.navigation.calculateRoute(
            waypoints: _sampleWaypoints,
            options: NavigationOptions(
              profile: profile,
              language: 'vi',
            ),
          );
          if (route != null) {
            routes.add(route);
          }
        } catch (e) {
          print('Error calculating route for ${profile.name}: $e');
        }
      }

      if (routes.isNotEmpty) {
        // Add multiple routes with different styling
        await _navigationMapRoute!.addRoutes(
          routes,
          primaryStyle: RouteStyle.primary(),
          alternativeStyle: RouteStyle.alternative(),
        );

        setState(() {
          _routeInfo = 'Đã thêm ${routes.length} tuyến đường\n'
              'Xe hơi, Đi bộ, Xe máy';
          _statusMessage = 'Đã thêm ${routes.length} tuyến đường thành công';
        });

        // Fit camera to show all routes
        await _navigationMapRoute!.fitCameraToRoutes(
          padding: const EdgeInsets.all(50),
        );

        _showSnackBar('Đã thêm ${routes.length} tuyến đường');
      } else {
        _showSnackBar('Không thể tính toán tuyến đường nào', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi thêm nhiều tuyến đường: $e', isError: true);
    } finally {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  /// Clear all routes
  Future<void> _clearRoutes() async {
    if (_navigationMapRoute == null) return;

    try {
      await _navigationMapRoute!.clearRoutes();
      setState(() {
        _currentRoute = null;
        _routeInfo = 'Chưa có tuyến đường';
        _statusMessage = 'Đã xóa tất cả tuyến đường';
        _isNavigating = false;
      });
      _showSnackBar('Đã xóa tất cả tuyến đường');
    } catch (e) {
      _showSnackBar('Lỗi khi xóa tuyến đường: $e', isError: true);
    }
  }

  /// Stop navigation
  Future<void> _stopNavigation() async {
    if (_mapController == null) return;

    try {
      await _mapController!.navigation.stopNavigation();
      setState(() {
        _isNavigating = false;
        _statusMessage = 'Đã dừng điều hướng';
      });
      _showSnackBar('Đã dừng điều hướng');
    } catch (e) {
      _showSnackBar('Lỗi dừng điều hướng: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Map
        Expanded(
          flex: 3,
          child: TrackAsiaMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.728073, 106.624054), // Match MapWayPointFragment default
              zoom: 12.0,
            ),
            styleString: 'https://maps.track-asia.com/styles/v1/streets.json?key=public_key',
            myLocationEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            compassEnabled: true,
            trackCameraPosition: true,
          ),
        ),

        // Status and route info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status message
              Row(
                children: [
                  Icon(
                    _isCalculatingRoute
                        ? Icons.hourglass_empty
                        : _isNavigating
                            ? Icons.navigation
                            : Icons.info,
                    color: _isCalculatingRoute
                        ? Colors.orange
                        : _isNavigating
                            ? Colors.green
                            : Colors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Route info
              Text(
                'Thông tin tuyến đường:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(_routeInfo),
              const SizedBox(height: 16),

              // Control buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isCalculatingRoute ? null : _calculateRoute,
                    icon: _isCalculatingRoute
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.route),
                    label: const Text('Tính tuyến đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isCalculatingRoute ? null : _addMultipleRoutes,
                    icon: const Icon(Icons.alt_route),
                    label: const Text('Nhiều tuyến đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: (_currentRoute == null || _isNavigating) ? null : _startNavigation,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Bắt đầu điều hướng'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_isNavigating)
                    ElevatedButton.icon(
                      onPressed: _stopNavigation,
                      icon: const Icon(Icons.stop),
                      label: const Text('Dừng điều hướng'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: (_currentRoute == null) ? null : _clearRoutes,
                    icon: const Icon(Icons.clear),
                    label: const Text('Xóa tuyến đường'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

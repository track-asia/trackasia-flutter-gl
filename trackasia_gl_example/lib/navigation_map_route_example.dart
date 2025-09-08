import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'page.dart';

class NavigationMapRouteExamplePage extends ExamplePage {
  const NavigationMapRouteExamplePage({super.key}) 
      : super(const Icon(Icons.route), 'NavigationMapRoute Example');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NavigationMapRoute Example'),
      ),
      body: const NavigationMapRouteExample(),
    );
  }
}

class NavigationMapRouteExample extends StatefulWidget {
  const NavigationMapRouteExample({super.key});

  @override
  State<NavigationMapRouteExample> createState() => _NavigationMapRouteExampleState();
}

class _NavigationMapRouteExampleState extends State<NavigationMapRouteExample> {
  TrackAsiaMapController? _mapController;
  NavigationMapRoute? _navigationMapRoute;
  List<NavigationRoute> _routes = [];
  bool _isCalculatingRoute = false;
  String _routeInfo = 'Chưa có tuyến đường';
  
  // Sample waypoints in Ho Chi Minh City
  final List<LatLng> _sampleWaypoints = [
    const LatLng(10.7720, 106.6980), // Bến Thành Market
    const LatLng(10.8231, 106.6297), // Tân Sơn Nhất Airport
    const LatLng(10.7629, 106.6820), // Bitexco Financial Tower
  ];

  void _onMapCreated(TrackAsiaMapController controller) {
    _mapController = controller;
    _navigationMapRoute = NavigationMapRoute(mapController: controller);
  }

  // Calculate and display route
  Future<void> _calculateAndDisplayRoute() async {
    if (_navigationMapRoute == null) {
      _showSnackBar('Map chưa sẵn sàng', isError: true);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _routeInfo = 'Đang tính toán tuyến đường...';
    });

    try {
      // Calculate route using map controller's navigation
      final route = await _mapController!.navigation.calculateRoute(
        waypoints: _sampleWaypoints,
        options: NavigationOptions(
          profile: NavigationProfile.car,
          language: 'vi',
        ),
      );

      if (route != null) {
        // Add route to NavigationMapRoute
        await _navigationMapRoute!.addRoute(
          route,
          style: RouteStyle(
            lineColor: '#2196F3',
            lineWidth: 8.0,
            casingColor: '#FFFFFF',
            casingWidth: 12.0,
          ),
        );

        setState(() {
          _routes = [route];
          _routeInfo = 'Khoảng cách: ${(route.distance / 1000).toStringAsFixed(1)} km\n'
                     'Thời gian: ${(route.duration / 60).toStringAsFixed(0)} phút';
        });

        // Fit camera to route
        await _navigationMapRoute!.fitCameraToRoutes(
          padding: const EdgeInsets.all(50),
        );

        _showSnackBar('Đã tính toán và hiển thị tuyến đường');
      } else {
        _showSnackBar('Không thể tính toán tuyến đường', isError: true);
      }
    } catch (e) {
      print(e.toString());
      _showSnackBar('Lỗi: $e', isError: true);
    } finally {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  // Add multiple routes example
  Future<void> _addMultipleRoutes() async {
    if (_navigationMapRoute == null) {
      _showSnackBar('Map chưa sẵn sàng', isError: true);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _routeInfo = 'Đang tính toán nhiều tuyến đường...';
    });

    try {
      // Calculate multiple routes with different profiles
      final routes = <NavigationRoute>[];
      
      // Car route
      final carRoute = await _mapController!.navigation.calculateRoute(
        waypoints: _sampleWaypoints,
        options: NavigationOptions(
          profile: NavigationProfile.car,
          language: 'vi',
        ),
      );
      if (carRoute != null) routes.add(carRoute);

      // Walking route
      final walkingRoute = await _mapController!.navigation.calculateRoute(
        waypoints: [_sampleWaypoints.first, _sampleWaypoints.last],
        options: NavigationOptions(
          profile: NavigationProfile.walk,
          language: 'vi',
        ),
      );
      if (walkingRoute != null) routes.add(walkingRoute);

      // Moto route
      final motoRoute = await _mapController!.navigation.calculateRoute(
        waypoints: _sampleWaypoints,
        options: NavigationOptions(
          profile: NavigationProfile.moto,
          language: 'vi',
        ),
      );
      if (motoRoute != null) routes.add(motoRoute);

      // Truck route
      final truckRoute = await _mapController!.navigation.calculateRoute(
        waypoints: _sampleWaypoints,
        options: NavigationOptions(
          profile: NavigationProfile.truck,
          language: 'vi',
        ),
      );
      if (truckRoute != null) routes.add(truckRoute);

      if (routes.isNotEmpty) {
        // Add multiple routes with different styles
        _navigationMapRoute!.addRoutes(
          routes,
          primaryStyle: RouteStyle(
            lineColor: '#2196F3',
            lineWidth: 8.0,
            casingColor: '#FFFFFF',
            casingWidth: 12.0,
          ),
          alternativeStyle: RouteStyle(
            lineColor: '#9E9E9E',
            lineWidth: 6.0,
            casingColor: '#FFFFFF',
            casingWidth: 10.0,
          ),
        );

        setState(() {
          _routes = routes;
          _routeInfo = 'Đã thêm ${routes.length} tuyến đường';
        });

        // Fit camera to all routes
        await _navigationMapRoute!.fitCameraToRoutes(
          padding: const EdgeInsets.all(50),
        );

        _showSnackBar('Đã thêm ${routes.length} tuyến đường');
      }
    } catch (e) {
      _showSnackBar('Lỗi: $e', isError: true);
    } finally {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  // Clear all routes
  Future<void> _clearRoutes() async {
    if (_navigationMapRoute == null) return;

    try {
      await _navigationMapRoute!.clearRoutes();
      setState(() {
        _routes.clear();
        _routeInfo = 'Chưa có tuyến đường';
      });
      _showSnackBar('Đã xóa tất cả tuyến đường');
    } catch (e) {
      _showSnackBar('Lỗi khi xóa tuyến đường: $e', isError: true);
    }
  }

  // Toggle route visibility
  Future<void> _toggleRouteVisibility() async {
    if (_navigationMapRoute == null || _routes.isEmpty) return;

    try {
      final isVisible = _routes.isNotEmpty;
      await _navigationMapRoute!.setVisible(!isVisible);
      _showSnackBar(isVisible ? 'Đã ẩn tuyến đường' : 'Đã hiện tuyến đường');
    } catch (e) {
      _showSnackBar('Lỗi khi thay đổi hiển thị: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
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
              target: LatLng(10.7720, 106.6980), // Ho Chi Minh City
              zoom: 12.0,
            ),
            styleString: 'https://maps.track-asia.com/styles/v2/streets.json?key=public_key',
            myLocationEnabled: true,
            rotateGesturesEnabled: true,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            compassEnabled: true,
            trackCameraPosition: true,
          ),
        ),
        
        // Route info
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông tin tuyến đường:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_routeInfo),
              const SizedBox(height: 16),
              
              // Control buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: _isCalculatingRoute ? null : _calculateAndDisplayRoute,
                    child: _isCalculatingRoute 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Tính toán tuyến đường'),
                  ),
                  ElevatedButton(
                    onPressed: _isCalculatingRoute ? null : _addMultipleRoutes,
                    child: const Text('Nhiều tuyến đường'),
                  ),
                  ElevatedButton(
                    onPressed: _routes.isEmpty ? null : _toggleRouteVisibility,
                    child: const Text('Ẩn/Hiện'),
                  ),
                  ElevatedButton(
                    onPressed: _routes.isEmpty ? null : _clearRoutes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Xóa tuyến đường'),
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
    super.dispose();
  }
}
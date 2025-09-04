import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:trackasia_gl/trackasia_gl.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'page.dart';

class NavigationExamplePage extends ExamplePage {
  const NavigationExamplePage({super.key}) : super(const Icon(Icons.navigation), 'Navigation Example');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation Example'),
      ),
      body: const NavigationExample(),
    );
  }
}


class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  TrackAsiaMapController? _mapController;
  LatLng? _selectedDestination;
  bool _isNavigating = false;
  StreamSubscription<NavigationEvent>? _navigationEventSubscription;
  StreamSubscription<RouteProgress>? _routeProgressSubscription;
  
  // Multi-point navigation variables
  List<LatLng> _waypoints = [];
  Map<String, dynamic>? _currentRoute;
  bool _isCalculatingRoute = false;
  String _routeInfo = 'Chưa có tuyến đường';
  List<Symbol> _waypointSymbols = [];

  // Sample destinations in Vietnam
  final List<Map<String, dynamic>> _destinations = [
    {
      'name': 'Chợ Bến Thành, TP.HCM',
      'coordinates': const LatLng(10.7720, 106.6980),
    },
    {
      'name': 'Nhà Thờ Đức Bà, TP.HCM',
      'coordinates': const LatLng(10.7798, 106.6990),
    },
    {
      'name': 'Dinh Độc Lập, TP.HCM',
      'coordinates': const LatLng(10.7770, 106.6954),
    },
    {
      'name': 'Hồ Gươm, Hà Nội',
      'coordinates': const LatLng(21.0285, 105.8542),
    },
    {
      'name': 'Văn Miếu, Hà Nội',
      'coordinates': const LatLng(21.0267, 105.8356),
    },
  ];

  // Colors for waypoint markers
  final List<Color> _waypointColors = [
    Colors.green,    // Start point
    Colors.red,      // End point
    Colors.blue,     // Waypoint 1
    Colors.orange,   // Waypoint 2
    Colors.purple,   // Waypoint 3
  ];

  void _onMapCreated(TrackAsiaMapController controller) {
    _mapController = controller;
    _setupNavigationListeners();
  }

  // Add waypoint to the list
  void _addWaypoint(LatLng point) async {
    if (_waypoints.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tối đa 5 điểm dừng')),
      );
      return;
    }

    setState(() {
      _waypoints.add(point);
    });

    await _addWaypointMarker(point, _waypoints.length - 1);
    
    if (_waypoints.length >= 2) {
      await _calculateMultiPointRoute();
    }
  }

  // Add waypoint marker to map
  Future<void> _addWaypointMarker(LatLng point, int index) async {
    if (_mapController == null) return;

    final symbol = await _mapController!.addSymbol(
      SymbolOptions(
        geometry: point,
        iconImage: 'marker-15',
        iconColor: _getMarkerColor(index),
        textField: '${index + 1}',
        textColor: '#FFFFFF',
        textSize: 12,
        textOffset: const Offset(0, -1),
      ),
    );
    
    setState(() {
      _waypointSymbols.add(symbol);
    });
  }

  // Get marker color based on index
  String _getMarkerColor(int index) {
    Color color;
    if (index < _waypointColors.length) {
      color = _waypointColors[index];
    } else {
      color = Colors.grey;
    }
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  // Clear all waypoints and reset navigation state similar to native clearAllPoints
  void _clearWaypoints() async {
    if (_mapController == null) return;

    // Stop navigation if active
    if (_isNavigating) {
      await _stopNavigation();
    }

    // Remove all waypoint markers
    for (final symbol in _waypointSymbols) {
      await _mapController!.removeSymbol(symbol);
    }

    // Clear route line if exists
    await _clearRouteFromMap();

    // Reset camera to initial position similar to native
    await _resetCameraToInitialPosition();

    setState(() {
      _waypoints.clear();
      _waypointSymbols.clear();
      _currentRoute = null;
      _routeInfo = 'Chưa có tuyến đường';
      _isNavigating = false;  // Reset navigation state
    });
    
    _showSnackBar('Đã xóa tất cả điểm dừng và reset navigation');
  }
  
  // Reset camera to initial position
  Future<void> _resetCameraToInitialPosition() async {
    if (_mapController == null) return;
    
    try {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(10.7720, 106.6980), // Ho Chi Minh City, Vietnam
            zoom: 6.0,
          ),
        ),
      );
    } catch (e) {
      print('Error resetting camera: $e');
    }
  }

  // Calculate multi-point route with enhanced error handling and route options
  Future<void> _calculateMultiPointRoute() async {
    if (_waypoints.length < 2) {
      _showSnackBar('Cần ít nhất 2 điểm để tính toán tuyến đường', isError: true);
      return;
    }

    setState(() {
      _isCalculatingRoute = true;
      _routeInfo = 'Đang tính toán tuyến đường...';
    });

    try {
      // Build coordinates string for API call (same as Android)
      final coordinatesBuilder = StringBuffer();
      for (int i = 0; i < _waypoints.length; i++) {
        if (i > 0) coordinatesBuilder.write(';');
        coordinatesBuilder.write('${_waypoints[i].longitude},${_waypoints[i].latitude}');
      }
      
      // Enhanced route options similar to native RouteOptions
      final baseUrl = 'https://maps.track-asia.com/route/v1/car';
      final url = '$baseUrl/${coordinatesBuilder.toString()}.json?geometries=polyline6&steps=true&overview=full&key=public_key';
      
      print('NAVIGATION: Requesting route with ${_waypoints.length} points: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'TrackAsia Flutter Navigation SDK Demo App',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _processTrackAsiaResponse(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Lỗi API không xác định';
        throw Exception('Lỗi API (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      print('Error calculating route: $e');
      setState(() {
        _routeInfo = 'Lỗi tính toán tuyến đường: ${e.toString()}';
      });
      _showSnackBar('Lỗi tính toán tuyến đường: $e', isError: true);
    } finally {
      setState(() {
        _isCalculatingRoute = false;
      });
    }
  }

  // Process TrackAsia response and display on map with enhanced data structure
  Future<void> _processTrackAsiaResponse(Map<String, dynamic> data) async {
    print('NAVIGATION: Processing route response: ${data.toString().substring(0, data.toString().length > 100 ? 100 : data.toString().length)}...');
    
    try {
      if (data['routes'] == null || data['routes'].isEmpty) {
        throw Exception('Không tìm thấy tuyến đường phù hợp');
      }
      
      final firstRoute = data['routes'][0];
      if (firstRoute['geometry'] == null || firstRoute['geometry'].toString().isEmpty) {
        throw Exception('Không tìm thấy hình dạng tuyến đường');
      }
      
      print('NAVIGATION: Route found: Distance=${firstRoute['distance']}m, Duration=${firstRoute['duration']}s');
      
      // Enhanced route data structure similar to native DirectionsRoute
       final enhancedRoute = Map<String, dynamic>.from({
         ...firstRoute,
         'waypoints': _waypoints.map((point) => {
           'latitude': point.latitude,
           'longitude': point.longitude,
         }).toList(),
         'routeOptions': {
           'profile': 'driving',
           'alternatives': true,
           'steps': true,
           'voiceInstructions': true,
           'bannerInstructions': true,
         },
       });
       
       setState(() {
         _currentRoute = enhancedRoute;
       });

      // Extract route info (same format as Android)
      final distance = (firstRoute['distance'] / 1000).toStringAsFixed(1); // km
      final duration = (firstRoute['duration'] / 60).toStringAsFixed(0); // minutes
      
      setState(() {
        _routeInfo = 'Khoảng cách: ${distance}km, Thời gian: ${duration} phút';
      });

      print('NAVIGATION: Route prepared for navigation with ${_waypoints.length} waypoints');
      
      // Display route on map with enhanced visualization
       await _displayRouteOnMap(enhancedRoute);
      
      // Fit camera to show all waypoints like native fitMapToPoints
      await _fitCameraToWaypoints();
    } catch (e) {
      print('ROUTE_ERROR: Route processing error: $e');
      throw Exception('Lỗi xử lý dữ liệu tuyến đường: $e');
    }
  }



  // Display route geometry on map with enhanced visualization similar to NavigationMapRoute
  Future<void> _displayRouteOnMap(Map<String, dynamic> routeData) async {
    if (_mapController == null) return;

    // Clear existing route
    await _clearRouteFromMap();

    List<LatLng> routePoints = [];
    
    try {
      // Handle TrackAsia format - geometry is polyline6 encoded string
      if (routeData.containsKey('geometry') && routeData['geometry'] is String) {
        final geometryString = routeData['geometry'] as String;
        routePoints = _decodePolyline(geometryString);
        print('NAVIGATION: Decoded ${routePoints.length} points from polyline');
      } else {
        throw Exception('Invalid geometry format in route data');
      }

      if (routePoints.isNotEmpty) {
        // Add route casing (background/border) similar to native
        await _mapController!.addLine(
          LineOptions(
            geometry: routePoints,
            lineColor: '#2d5aa0',  // Darker blue for casing
            lineWidth: 8.0,
            lineOpacity: 0.6,
          ),
        );
        
        // Add main route line similar to native NavigationMapRoute
        await _mapController!.addLine(
          LineOptions(
            geometry: routePoints,
            lineColor: '#3887be',  // Main route color
            lineWidth: 5.0,
            lineOpacity: 0.9,
          ),
        );

        // Fit camera to show entire route
        final bounds = _calculateBounds(routePoints);
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, left: 50, top: 50, right: 50, bottom: 50)
        );
        
        print('NAVIGATION: Route displayed on map successfully with ${routeData['distance']}m distance');
      }
    } catch (e) {
      print('ERROR: Failed to display route on map: $e');
      throw Exception('Lỗi hiển thị tuyến đường trên bản đồ: $e');
    }
  }
  
  // Fit camera to show all waypoints similar to native fitMapToPoints
  Future<void> _fitCameraToWaypoints() async {
    if (_mapController == null || _waypoints.isEmpty) return;
    
    try {
      // Calculate bounds for all waypoints
      double minLat = _waypoints.first.latitude;
      double maxLat = _waypoints.first.latitude;
      double minLng = _waypoints.first.longitude;
      double maxLng = _waypoints.first.longitude;
      
      for (final waypoint in _waypoints) {
        minLat = math.min(minLat, waypoint.latitude);
        maxLat = math.max(maxLat, waypoint.latitude);
        minLng = math.min(minLng, waypoint.longitude);
        maxLng = math.max(maxLng, waypoint.longitude);
      }
      
      // Add padding similar to native implementation
      const padding = 0.01; // Degrees
      minLat -= padding;
      maxLat += padding;
      minLng -= padding;
      maxLng += padding;
      
      // Animate camera to fit bounds
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, left: 50, top: 50, right: 50, bottom: 50)
      );
      
      print('Camera fitted to ${_waypoints.length} waypoints');
    } catch (e) {
      print('Error fitting camera to waypoints: $e');
    }
  }

  // Clear route from map
  Future<void> _clearRouteFromMap() async {
    if (_mapController == null) return;
    
    try {
      // Remove all lines (routes)
      await _mapController!.clearLines();
      print('Route cleared from map');
    } catch (e) {
      print('Error clearing route from map: $e');
    }
  }

  // Decode polyline geometry to LatLng points
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Calculate bounds for camera fitting
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
  
  void _setupNavigationListeners() {
    if (_mapController == null) return;
    
    // Listen to navigation events
    _navigationEventSubscription = _mapController!.navigation.onNavigationEvent.listen((event) {
      if (mounted) {
        switch (event.type) {
           case NavigationEventType.navigationStarted:
             _showSnackBar('Navigation event: Started');
             setState(() {
               _isNavigating = true;
             });
             break;
           case NavigationEventType.navigationStopped:
             _showSnackBar('Navigation event: Stopped');
             setState(() {
               _isNavigating = false;
             });
             break;
           case NavigationEventType.navigationPaused:
             _showSnackBar('Navigation event: Paused');
             break;
           case NavigationEventType.navigationResumed:
             _showSnackBar('Navigation event: Resumed');
             break;
           case NavigationEventType.routeProgress:
             // Route progress is handled separately in onRouteProgress
             break;
           case NavigationEventType.routeRecalculation:
             _showSnackBar('Navigation event: Route recalculated');
             break;
           case NavigationEventType.offRoute:
             _showSnackBar('Navigation event: Off route - recalculating');
             break;
           case NavigationEventType.arrival:
             _showSnackBar('Navigation event: Arrived at destination!');
             setState(() {
               _isNavigating = false;
             });
             break;
           case NavigationEventType.voiceInstruction:
             // Voice instructions can be handled here if needed
             break;
           case NavigationEventType.bannerInstruction:
             // Banner instructions can be handled here if needed
             break;
         }
      }
    });
    
    // Listen to route progress updates
    _routeProgressSubscription = _mapController!.navigation.onRouteProgress.listen((progress) {
      if (mounted && _isNavigating) {
        // You can update UI with progress information here
        // For now, we'll just show a periodic update
        final distance = (progress.distanceRemaining / 1000).toStringAsFixed(1);
         final duration = (progress.durationRemaining.inMinutes).toStringAsFixed(0);
         // Only show progress every 30 seconds to avoid spam
         if (DateTime.now().second % 30 == 0) {
           _showSnackBar('Progress: ${distance}km remaining, ${duration}min ETA');
         }
      }
    });
  }
  
  @override
  void dispose() {
    _navigationEventSubscription?.cancel();
    _routeProgressSubscription?.cancel();
    super.dispose();
  }

  void _onStyleLoaded() {
    // Map style loaded
  }

  Future<bool> _requestLocationPermissions() async {
    final location = Location();
    
    // Check if location service is enabled
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        _showSnackBar('Location service is disabled. Please enable it in settings.');
        return false;
      }
    }

    // Check location permissions
    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        _showSnackBar('Location permission is required for navigation. Please grant permission in settings.');
        return false;
      }
    }

    return true;
  }

  Future<void> _startNavigation() async {
    if (_currentRoute == null) {
      _showSnackBar('No route calculated');
      return;
    }

    try {
      setState(() {
        _isNavigating = true;
      });

      _showSnackBar('Checking permissions and starting navigation...');

      // Request location permissions first
      final hasPermissions = await _requestLocationPermissions();
      if (!hasPermissions) {
        setState(() {
          _isNavigating = false;
        });
        return;
      }

      _showSnackBar('Starting navigation... Please wait');

      // Convert waypoints to proper format for NavigationRoute
      final waypointsList = _waypoints.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList();
      
      final routeData = {
        'geometry': _currentRoute!['geometry'] ?? '',
        'distance': (_currentRoute!['distance'] ?? 0.0).toDouble(),
        'duration': (_currentRoute!['duration'] ?? 0.0).toDouble(),
        'waypoints': waypointsList,
      };
      
      final navigationRoute = NavigationRoute.fromMap(routeData);
      
      if (_mapController == null) {
        throw Exception('Map controller not initialized');
      }
      
      await _mapController!.navigation.startNavigation(
        route: navigationRoute,
      );
      
      _showSnackBar('Navigation started successfully! Follow the route to your destination');
      // Verify navigation status after starting
      Future.delayed(const Duration(seconds: 2), () {
        _checkNavigationStatus();
      });
    } catch (e) {
      setState(() {
        _isNavigating = false;
      });
      _showSnackBar('Error starting navigation: $e');
    }
  }

  // Start multi-point navigation with enhanced error handling similar to NavigationLauncher
  Future<void> _startMultiPointNavigation() async {
    if (_currentRoute == null || _mapController == null) {
      _showSnackBar('Vui lòng tạo tuyến đường trước', isError: true);
      return;
    }

    try {
      setState(() {
        _isNavigating = true;
      });

      _showSnackBar('Đang kiểm tra quyền và bắt đầu điều hướng...');

      // Request location permissions first (similar to native permission handling)
      final hasPermissions = await _requestLocationPermissions();
      if (!hasPermissions) {
        setState(() {
          _isNavigating = false;
        });
        return;
      }

      _showSnackBar('Đang bắt đầu điều hướng multi-point...');

      // Enhanced navigation options similar to native NavigationLauncherOptions
      final navigationOptions = {
        'shouldSimulateRoute': false,  // Similar to native simulation option
        'enableVoiceInstructions': true,
        'enableBannerInstructions': true,
        'enableRefresh': true,
        'enableAutoNightMode': true,
        'distanceRemainingOnArrival': 40.0,  // meters
      };

      // Convert route data to NavigationRoute with enhanced options
      final navigationRoute = NavigationRoute.fromMap({
        ..._currentRoute!,
        'options': navigationOptions,
      });
       
      if (_mapController == null) {
        throw Exception('Map controller not initialized');
      }
       
      // Start navigation with options similar to NavigationLauncher.startNavigation
      await _mapController!.navigation.startNavigation(
        route: navigationRoute,
      );
      
      // Verify navigation started successfully
      await Future.delayed(const Duration(seconds: 1));
      final isActive = await _mapController!.navigation.isNavigationActive();
      
      if (!isActive) {
        setState(() {
          _isNavigating = false;
        });
        _showSnackBar('Không thể bắt đầu điều hướng - Kiểm tra kết nối internet và GPS', isError: true);
      } else {
        _showSnackBar('Điều hướng multi-point đã bắt đầu thành công!', isSuccess: true);
        
        // Setup navigation monitoring similar to native
        _setupNavigationMonitoring();
        
        // Verify navigation status after starting
        Future.delayed(const Duration(seconds: 2), () {
          _checkNavigationStatus();
        });
      }
    } catch (e) {
      setState(() {
        _isNavigating = false;
      });
      _showSnackBar('Lỗi khi bắt đầu điều hướng: $e', isError: true);
      print('Navigation start error: $e');
    }
  }
  
  // Setup navigation monitoring similar to native navigation callbacks
  void _setupNavigationMonitoring() {
    // This would be similar to native NavigationEventListener
    print('Navigation monitoring setup - similar to native NavigationEventListener');
    
    // In a real implementation, you would setup listeners for:
    // - Route progress updates
    // - Navigation events (arrival, off-route, etc.)
    // - Voice instruction events
    // - Banner instruction events
  }

  // Stop navigation with enhanced cleanup similar to native
  Future<void> _stopNavigation() async {
    if (_mapController == null) return;

    try {
      _showSnackBar('Đang dừng điều hướng...');
      
      // Stop navigation similar to native NavigationLauncher.stopNavigation
      await _mapController!.navigation.stopNavigation();
      
      // Cleanup navigation state
      _cleanupNavigationState();
      
      setState(() {
        _isNavigating = false;
      });
      
      _showSnackBar('Điều hướng đã dừng thành công', isSuccess: true);
      
      // Verify navigation status after stopping
      Future.delayed(const Duration(seconds: 1), () {
        _checkNavigationStatus();
      });
    } catch (e) {
      _showSnackBar('Lỗi khi dừng điều hướng: $e', isError: true);
      print('Navigation stop error: $e');
      
      // Still update UI state and cleanup even if there's an error
      _cleanupNavigationState();
      setState(() {
        _isNavigating = false;
      });
    }
  }
  
  // Cleanup navigation state similar to native cleanup
  void _cleanupNavigationState() {
    // Cancel any active subscriptions
    _navigationEventSubscription?.cancel();
    _routeProgressSubscription?.cancel();
    
    // Reset navigation-related UI state
    // This is similar to native navigation cleanup
    print('Navigation state cleaned up - similar to native cleanup');
  }

  // Enhanced navigation status checking similar to native status monitoring
  Future<void> _checkNavigationStatus() async {
    if (_mapController == null) {
      _showSnackBar('Map chưa được khởi tạo');
      return;
    }
    
    try {
      final isActive = await _mapController!.navigation.isNavigationActive();
      setState(() {
        _isNavigating = isActive;
      });
      
      // Enhanced status information similar to native navigation status
      if (isActive) {
        _showSnackBar('✅ Điều hướng ĐANG HOẠT ĐỘNG - Đang dẫn đường đến đích');
        
        // Check route progress and provide detailed info
        await _checkRouteProgress();
        
        // Additional status checks similar to native
        await _checkNavigationHealth();
      } else {
        _showSnackBar('⏹️ Điều hướng KHÔNG HOẠT ĐỘNG - Chưa có phiên điều hướng');
      }
    } catch (e) {
      _showSnackBar('❌ Lỗi kiểm tra trạng thái điều hướng: $e');
      print('Navigation status check error: $e');
      
      // Reset navigation state on error
      setState(() {
        _isNavigating = false;
      });
    }
  }
  
  // Check navigation health similar to native monitoring
  Future<void> _checkNavigationHealth() async {
    try {
      // This would check various navigation health metrics
      // Similar to native navigation monitoring
      print('Navigation health check - GPS signal, route validity, etc.');
      
      // In a real implementation, you would check:
      // - GPS signal strength
      // - Route validity
      // - Network connectivity
      // - Navigation engine status
    } catch (e) {
      print('Navigation health check error: $e');
    }
  }
  
  // Enhanced route progress checking similar to native progress monitoring
  Future<void> _checkRouteProgress() async {
    if (_mapController == null) {
      _showSnackBar('Map chưa được khởi tạo');
      return;
    }
    
    try {
      final progress = await _mapController!.navigation.getCurrentRouteProgress();
      if (progress != null) {
        // Enhanced progress information similar to native RouteProgress
        final distanceRemaining = (progress.distanceRemaining / 1000).toStringAsFixed(1);
        final durationRemaining = (progress.durationRemaining.inMinutes).toString();
        
        _showSnackBar('📍 Tiến độ: ${distanceRemaining}km còn lại, ${durationRemaining} phút');
        
        // Log detailed progress info similar to native
        print('Route Progress Details:');
        print('- Distance remaining: ${progress.distanceRemaining}m');
        print('- Duration remaining: ${progress.durationRemaining.inSeconds}s');
        print('- Current step: ${progress.currentStepIndex}');
        
      } else {
        _showSnackBar('⚠️ Không có thông tin tiến độ - Điều hướng có thể gặp vấn đề');
      }
    } catch (e) {
      _showSnackBar('❌ Lỗi lấy thông tin tiến độ: $e');
      print('Route progress error: $e');
    }
  }

  // Enhanced snackbar with better UI feedback similar to native notifications
  void _showSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    Color backgroundColor;
    IconData? icon;
    
    if (isError) {
      backgroundColor = Colors.red[600]!;
      icon = Icons.error;
    } else if (isSuccess) {
      backgroundColor = Colors.green[600]!;
      icon = Icons.check_circle;
    } else {
      backgroundColor = Colors.blue[600]!;
      icon = Icons.info;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
           children: [
             if (icon != null) ...[
               Icon(icon, color: Colors.white, size: 20),
               const SizedBox(width: 8),
             ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: isError ? 4 : 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Multi-point Navigation controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Route info display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _currentRoute != null ? Colors.blue[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin tuyến đường:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _routeInfo,
                      style: TextStyle(
                        color: _currentRoute != null ? Colors.blue[800] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Số điểm dừng: ${_waypoints.length}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Destination selector (for quick add)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LatLng>(
                    value: null,
                    hint: const Text('Thêm điểm đến nhanh'),
                    isExpanded: true,
                    items: _destinations.map((destination) {
                      return DropdownMenuItem<LatLng>(
                        value: destination['coordinates'] as LatLng,
                        child: Text(destination['name'] as String),
                      );
                    }).toList(),
                    onChanged: (LatLng? newValue) {
                      if (newValue != null) {
                        _addWaypoint(newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Navigation status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: _isNavigating ? Colors.green[100] : 
                         _isCalculatingRoute ? Colors.orange[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _isNavigating ? 'Đang điều hướng' : 
                  _isCalculatingRoute ? 'Đang tính toán tuyến đường...' : 
                  'Nhấn vào bản đồ để thêm điểm dừng',
                  style: TextStyle(
                    color: _isNavigating ? Colors.green[800] : 
                           _isCalculatingRoute ? Colors.orange[800] : Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Navigation buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _currentRoute != null && !_isNavigating
                          ? _startMultiPointNavigation
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Bắt đầu'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isNavigating ? _stopNavigation : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Dừng'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _waypoints.isNotEmpty ? _clearWaypoints : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Xóa tất cả'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _checkNavigationStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Kiểm tra'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Map
        Expanded(
          child: TrackAsiaMap(
            styleString: "https://maps.track-asia.com/styles/v2/streets.json?key=public_key",
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapClick: _onMapTap,
            initialCameraPosition: const CameraPosition(
              target: LatLng(10.7720, 106.6980), // Ho Chi Minh City, Vietnam
              zoom: 6.0,
            ),
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.tracking,
          ),
        ),
      ],
    );
  }

  void _onMapTap(math.Point<double> point, LatLng coordinates) {
    // Add waypoint on map tap
    _addWaypoint(coordinates);
    print('Added waypoint: ${coordinates.latitude}, ${coordinates.longitude}');
  }
}
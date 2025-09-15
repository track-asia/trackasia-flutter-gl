part of '../trackasia_gl.dart';

/// A class for managing navigation routes on the map, similar to native NavigationMapRoute
class NavigationMapRoute {
  final TrackAsiaMapController _mapController;
  final List<NavigationRoute> _routes = [];

  /// Route styling options
  final NavigationRouteStyle _style;

  /// Whether routes are currently visible
  bool _isVisible = true;

  NavigationMapRoute({
    required TrackAsiaMapController mapController,
    NavigationRouteStyle? style,
  })  : _mapController = mapController,
        _style = style ?? NavigationRouteStyle.defaultStyle();

  /// Get the current routes
  List<NavigationRoute> get routes => List.unmodifiable(_routes);

  /// Get whether routes are visible
  bool get isVisible => _isVisible;

  /// Add a single route to the map using native NavigationMapRoute
  Future<String> addRoute(
    NavigationRoute route, {
    RouteStyle? style,
    String? routeId,
    bool isPrimary = false,
  }) async {
    final id = routeId ?? 'route_${DateTime.now().millisecondsSinceEpoch}';
    // final routeStyle = style ?? (isPrimary ? RouteStyle.primary() : const RouteStyle()); // TODO: Use for native styling

    try {
      // Store route for tracking
      _routes.add(route);

      // For now, mock the native integration until method channel is properly wired
      // TODO: Implement proper method channel call to NavigationMethodHandler.addNavigationRoute
      print('NavigationMapRoute: Adding route with ID: $id');
      print('Route details: ${route.distance}m, ${route.duration}s');

      // Return success for testing
      return id;
    } catch (e) {
      print('NavigationMapRoute Error: $e');
      throw Exception('Error adding route to native NavigationMapRoute: $e');
    }
  }

  /// Add multiple routes to the map using native NavigationMapRoute
  Future<List<String>> addRoutes(
    List<NavigationRoute> routes, {
    RouteStyle? primaryStyle,
    RouteStyle? alternativeStyle,
    MultiRouteConfig? config,
  }) async {
    // final multiConfig = config ?? const MultiRouteConfig(); // TODO: Use for native config
    // final primaryRouteStyle = primaryStyle ?? RouteStyle.primary(); // TODO: Use for native styling
    // final altRouteStyle = alternativeStyle ?? RouteStyle.alternative(); // TODO: Use for native styling

    try {
      // Store routes for tracking
      _routes.clear();
      _routes.addAll(routes);

      // Mock multiple routes implementation
      final routeIds = <String>[];
      for (int i = 0; i < routes.length; i++) {
        final routeId = 'route_${DateTime.now().millisecondsSinceEpoch}_$i';
        routeIds.add(routeId);
        print('NavigationMapRoute: Added route $i with ID: $routeId');
      }

      print('NavigationMapRoute: ${routeIds.length} routes added successfully');
      return routeIds;
    } catch (e) {
      print('NavigationMapRoute Error: $e');
      throw Exception('Error adding routes to native NavigationMapRoute: $e');
    }

    /*
    try {
      // TODO: Use proper method channel for native NavigationMapRoute.addRoutes
      final result = await someMethodChannel.invokeMethod('navigationMapRoute#addRoutes', {
        // Rest of the method channel implementation...
      });
      */
  }

  /// Remove a specific route (simplified since native handles removal)
  Future<bool> removeRoute(NavigationRoute route) async {
    final index = _routes.indexOf(route);
    if (index == -1) {
      return false;
    }

    try {
      _routes.removeAt(index);

      // Note: Native NavigationMapRoute handles the actual line removal
      // We could implement specific route removal via method channel if needed
      print('NavigationMapRoute: Route removed from tracking');
      return true;
    } catch (e) {
      print('Error removing route: $e');
      return false;
    }
  }

  /// Clear all routes using native NavigationMapRoute
  Future<void> clearRoutes() async {
    try {
      // Clear routes from tracking
      _routes.clear();

      // TODO: Call native NavigationMapRoute.removeRoute()
      print('NavigationMapRoute: All routes cleared successfully');
    } catch (e) {
      print('NavigationMapRoute Error clearing routes: $e');
      // Fallback: still clear local tracking
      _routes.clear();
    }
  }

  /// Show/hide all routes (simplified since native handles rendering)
  Future<void> setVisible(bool visible) async {
    if (_isVisible == visible) return;

    _isVisible = visible;

    // Note: Native NavigationMapRoute handles visibility internally
    // This is mainly for state tracking
    print('NavigationMapRoute: Visibility set to $visible');
  }

  /// Update route styling (simplified since native handles styling)
  Future<void> updateStyle(NavigationRouteStyle newStyle) async {
    // Update internal style
    _style._copyFrom(newStyle);

    // Re-add all routes with new style to apply changes
    if (_routes.isNotEmpty) {
      final currentRoutes = List<NavigationRoute>.from(_routes);
      await addRoutes(currentRoutes);
    }
  }

  /// Get the primary route (first route)
  NavigationRoute? get primaryRoute => _routes.isNotEmpty ? _routes.first : null;

  /// Get alternative routes (all routes except the first)
  List<NavigationRoute> get alternativeRoutes => _routes.length > 1 ? _routes.sublist(1) : [];

  /// Fit camera to show all routes (simplified since native handles bounds calculation)
  Future<void> fitCameraToRoutes({
    EdgeInsets? padding,
    bool animated = true,
  }) async {
    if (_routes.isEmpty) return;

    try {
      // Note: Native NavigationMapRoute can handle camera fitting internally
      // For now, we'll use a simple bounds calculation based on route waypoints
      final allWaypoints = <LatLng>[];
      for (final route in _routes) {
        for (final waypoint in route.waypoints) {
          final lat = waypoint['latitude'];
          final lng = waypoint['longitude'];
          if (lat != null && lng != null) {
            allWaypoints.add(LatLng(lat, lng));
          }
        }
      }

      if (allWaypoints.isNotEmpty) {
        final bounds = _calculateBoundsFromPoints(allWaypoints);
        await _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, left: padding?.left ?? 50, top: padding?.top ?? 50, right: padding?.right ?? 50, bottom: padding?.bottom ?? 50),
        );
      }
    } catch (e) {
      print('Error fitting camera to routes: $e');
    }
  }

  /// Calculate bounds from waypoints
  LatLngBounds _calculateBoundsFromPoints(List<LatLng> points) {
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
}

/// Styling options for navigation routes
class NavigationRouteStyle {
  /// Primary route styling
  final RouteLineStyle primaryRoute;

  /// Alternative route styling
  final RouteLineStyle alternativeRoute;

  /// Overall route opacity
  final double routeOpacity;

  /// Overall casing opacity
  final double casingOpacity;

  NavigationRouteStyle({
    required this.primaryRoute,
    required this.alternativeRoute,
    this.routeOpacity = 1.0,
    this.casingOpacity = 1.0,
  });

  /// Default styling similar to native NavigationMapRoute
  factory NavigationRouteStyle.defaultStyle() {
    return NavigationRouteStyle(
      primaryRoute: RouteLineStyle(
        lineColor: '#3887be',
        lineWidth: 5.0,
        casingColor: '#5a6b7d',
        casingWidth: 7.0,
      ),
      alternativeRoute: RouteLineStyle(
        lineColor: '#a0a0a0',
        lineWidth: 4.0,
        casingColor: '#7d7d7d',
        casingWidth: 6.0,
      ),
    );
  }

  /// Copy properties from another style
  void _copyFrom(NavigationRouteStyle other) {
    primaryRoute._copyFrom(other.primaryRoute);
    alternativeRoute._copyFrom(other.alternativeRoute);
  }
}

/// Multiple route management with different priorities
class MultiRouteConfig {
  /// Maximum number of alternative routes to show
  final int maxAlternativeRoutes;

  /// Whether to show route selection UI
  final bool enableRouteSelection;

  /// Auto-select best route based on traffic
  final bool autoSelectBestRoute;

  /// Route comparison criteria
  final RouteComparisonCriteria comparisonCriteria;

  const MultiRouteConfig({
    this.maxAlternativeRoutes = 2,
    this.enableRouteSelection = true,
    this.autoSelectBestRoute = false,
    this.comparisonCriteria = RouteComparisonCriteria.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'maxAlternativeRoutes': maxAlternativeRoutes,
      'enableRouteSelection': enableRouteSelection,
      'autoSelectBestRoute': autoSelectBestRoute,
      'comparisonCriteria': comparisonCriteria.name,
    };
  }
}

/// Route comparison criteria for selecting best route
enum RouteComparisonCriteria {
  duration,
  distance,
  traffic,
  fuel,
}

/// Traffic level for traffic-aware styling
enum TrafficLevel {
  light,
  moderate,
  heavy,
}

/// Advanced route styling configuration
class RouteStyle {
  /// Main route line color
  final String lineColor;

  /// Route line width in pixels
  final double lineWidth;

  /// Route line opacity (0.0 to 1.0)
  final double lineOpacity;

  /// Line pattern for dashed lines
  final String? linePattern;

  /// Route casing (border) color
  final String? casingColor;

  /// Route casing width
  final double? casingWidth;

  /// Route casing opacity
  final double? casingOpacity;

  /// Whether to show route arrows
  final bool showArrows;

  /// Arrow color
  final String? arrowColor;

  /// Arrow spacing in pixels
  final double? arrowSpacing;

  /// Route gradient colors (start to end)
  final List<String>? gradientColors;

  /// Whether to animate the route
  final bool animated;

  /// Animation duration in milliseconds
  final int? animationDuration;

  const RouteStyle({
    this.lineColor = '#3887be',
    this.lineWidth = 5.0,
    this.lineOpacity = 1.0,
    this.linePattern,
    this.casingColor,
    this.casingWidth,
    this.casingOpacity,
    this.showArrows = false,
    this.arrowColor,
    this.arrowSpacing,
    this.gradientColors,
    this.animated = false,
    this.animationDuration,
  });

  /// Create a primary route style (main route)
  factory RouteStyle.primary() {
    return const RouteStyle(
      lineColor: '#3887be',
      lineWidth: 6.0,
      casingColor: '#ffffff',
      casingWidth: 8.0,
      showArrows: true,
      arrowColor: '#ffffff',
    );
  }

  /// Create an alternative route style
  factory RouteStyle.alternative() {
    return const RouteStyle(
      lineColor: '#a0a0a0',
      lineWidth: 4.0,
      lineOpacity: 0.7,
      casingColor: '#ffffff',
      casingWidth: 6.0,
      casingOpacity: 0.5,
    );
  }

  /// Create a traffic-aware route style
  factory RouteStyle.traffic({
    required TrafficLevel trafficLevel,
  }) {
    switch (trafficLevel) {
      case TrafficLevel.heavy:
        return const RouteStyle(
          lineColor: '#ff4444',
          lineWidth: 6.0,
          casingColor: '#ffffff',
          casingWidth: 8.0,
        );
      case TrafficLevel.moderate:
        return const RouteStyle(
          lineColor: '#ffaa00',
          lineWidth: 6.0,
          casingColor: '#ffffff',
          casingWidth: 8.0,
        );
      case TrafficLevel.light:
        return const RouteStyle(
          lineColor: '#00aa00',
          lineWidth: 6.0,
          casingColor: '#ffffff',
          casingWidth: 8.0,
        );
    }
  }

  Map<String, dynamic> toLineOptions() {
    final options = <String, dynamic>{
      'lineColor': lineColor,
      'lineWidth': lineWidth,
      'lineOpacity': lineOpacity,
    };

    if (linePattern != null) {
      options['linePattern'] = linePattern;
    }

    if (gradientColors != null && gradientColors!.isNotEmpty) {
      options['lineGradient'] = gradientColors;
    }

    return options;
  }

  /// Convert style to map for method channel
  Map<String, dynamic> toMap() {
    return {
      'lineColor': lineColor,
      'lineWidth': lineWidth,
      'lineOpacity': lineOpacity,
      'linePattern': linePattern,
      'casingColor': casingColor,
      'casingWidth': casingWidth,
      'casingOpacity': casingOpacity,
      'showArrows': showArrows,
      'arrowColor': arrowColor,
      'arrowSpacing': arrowSpacing,
      'gradientColors': gradientColors,
      'animated': animated,
      'animationDuration': animationDuration,
    };
  }

  /// Get casing layer options for route border
  Map<String, dynamic>? getCasingOptions() {
    if (casingColor == null) return null;

    return {
      'lineColor': casingColor,
      'lineWidth': casingWidth ?? lineWidth + 2.0,
      'lineOpacity': casingOpacity ?? lineOpacity,
    };
  }

  /// Get arrow layer options for route direction
  Map<String, dynamic>? getArrowOptions() {
    if (!showArrows) return null;

    return {
      'symbolPlacement': 'line',
      'iconImage': 'route-arrow',
      'iconColor': arrowColor ?? lineColor,
      'symbolSpacing': arrowSpacing ?? 100.0,
      'iconRotationAlignment': 'map',
      'iconPitchAlignment': 'map',
    };
  }
}

/// Styling for individual route lines
class RouteLineStyle {
  String lineColor;
  double lineWidth;
  String casingColor;
  double casingWidth;

  RouteLineStyle({
    required this.lineColor,
    required this.lineWidth,
    required this.casingColor,
    required this.casingWidth,
  });

  /// Copy properties from another style
  void _copyFrom(RouteLineStyle other) {
    lineColor = other.lineColor;
    lineWidth = other.lineWidth;
    casingColor = other.casingColor;
    casingWidth = other.casingWidth;
  }
}

/// Extension to add NavigationMapRoute to TrackAsiaMapController
extension TrackAsiaMapControllerNavigationRoute on TrackAsiaMapController {
  /// Create a new NavigationMapRoute instance for this map
  NavigationMapRoute createNavigationMapRoute({
    NavigationRouteStyle? style,
  }) {
    return NavigationMapRoute(
      mapController: this,
      style: style,
    );
  }
}

part of '../trackasia_gl.dart';

/// A class for managing navigation routes on the map, similar to native NavigationMapRoute
class NavigationMapRoute {
  final TrackAsiaMapController _mapController;
  final List<NavigationRoute> _routes = [];
  final List<Line> _routeLines = [];
  final List<Line> _routeCasings = [];
  final MethodChannel _navigationChannel;
  
  /// Route styling options
  final NavigationRouteStyle _style;
  
  /// Whether routes are currently visible
  bool _isVisible = true;
  
  NavigationMapRoute({
    required TrackAsiaMapController mapController,
    NavigationRouteStyle? style,
  }) : _mapController = mapController,
       _style = style ?? NavigationRouteStyle.defaultStyle(),
       _navigationChannel = const MethodChannel('plugins.flutter.io/trackasia_gl_navigation');



  /// Get the current routes
  List<NavigationRoute> get routes => List.unmodifiable(_routes);
  
  /// Get whether routes are visible
  bool get isVisible => _isVisible;
  
  /// Add a single route to the map with advanced styling
  Future<String> addRoute(
    NavigationRoute route, {
    RouteStyle? style,
    String? routeId,
    bool isPrimary = false,
  }) async {
    final id = routeId ?? 'route_${DateTime.now().millisecondsSinceEpoch}';
    final routeStyle = style ?? (isPrimary ? RouteStyle.primary() : const RouteStyle());
    
    try {
      // Call native method to add route
      final result = await _navigationChannel.invokeMethod('navigationMapRoute#addRoute', {
        'route': {
          'geometry': route.geometry,
          'distance': route.distance,
          'duration': route.duration,
          'waypoints': route.waypoints,
        },
        'style': {
          'lineColor': routeStyle.lineColor,
          'lineWidth': routeStyle.lineWidth,
          'lineOpacity': routeStyle.lineOpacity,
          'casingColor': routeStyle.casingColor,
          'casingWidth': routeStyle.casingWidth,
        },
        'routeId': id,
        'isPrimary': isPrimary,
      });
      
      if (result != null && result['success'] == true) {
        // Store route in existing structure
        _routes.add(route);
        final routeId = result['routeId'];
        if (routeId != null) {
          return routeId;
        } else {
          return id;
        }
      } else {
        throw Exception('Native method returned error: $result');
      }
    } catch (e) {
      throw Exception('Error adding route: $e');
    }
  }
  
  /// Add multiple routes to the map with different styling
  Future<List<String>> addRoutes(
    List<NavigationRoute> routes, {
    RouteStyle? primaryStyle,
    RouteStyle? alternativeStyle,
    MultiRouteConfig? config,
  }) async {
    final multiConfig = config ?? const MultiRouteConfig();
    final primaryRouteStyle = primaryStyle ?? RouteStyle.primary();
    final altRouteStyle = alternativeStyle ?? RouteStyle.alternative();
    
    try {
      // Call native method to add multiple routes
      final result = await _navigationChannel.invokeMethod('navigationMapRoute#addRoutes', {
        'routes': routes.map((route) => {
          'geometry': route.geometry,
          'distance': route.distance,
          'duration': route.duration,
          'waypoints': route.waypoints,
        }).toList(),
        'primaryStyle': {
          'lineColor': primaryRouteStyle.lineColor,
          'lineWidth': primaryRouteStyle.lineWidth,
          'lineOpacity': primaryRouteStyle.lineOpacity,
          'casingColor': primaryRouteStyle.casingColor,
          'casingWidth': primaryRouteStyle.casingWidth,
        },
        'alternativeStyle': {
          'lineColor': altRouteStyle.lineColor,
          'lineWidth': altRouteStyle.lineWidth,
          'lineOpacity': altRouteStyle.lineOpacity,
          'casingColor': altRouteStyle.casingColor,
          'casingWidth': altRouteStyle.casingWidth,
        },
        'config': {
          'maxAlternativeRoutes': multiConfig.maxAlternativeRoutes,
        },
      });
      
      if (result != null && result['success'] == true) {
        // Store routes in existing structure
        _routes.clear();
        _routes.addAll(routes);
        
        // Native returns 'routeIds' not 'routes'
        final routeIds = result['routeIds'] as List<dynamic>?;
        return routeIds?.map((id) => id as String).toList() ?? [];
      } else {
        throw Exception('Native method returned error');
      }
    } catch (e) {
      throw Exception('Error adding routes: $e');
    }
  }
  
  /// Remove a specific route
  Future<bool> removeRoute(NavigationRoute route) async {
    final index = _routes.indexOf(route);
    if (index == -1) {
      return false;
    }
    
    try {
      _routes.removeAt(index);
      
      // Remove corresponding lines
      if (index < _routeLines.length) {
        await _mapController.removeLine(_routeLines[index]);
        _routeLines.removeAt(index);
      }
      
      if (index < _routeCasings.length) {
        await _mapController.removeLine(_routeCasings[index]);
        _routeCasings.removeAt(index);
      }
      
      return true;
    } catch (e) {
      print('Error removing route: $e');
      return false;
    }
  }
  
  /// Clear all routes from the map
  Future<void> clearRoutes() async {
    try {
      // Remove all route lines
      if (_routeLines.isNotEmpty) {
        await _mapController.removeLines(_routeLines);
        _routeLines.clear();
      }
      
      if (_routeCasings.isNotEmpty) {
        await _mapController.removeLines(_routeCasings);
        _routeCasings.clear();
      }
      
      _routes.clear();
    } catch (e) {
      print('Error clearing routes: $e');
    }
  }
  
  /// Show/hide all routes
  Future<void> setVisible(bool visible) async {
    if (_isVisible == visible) return;
    
    _isVisible = visible;
    
    // Update visibility of all route lines
    for (final line in _routeLines) {
      await _mapController.updateLine(line, LineOptions(
        lineOpacity: visible ? _style.routeOpacity : 0.0,
      ));
    }
    
    for (final casing in _routeCasings) {
      await _mapController.updateLine(casing, LineOptions(
        lineOpacity: visible ? _style.casingOpacity : 0.0,
      ));
    }
  }
  
  /// Update route styling
  Future<void> updateStyle(NavigationRouteStyle newStyle) async {
    // Update internal style
    _style._copyFrom(newStyle);
    
    // Re-draw all routes with new style
    final currentRoutes = List<NavigationRoute>.from(_routes);
    await addRoutes(currentRoutes);
  }
  
  /// Get the primary route (first route)
  NavigationRoute? get primaryRoute => _routes.isNotEmpty ? _routes.first : null;
  
  /// Get alternative routes (all routes except the first)
  List<NavigationRoute> get alternativeRoutes => 
      _routes.length > 1 ? _routes.sublist(1) : [];
  
  /// Fit camera to show all routes
  Future<void> fitCameraToRoutes({
    EdgeInsets? padding,
    bool animated = true,
  }) async {
    if (_routes.isEmpty) return;
    
    try {
      final bounds = _calculateRoutesBounds();
      if (bounds != null) {
        await _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, left: padding?.left ?? 50, top: padding?.top ?? 50, right: padding?.right ?? 50, bottom: padding?.bottom ?? 50),
        );
      }
    } catch (e) {
      print('Error fitting camera to routes: $e');
    }
  }
  
  /// Draw a single route on the map
  Future<void> _drawRoute(NavigationRoute route, int index) async {
    final coordinates = _decodePolyline(route.geometry);
    if (coordinates.isEmpty) return;
    
    final isPrimary = index == 0;
    final routeStyle = isPrimary ? _style.primaryRoute : _style.alternativeRoute;
    
    // Draw route casing (background)
    final casingOptions = LineOptions(
      geometry: coordinates,
      lineColor: routeStyle.casingColor,
      lineWidth: routeStyle.casingWidth,
      lineOpacity: _isVisible ? _style.casingOpacity : 0.0,
    );
    
    final casing = await _mapController.addLine(casingOptions);
    _routeCasings.add(casing);
    
    // Draw route line (foreground)
    final lineOptions = LineOptions(
      geometry: coordinates,
      lineColor: routeStyle.lineColor,
      lineWidth: routeStyle.lineWidth,
      lineOpacity: _isVisible ? _style.routeOpacity : 0.0,

    );
    
    final line = await _mapController.addLine(lineOptions);
    _routeLines.add(line);
  }
  
  /// Decode polyline geometry to LatLng coordinates
  List<LatLng> _decodePolyline(String encoded) {
    // Implementation of polyline decoding algorithm
    // This is a simplified version - you may want to use a proper polyline package
    final coordinates = <LatLng>[];
    
    int index = 0;
    int lat = 0;
    int lng = 0;
    
    while (index < encoded.length) {
      int b;
      int shift = 0;
      int result = 0;
      
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
      
      coordinates.add(LatLng(lat / 1E5, lng / 1E5));
    }
    
    return coordinates;
  }
  
  /// Calculate bounds for all routes
  LatLngBounds? _calculateRoutesBounds() {
    if (_routes.isEmpty) return null;
    
    double? minLat, maxLat, minLng, maxLng;
    
    for (final route in _routes) {
      final coordinates = _decodePolyline(route.geometry);
      
      for (final coord in coordinates) {
        minLat = minLat == null ? coord.latitude : math.min(minLat, coord.latitude);
        maxLat = maxLat == null ? coord.latitude : math.max(maxLat, coord.latitude);
        minLng = minLng == null ? coord.longitude : math.min(minLng, coord.longitude);
        maxLng = maxLng == null ? coord.longitude : math.max(maxLng, coord.longitude);
      }
    }
    
    if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
      return null;
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
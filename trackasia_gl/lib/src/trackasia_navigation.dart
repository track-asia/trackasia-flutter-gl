part of '../trackasia_gl.dart';

/// High-level navigation API for TrackAsia Flutter GL
class TrackAsiaNavigation {
  final TrackAsiaPlatform _platform;

  static TrackAsiaNavigation? _instance;

  // Stream controllers for navigation events
  final StreamController<NavigationEvent> _navigationEventController = StreamController<NavigationEvent>.broadcast();
  final StreamController<RouteProgress> _routeProgressController = StreamController<RouteProgress>.broadcast();
  final StreamController<VoiceInstruction> _voiceInstructionController = StreamController<VoiceInstruction>.broadcast();
  final StreamController<BannerInstruction> _bannerInstructionController = StreamController<BannerInstruction>.broadcast();

  /// Get the singleton instance
  static TrackAsiaNavigation get instance {
    _instance ??= TrackAsiaNavigation._();
    return _instance!;
  }

  /// Create a new TrackAsiaNavigation instance
  factory TrackAsiaNavigation() {
    return TrackAsiaNavigation._(TrackAsiaPlatform.createInstance());
  }

  TrackAsiaNavigation._([TrackAsiaPlatform? platform]) : _platform = platform ?? TrackAsiaPlatform.createInstance();

  /// Navigation event stream
  Stream<NavigationEvent> get onNavigationEvent {
    return _navigationEventController.stream;
  }

  /// Route progress stream
  Stream<RouteProgress> get onRouteProgress {
    return _routeProgressController.stream;
  }

  /// Voice instruction stream
  Stream<VoiceInstruction> get onVoiceInstruction {
    return _voiceInstructionController.stream;
  }

  /// Banner instruction stream
  Stream<BannerInstruction> get onBannerInstruction {
    return _bannerInstructionController.stream;
  }

  /// Calculate a route between waypoints
  ///
  /// [waypoints] - List of coordinates to navigate through
  /// [options] - Optional navigation configuration
  ///
  /// Returns a [NavigationRoute] if successful, null otherwise
  Future<NavigationRoute?> calculateRoute({
    required List<LatLng> waypoints,
    NavigationOptions? options,
  }) async {
    return await _platform.calculateRoute(
      waypoints: waypoints,
      options: options,
    );
  }

  /// Start navigation with the given route
  ///
  /// [route] - The route to navigate
  /// [options] - Optional navigation configuration
  Future<void> startNavigation({
    required NavigationRoute route,
    NavigationOptions? options,
  }) async {
    return _platform.startNavigation(
      route: route,
      options: options,
    );
  }

  /// Stop the current navigation session
  Future<void> stopNavigation() async {
    return _platform.stopNavigation();
  }

  /// Pause the current navigation session
  Future<void> pauseNavigation() async {
    return _platform.pauseNavigation();
  }

  /// Resume the paused navigation session
  Future<void> resumeNavigation() async {
    return _platform.resumeNavigation();
  }

  /// Check if navigation is currently active
  ///
  /// Returns true if navigation is active, false otherwise
  Future<bool> isNavigationActive() async {
    return await _platform.isNavigationActive();
  }

  /// Get the current route progress
  ///
  /// Returns [RouteProgress] if navigation is active, null otherwise
  Future<RouteProgress?> getCurrentRouteProgress() async {
    return await _platform.getCurrentRouteProgress();
  }
}

/// Extension methods for TrackAsiaMapController to add navigation functionality
extension TrackAsiaMapControllerNavigation on TrackAsiaMapController {
  /// Get the navigation instance for this map
  TrackAsiaNavigation get navigation => TrackAsiaNavigation._(_trackasiaPlatform);

  /// Quick method to calculate and start navigation
  ///
  /// [destination] - The destination coordinate
  /// [options] - Optional navigation configuration
  ///
  /// Returns true if navigation started successfully, false otherwise
  Future<bool> navigateTo(
    LatLng destination, {
    NavigationOptions? options,
  }) async {
    try {
      // Get current location as starting point
      final currentLocation = await requestMyLocationLatLng();
      if (currentLocation == null) {
        return false;
      }

      final startPoint = currentLocation;

      // Calculate route
      final route = await navigation.calculateRoute(
        waypoints: [startPoint, destination],
        options: options,
      );

      if (route == null) {
        return false;
      }

      // Start navigation
      await navigation.startNavigation(
        route: route,
        options: options,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Quick method to calculate and start navigation with multiple waypoints
  ///
  /// [waypoints] - List of coordinates to navigate through
  /// [options] - Optional navigation configuration
  ///
  /// Returns true if navigation started successfully, false otherwise
  Future<bool> navigateToWaypoints(
    List<LatLng> waypoints, {
    NavigationOptions? options,
  }) async {
    try {
      // Calculate route
      final route = await navigation.calculateRoute(
        waypoints: waypoints,
        options: options,
      );

      if (route == null) {
        return false;
      }

      // Start navigation
      await navigation.startNavigation(
        route: route,
        options: options,
      );

      return true;
    } catch (e) {
      return false;
    }
  }
}

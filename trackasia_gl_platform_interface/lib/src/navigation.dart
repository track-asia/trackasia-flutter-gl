part of '../trackasia_gl_platform_interface.dart';

/// Navigation options for route calculation and navigation UI
class NavigationOptions {
  /// Whether to enable voice guidance
  final bool enableVoiceGuidance;

  /// Whether to enable rerouting when off route
  final bool enableRerouting;

  /// Whether to simulate navigation for testing
  final bool simulateRoute;

  /// Navigation profile (driving, walking, cycling)
  final NavigationProfile profile;

  /// Language for voice instructions
  final String? language;

  /// Units for distance (metric, imperial)
  final DistanceUnits units;

  /// Theme configuration for navigation UI
  final NavigationTheme? theme;

  /// Whether to show alternative routes
  final bool showAlternativeRoutes;

  /// Whether to enable turn-by-turn navigation UI
  final bool enableNavigationUI;

  /// Custom navigation UI configuration
  final NavigationUIConfig? uiConfig;

  /// Route refresh interval in seconds
  final int? routeRefreshInterval;

  /// Whether to enable offline navigation
  final bool enableOfflineNavigation;

  const NavigationOptions({
    this.enableVoiceGuidance = true,
    this.enableRerouting = true,
    this.simulateRoute = false,
    this.profile = NavigationProfile.car,
    this.language,
    this.units = DistanceUnits.metric,
    this.theme,
    this.showAlternativeRoutes = true,
    this.enableNavigationUI = true,
    this.uiConfig,
    this.routeRefreshInterval,
    this.enableOfflineNavigation = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'enableVoiceGuidance': enableVoiceGuidance,
      'enableRerouting': enableRerouting,
      'simulateRoute': simulateRoute,
      'profile': profile.name,
      'language': language,
      'units': units.name,
      'theme': theme?.toMap(),
      'showAlternativeRoutes': showAlternativeRoutes,
      'enableNavigationUI': enableNavigationUI,
      'uiConfig': uiConfig?.toMap(),
      'routeRefreshInterval': routeRefreshInterval,
      'enableOfflineNavigation': enableOfflineNavigation,
    };
  }
}

/// Navigation profile types
enum NavigationProfile {
  car,
  walk,
  moto,
  truck,
}

/// Distance units
enum DistanceUnits {
  metric,
  imperial,
}

/// Navigation event types
enum NavigationEventType {
  routeProgress,
  routeRecalculation,
  reroute,
  arrival,
  offRoute,
  navigationStarted,
  navigationStopped,
  navigationPaused,
  navigationResumed,
  navigationEnded,
  voiceInstruction,
  bannerInstruction,
}

/// Navigation event data
class NavigationEvent {
  final NavigationEventType type;
  final Map<String, dynamic>? data;

  const NavigationEvent({
    required this.type,
    this.data,
  });

  factory NavigationEvent.fromMap(Map<String, dynamic> map) {
    return NavigationEvent(
      type: NavigationEventType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NavigationEventType.routeProgress,
      ),
      data: map['data'],
    );
  }
}

/// Route progress information
class RouteProgress {
  /// Distance remaining in meters
  final double distanceRemaining;

  /// Duration remaining in seconds
  final double _durationRemaining;

  /// Duration remaining as Duration object
  Duration get durationRemaining => Duration(seconds: _durationRemaining.round());

  /// Distance traveled in meters
  final double distanceTraveled;

  /// Fraction of route completed (0.0 to 1.0)
  final double fractionTraveled;

  /// Current step index
  final int currentStepIndex;

  /// Current leg index
  final int currentLegIndex;

  const RouteProgress({
    required this.distanceRemaining,
    required double durationRemaining,
    required this.distanceTraveled,
    required this.fractionTraveled,
    required this.currentStepIndex,
    required this.currentLegIndex,
  }) : _durationRemaining = durationRemaining;

  factory RouteProgress.fromMap(Map<String, dynamic> map) {
    return RouteProgress(
      distanceRemaining: (map['distanceRemaining'] ?? 0.0).toDouble(),
      durationRemaining: (map['durationRemaining'] ?? 0.0).toDouble(),
      distanceTraveled: (map['distanceTraveled'] ?? 0.0).toDouble(),
      fractionTraveled: (map['fractionTraveled'] ?? 0.0).toDouble(),
      currentStepIndex: map['currentStepIndex'] ?? 0,
      currentLegIndex: map['currentLegIndex'] ?? 0,
    );
  }
}

/// Voice instruction data
class VoiceInstruction {
  /// The instruction text
  final String text;

  /// The announcement text (same as text for compatibility)
  String get announcement => text;

  /// Distance to the maneuver in meters
  final double distanceAlongGeometry;

  const VoiceInstruction({
    required this.text,
    required this.distanceAlongGeometry,
  });

  factory VoiceInstruction.fromMap(Map<String, dynamic> map) {
    return VoiceInstruction(
      text: map['text'] ?? '',
      distanceAlongGeometry: (map['distanceAlongGeometry'] ?? 0.0).toDouble(),
    );
  }
}

/// Banner instruction data
class BannerInstruction {
  /// Primary instruction text
  final String primaryText;

  /// Secondary instruction text
  final String? secondaryText;

  /// Distance to the maneuver in meters
  final double distanceAlongGeometry;

  /// Maneuver type
  final String? maneuverType;

  /// Maneuver modifier
  final String? maneuverModifier;

  const BannerInstruction({
    required this.primaryText,
    this.secondaryText,
    required this.distanceAlongGeometry,
    this.maneuverType,
    this.maneuverModifier,
  });

  factory BannerInstruction.fromMap(Map<String, dynamic> map) {
    return BannerInstruction(
      primaryText: map['primaryText'] ?? '',
      secondaryText: map['secondaryText'],
      distanceAlongGeometry: (map['distanceAlongGeometry'] ?? 0.0).toDouble(),
      maneuverType: map['maneuverType'],
      maneuverModifier: map['maneuverModifier'],
    );
  }
}

/// Navigation route data
class NavigationRoute {
  /// Route geometry as encoded polyline
  final String geometry;

  /// Route distance in meters
  final double distance;

  /// Route duration in seconds
  final double duration;

  /// Route waypoints as list of lat/lng maps
  final List<Map<String, double>> waypoints;

  const NavigationRoute({
    required this.geometry,
    required this.distance,
    required this.duration,
    required this.waypoints,
  });

  factory NavigationRoute.fromMap(Map<String, dynamic> map) {
    final waypointsList = map['waypoints'] as List<dynamic>? ?? [];
    final waypoints = waypointsList
        .map<Map<String, double>>((w) => {
              'latitude': (w['latitude'] ?? 0.0).toDouble(),
              'longitude': (w['longitude'] ?? 0.0).toDouble(),
            })
        .toList();

    return NavigationRoute(
      geometry: map['geometry'] ?? '',
      distance: (map['distance'] ?? 0.0).toDouble(),
      duration: (map['duration'] ?? 0.0).toDouble(),
      waypoints: waypoints,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'geometry': geometry,
      'distance': distance,
      'duration': duration,
      'waypoints': waypoints,
    };
  }
}

/// Navigation theme configuration
class NavigationTheme {
  /// Light theme resource ID (Android)
  final int? lightThemeResId;

  /// Dark theme resource ID (Android)
  final int? darkThemeResId;

  /// Whether to use system theme
  final bool useSystemTheme;

  /// Primary color for navigation UI
  final String? primaryColor;

  /// Secondary color for navigation UI
  final String? secondaryColor;

  const NavigationTheme({
    this.lightThemeResId,
    this.darkThemeResId,
    this.useSystemTheme = true,
    this.primaryColor,
    this.secondaryColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'lightThemeResId': lightThemeResId,
      'darkThemeResId': darkThemeResId,
      'useSystemTheme': useSystemTheme,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
    };
  }
}

/// Navigation UI configuration
class NavigationUIConfig {
  /// Whether to show speed limit
  final bool showSpeedLimit;

  /// Whether to show current speed
  final bool showCurrentSpeed;

  /// Whether to show arrival time
  final bool showArrivalTime;

  /// Whether to show distance remaining
  final bool showDistanceRemaining;

  /// Whether to show turn instructions
  final bool showTurnInstructions;

  /// Whether to show route overview button
  final bool showRouteOverview;

  /// Whether to show end navigation button
  final bool showEndNavigation;

  /// Whether to show recenter button
  final bool showRecenterButton;

  const NavigationUIConfig({
    this.showSpeedLimit = true,
    this.showCurrentSpeed = true,
    this.showArrivalTime = true,
    this.showDistanceRemaining = true,
    this.showTurnInstructions = true,
    this.showRouteOverview = true,
    this.showEndNavigation = true,
    this.showRecenterButton = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'showSpeedLimit': showSpeedLimit,
      'showCurrentSpeed': showCurrentSpeed,
      'showArrivalTime': showArrivalTime,
      'showDistanceRemaining': showDistanceRemaining,
      'showTurnInstructions': showTurnInstructions,
      'showRouteOverview': showRouteOverview,
      'showEndNavigation': showEndNavigation,
      'showRecenterButton': showRecenterButton,
    };
  }
}

/// Navigation callback types
typedef NavigationEventCallback = void Function(NavigationEvent event);
typedef RouteProgressCallback = void Function(RouteProgress progress);
typedef VoiceInstructionCallback = void Function(VoiceInstruction instruction);
typedef BannerInstructionCallback = void Function(BannerInstruction instruction);

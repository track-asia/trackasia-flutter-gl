# TrackAsia Navigation Architecture Documentation

## Overview

TrackAsia Navigation provides comprehensive navigation capabilities for Flutter applications with native Android and iOS implementations. The architecture consists of three main layers:

1. **Flutter Layer**: Dart APIs for navigation functionality
2. **Platform Interface**: Cross-platform abstractions
3. **Native Implementations**: Android (Kotlin/Java) and iOS (Swift) native code

## Flutter Layer Architecture

### Core Classes

#### NavigationMapRoute

**Location**: `lib/src/navigation_map_route.dart`

**Purpose**: Manages navigation routes display on the map

**Key Features**:
- Route visualization with customizable styling
- Multiple route support (primary + alternative routes)
- Route management (add, remove, clear)
- Camera fitting to route bounds
- Route visibility control

**Main Methods**:
```dart
// Route Management
Future<void> addRoute(DirectionsRoute route, {bool isPrimary = true})
Future<void> addRoutes(List<DirectionsRoute> routes)
Future<void> removeRoute(String routeId)
Future<void> clearRoutes()

// Styling and Display
Future<void> updateStyle(NavigationRouteStyle style)
Future<void> setVisible(String routeId, bool visible)
Future<void> fitCameraToRoutes({List<String>? routeIds, EdgeInsets? padding})
```

**Styling System**:
- `NavigationRouteStyle`: Main styling configuration
- `RouteStyle`: Detailed route appearance (colors, width, opacity)
- `MultiRouteConfig`: Configuration for multiple routes
- Support for primary/alternative route styling
- Traffic-aware styling
- Gradient and animation support

#### TrackAsiaNavigation

**Location**: `lib/src/trackasia_navigation.dart`

**Purpose**: Core navigation controller (Singleton pattern)

**Key Features**:
- Route calculation
- Turn-by-turn navigation
- Navigation state management
- Progress tracking
- Voice guidance

**Main Methods**:
```dart
// Route Calculation
Future<DirectionsRoute?> calculateRoute({
  required List<LatLng> waypoints,
  String profile = 'driving',
  String language = 'en',
  bool alternatives = false,
})

// Navigation Control
Future<void> startNavigation(DirectionsRoute route, {bool simulate = false})
Future<void> stopNavigation()
Future<void> pauseNavigation()
Future<void> resumeNavigation()

// State Management
Stream<NavigationProgress> get onProgressChanged
Stream<NavigationInstruction> get onInstructionChanged
Stream<NavigationEvent> get onNavigationEvent
```

#### Extension Methods

**TrackAsiaMapControllerNavigation**:
```dart
extension TrackAsiaMapControllerNavigation on TrackAsiaMapController {
  Future<void> navigateTo(LatLng destination, {bool simulate = false})
  Future<void> navigateToWaypoints(List<LatLng> waypoints, {bool simulate = false})
}
```

**TrackAsiaMapControllerNavigationRoute**:
```dart
extension TrackAsiaMapControllerNavigationRoute on TrackAsiaMapController {
  NavigationMapRoute createNavigationMapRoute() => NavigationMapRoute(this)
}
```

## Android Native Implementation

### NavigationMethodHandler.kt

**Location**: `android/src/main/java/com/trackasia/trackasiagl/NavigationMethodHandler.kt`

**Purpose**: Handles Flutter method calls for navigation functionality

**Key Components**:

#### Route Calculation
```kotlin
private fun calculateRoute(call: MethodCall, result: MethodChannel.Result) {
    // Convert Flutter waypoints to native Point objects
    // Call TrackAsia Directions API
    // Process response and display route on map
    // Return route data to Flutter
}
```

#### Navigation Management
```kotlin
private fun startNavigation(call: MethodCall, result: MethodChannel.Result) {
    // Prepare NavigationLauncherOptions
    // Launch NavigationLauncher with route
    // Handle navigation lifecycle
}

private fun stopNavigation(result: MethodChannel.Result) {
    // Stop active navigation
    // Clean up resources
}
```

#### Route Display Management
```kotlin
private fun addNavigationRoute(call: MethodCall, result: MethodChannel.Result) {
    // Add route to NavigationMapRoute
    // Handle primary vs alternative routes
    // Apply styling
}

private fun removeNavigationRoute(call: MethodCall, result: MethodChannel.Result) {
    // Remove specific route by ID
    // Update map display
}

private fun clearNavigationRoutes(result: MethodChannel.Result) {
    // Remove all routes
    // Reset navigation state
}
```

#### Key Dependencies
- `com.trackasia.navigation.android.navigation.ui.v5.NavigationLauncher`
- `com.trackasia.navigation.android.navigation.ui.v5.route.NavigationMapRoute`
- `com.trackasia.navigation.core.navigation.TrackAsiaNavigation`
- `com.trackasia.navigation.core.models.DirectionsRoute`

## iOS Native Implementation

### RouteHandler.swift

**Location**: `ios/Classes/RouteHandler.swift` (inferred from demo)

**Purpose**: Manages route calculation and display on iOS

**Key Features**:
```swift
class RouteHandler: ObservableObject {
    private var mapView: MLNMapView
    @Published var routes: [Route]?
    @Published var waypoints: [Waypoint] = []
    private var routeOptions: NavigationRouteOptions?
    @Published var currentRoute: Route?
    
    func requestRoute(from origin: CLLocationCoordinate2D, 
                     to destination: CLLocationCoordinate2D, 
                     completion: @escaping (Route?) -> Void)
    
    func addRoute(_ route: Route)
}
```

### WayPointView.swift

**Purpose**: Manages waypoint visualization

**Key Features**:
```swift
struct WaypointView {
    static func view(for annotation: MLNAnnotation) -> MLNAnnotationView?
    static func addWaypoints(mapView: MLNMapView, waypoints: [Waypoint])
    static func onWaypoints(mapView: MLNMapView, waypoints: [Waypoint])
}
```

## Platform Communication

### Method Channel Interface

**Channel Name**: `trackasia_navigation`

**Supported Methods**:

#### Route Management
- `calculateRoute`: Calculate route between waypoints
- `addNavigationRoute`: Add route to map display
- `addNavigationRoutes`: Add multiple routes
- `removeNavigationRoute`: Remove specific route
- `clearNavigationRoutes`: Remove all routes
- `setRouteVisibility`: Show/hide specific route
- `fitCameraToRoutes`: Adjust camera to show routes

#### Navigation Control
- `startNavigation`: Begin turn-by-turn navigation
- `stopNavigation`: End navigation session
- `getCurrentRoute`: Get active route information

### Data Models

#### DirectionsRoute
```dart
class DirectionsRoute {
  final String geometry;        // Polyline geometry
  final double distance;        // Route distance in meters
  final double duration;        // Route duration in seconds
  final List<RouteLeg> legs;    // Route segments
  final List<Waypoint> waypoints; // Route waypoints
}
```

#### NavigationProgress
```dart
class NavigationProgress {
  final double distanceRemaining;
  final double durationRemaining;
  final double distanceTraveled;
  final LatLng currentLocation;
  final RouteProgress routeProgress;
}
```

#### NavigationInstruction
```dart
class NavigationInstruction {
  final String text;
  final String type;
  final double distance;
  final String modifier;
}
```

## Demo Implementations

### Android Demo (MapWayPointFragment.kt)

**Key Features**:
- Address search with autocomplete
- Route calculation and display
- Multiple navigation options (TrackAsia vs Google Maps)
- Route information display (distance, duration)
- Map interaction (tap to set waypoints)
- 3D map toggle
- Location services integration

**Route Calculation Flow**:
1. User selects origin and destination
2. Validate points (minimum distance check)
3. Call TrackAsia Directions API
4. Process response and create DirectionsRoute
5. Display route on map using NavigationMapRoute
6. Show route information (distance, time)
7. Enable navigation options

### iOS Demo (MapRouteView.swift)

**Key Features**:
- SwiftUI-based interface
- Address input with map tap selection
- Route calculation integration
- Location services
- Route information display

## Best Practices

### Performance
- Use route caching for frequently requested routes
- Implement proper memory management for route objects
- Optimize polyline rendering for complex routes
- Use appropriate zoom levels for route display

### User Experience
- Provide clear visual feedback during route calculation
- Handle network errors gracefully
- Implement proper loading states
- Support offline navigation when possible

### Error Handling
- Validate waypoints before route calculation
- Handle API rate limiting
- Provide meaningful error messages
- Implement retry mechanisms for failed requests

### Security
- Secure API key storage
- Validate input parameters
- Implement proper permission handling
- Use HTTPS for all API communications

## Migration Guide

### From Legacy Route Drawing

**Old Approach**:
```dart
// Manual polyline drawing
mapController.addLine(LineOptions(
  geometry: routeCoordinates,
  lineColor: "#3bb2d0",
  lineWidth: 8.0,
));
```

**New Approach**:
```dart
// Using NavigationMapRoute
final navigationRoute = mapController.createNavigationMapRoute();
await navigationRoute.addRoute(directionsRoute);
```

### Benefits of New API
- Automatic styling management
- Built-in support for multiple routes
- Integrated camera management
- Consistent cross-platform behavior
- Better performance optimization

## API Reference Summary

### Flutter Classes
- `NavigationMapRoute`: Route display management
- `TrackAsiaNavigation`: Core navigation controller
- `NavigationRouteStyle`: Route styling configuration
- `RouteStyle`: Detailed route appearance
- `MultiRouteConfig`: Multiple route configuration

### Native Classes
- **Android**: `NavigationMethodHandler`, `NavigationMapRoute`
- **iOS**: `RouteHandler`, `WaypointView`

### Platform Support
- ✅ Android: Full support
- ✅ iOS: Full support
- ❌ Web: Not supported

### Requirements
- Flutter SDK: >=2.17.0
- TrackAsia GL: Latest version
- Dart: >=2.17.0
- Android: API level 21+
- iOS: 11.0+

This architecture provides a robust, scalable navigation solution with consistent APIs across platforms while leveraging native capabilities for optimal performance.
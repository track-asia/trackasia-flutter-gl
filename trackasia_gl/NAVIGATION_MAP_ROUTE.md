# NavigationMapRoute API Documentation

## Overview

`NavigationMapRoute` is a powerful class for managing navigation routes on TrackAsia maps, providing advanced route visualization, styling, and management capabilities similar to native NavigationMapRoute implementations.

## Features

- **Single and Multiple Route Support**: Add individual routes or multiple routes with different styling
- **Advanced Route Styling**: Customize route appearance with colors, widths, casing, and opacity
- **Route Management**: Add, remove, clear, and toggle visibility of routes
- **Camera Integration**: Automatically fit camera to show all routes
- **Platform Integration**: Seamless communication with native Android and iOS implementations

## Basic Usage

### Creating NavigationMapRoute

```dart
NavigationMapRoute? _navigationMapRoute;

void _onMapCreated(TrackAsiaMapController controller) {
  _navigationMapRoute = NavigationMapRoute(mapController: controller);
}
```

### Adding a Single Route

```dart
Future<void> _addSingleRoute() async {
  final route = await TrackAsiaNavigation.calculateRoute(
    origin: LatLng(21.0285, 105.8542), // Hanoi
    destination: LatLng(10.8231, 106.6297), // Ho Chi Minh City
    options: NavigationOptions(
      profile: NavigationProfile.car,
      language: 'vi',
    ),
  );

  if (route != null) {
    await _navigationMapRoute!.addRoute(
      route,
      style: RouteStyle(
        lineColor: '#2196F3',
        lineWidth: 8.0,
        casingColor: '#FFFFFF',
        casingWidth: 12.0,
      ),
    );
  }
}
```

### Adding Multiple Routes

```dart
Future<void> _addMultipleRoutes() async {
  final routes = await TrackAsiaNavigation.calculateRoutes(
    origin: LatLng(21.0285, 105.8542),
    destination: LatLng(10.8231, 106.6297),
    options: NavigationOptions(
      profile: NavigationProfile.car,
      language: 'vi',
    ),
  );

  if (routes.isNotEmpty) {
    await _navigationMapRoute!.addRoutes(
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
  }
}
```

## API Reference

### Constructor

```dart
NavigationMapRoute({
  required TrackAsiaMapController mapController,
  NavigationRouteStyle? style,
})
```

**Parameters:**
- `mapController`: The TrackAsia map controller instance
- `style`: Optional default styling for routes

### Methods

#### addRoute

```dart
Future<String> addRoute(
  NavigationRoute route, {
  RouteStyle? style,
  String? routeId,
  bool isPrimary = false,
})
```

Adds a single route to the map with custom styling.

**Parameters:**
- `route`: The navigation route to add
- `style`: Optional route styling
- `routeId`: Optional custom route ID
- `isPrimary`: Whether this is the primary route

**Returns:** Route ID string

#### addRoutes

```dart
Future<List<String>> addRoutes(
  List<NavigationRoute> routes, {
  RouteStyle? primaryStyle,
  RouteStyle? alternativeStyle,
  MultiRouteConfig? config,
})
```

Adds multiple routes with different styling for primary and alternative routes.

**Parameters:**
- `routes`: List of navigation routes
- `primaryStyle`: Styling for the primary route
- `alternativeStyle`: Styling for alternative routes
- `config`: Configuration for multiple routes

**Returns:** List of route ID strings

#### removeRoute

```dart
Future<void> removeRoute(String routeId)
```

Removes a specific route by ID.

#### clearRoutes

```dart
Future<void> clearRoutes()
```

Removes all routes from the map.

#### setVisible

```dart
Future<void> setVisible(bool visible)
```

Shows or hides all routes.

#### fitCameraToRoutes

```dart
Future<void> fitCameraToRoutes({
  EdgeInsets? padding,
  bool animated = true,
})
```

Adjusts the camera to show all routes within the viewport.

### Properties

#### routes

```dart
List<NavigationRoute> get routes
```

Returns an unmodifiable list of current routes.

#### isVisible

```dart
bool get isVisible
```

Returns whether routes are currently visible.

#### primaryRoute

```dart
NavigationRoute? get primaryRoute
```

Returns the primary route (first route in the list).

#### alternativeRoutes

```dart
List<NavigationRoute> get alternativeRoutes
```

Returns all alternative routes (excluding the primary route).

## Route Styling

### RouteStyle

```dart
class RouteStyle {
  final String lineColor;
  final double lineWidth;
  final String? casingColor;
  final double? casingWidth;
  final double lineOpacity;
  final double? casingOpacity;

  const RouteStyle({
    this.lineColor = '#007AFF',
    this.lineWidth = 6.0,
    this.casingColor,
    this.casingWidth,
    this.lineOpacity = 1.0,
    this.casingOpacity = 1.0,
  });

  // Predefined styles
  static RouteStyle primary() => RouteStyle(
    lineColor: '#007AFF',
    lineWidth: 8.0,
    casingColor: '#FFFFFF',
    casingWidth: 12.0,
  );

  static RouteStyle alternative() => RouteStyle(
    lineColor: '#8E8E93',
    lineWidth: 6.0,
    casingColor: '#FFFFFF',
    casingWidth: 10.0,
  );
}
```

### NavigationRouteStyle

```dart
class NavigationRouteStyle {
  final double routeOpacity;
  final double casingOpacity;
  final bool showArrows;
  final double arrowSpacing;

  const NavigationRouteStyle({
    this.routeOpacity = 1.0,
    this.casingOpacity = 1.0,
    this.showArrows = false,
    this.arrowSpacing = 100.0,
  });

  static NavigationRouteStyle defaultStyle() => NavigationRouteStyle();
}
```

## Multi-Route Configuration

### MultiRouteConfig

```dart
class MultiRouteConfig {
  final int maxAlternativeRoutes;
  final bool showAlternativeRoutes;
  final double alternativeRouteOpacity;

  const MultiRouteConfig({
    this.maxAlternativeRoutes = 2,
    this.showAlternativeRoutes = true,
    this.alternativeRouteOpacity = 0.7,
  });
}
```

## Migration Guide

### From Previous Implementation

If you're migrating from a previous navigation implementation:

1. **Replace direct route drawing** with `NavigationMapRoute`:
   ```dart
   // Old way
   await mapController.addLine(lineOptions);
   
   // New way
   await navigationMapRoute.addRoute(route, style: routeStyle);
   ```

2. **Update route styling** to use new `RouteStyle` class:
   ```dart
   // Old way
   LineOptions(lineColor: "#FF0000", lineWidth: 5.0)
   
   // New way
   RouteStyle(lineColor: "#FF0000", lineWidth: 5.0)
   ```

3. **Use new route management methods**:
   ```dart
   // Clear all routes
   await navigationMapRoute.clearRoutes();
   
   // Toggle visibility
   await navigationMapRoute.setVisible(false);
   
   // Fit camera to routes
   await navigationMapRoute.fitCameraToRoutes();
   ```

## Best Practices

1. **Route Styling**: Use predefined styles (`RouteStyle.primary()`, `RouteStyle.alternative()`) for consistency
2. **Performance**: Clear routes when not needed to improve map performance
3. **User Experience**: Use `fitCameraToRoutes()` to ensure all routes are visible
4. **Error Handling**: Always wrap route operations in try-catch blocks
5. **Memory Management**: Dispose of `NavigationMapRoute` when the map controller is disposed

## Example Implementation

See `trackasia_gl_example/lib/navigation_map_route_example.dart` for a complete working example demonstrating all NavigationMapRoute features.

## Platform Support

- ✅ Android
- ✅ iOS
- ❌ Web (not supported)

## Requirements

- Flutter SDK: >=2.17.0
- TrackAsia GL: >=0.16.0
- Dart: >=2.17.0
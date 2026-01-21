# TrackAsia Flutter GL - iOS Navigation Setup

## Overview

The iOS plugin provides navigation capabilities that can work with or without additional navigation libraries.

## Basic Setup (Recommended)

By default, the plugin uses HTTP API for route calculation and provides basic route display functionality. No additional setup required.

```yaml
dependencies:
  trackasia_gl: ^2.0.3
```

## Advanced Setup (Optional Navigation Libraries)

If you have access to MapboxDirections and MapboxNavigation libraries, you can add them to your `ios/Podfile` for enhanced navigation features:

```ruby
target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Optional: Add navigation libraries if available
  # pod 'MapboxDirections', '~> 2.0'
  # pod 'MapboxCoreNavigation', '~> 2.0'  
  # pod 'MapboxNavigation', '~> 2.0'
end
```

## Features by Setup Type

### Basic Setup (HTTP API)
✅ Route calculation via TrackAsia HTTP API  
✅ Route display on map with custom styling  
✅ Multiple routes support  
✅ Fallback to straight-line routes  
✅ Basic navigation tracking  

### Advanced Setup (with Navigation Libraries)
✅ All basic features  
✅ Enhanced route calculation via Directions SDK  
✅ Turn-by-turn navigation UI (when implemented)  
✅ Voice guidance (when implemented)  
✅ Route progress tracking  

## API Usage

Both setups use the same Flutter API:

```dart
// Calculate route
final route = await TrackAsiaNavigation.calculateRoute(
  waypoints: [origin, destination],
  options: NavigationOptions(
    profile: NavigationProfile.car,
    language: 'vi',
  ),
);

// Display route
await navigationMapRoute.addRoute(route, style: RouteStyle(
  lineColor: '#2196F3',
  lineWidth: 8.0,
));

// Start navigation  
await TrackAsiaNavigation.startNavigation(
  route: route,
  options: NavigationOptions(simulateRoute: true),
);
```

## Troubleshooting

### Pod Install Issues
If you encounter dependency issues, ensure you're using basic setup without optional navigation libraries.

### Route Calculation
- Basic setup uses TrackAsia HTTP API (https://maps.track-asia.com/route/v1/)
- Requires internet connection
- Automatically falls back to straight-line routes if API fails

### Navigation
- Basic setup provides route tracking without turn-by-turn UI
- Full navigation UI requires additional navigation libraries

## Migration from Native Demo

If migrating from TrackAsia native iOS demo:
1. Copy `libs/trackasia-navigation-ios` to your iOS project
2. Add dependencies to Podfile
3. Uncomment navigation dependencies in trackasia_gl.podspec locally

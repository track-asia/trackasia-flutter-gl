# TrackAsia Navigation - Hướng Dẫn Triển Khai

## Tổng Quan

Hướng dẫn này cung cấp các bước chi tiết để triển khai TrackAsia Navigation trong ứng dụng Flutter, dựa trên phân tích từ các file documentation đã tạo.

## Cài Đặt và Cấu Hình

### 1. Dependencies

Thêm vào `pubspec.yaml`:
```yaml
dependencies:
  trackasia_gl: ^latest_version
  flutter:
    sdk: flutter
```

### 2. Platform Configuration

#### Android (android/app/build.gradle)
```gradle
android {
    compileSdkVersion 33
    minSdkVersion 21
    targetSdkVersion 33
}

dependencies {
    implementation 'com.trackasia.android:trackasia-android-sdk:latest'
    implementation 'com.trackasia.android:trackasia-android-navigation:latest'
}
```

#### iOS (ios/Podfile)
```ruby
platform :ios, '11.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  
  pod 'TrackasiaGL'
  pod 'TrackasiaNavigation'
end
```

### 3. Permissions

#### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

#### iOS (ios/Runner/Info.plist)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access for navigation</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs location access for navigation</string>
```

## Triển Khai Cơ Bản

### 1. Khởi Tạo Map với Navigation

```dart
class NavigationMapPage extends StatefulWidget {
  @override
  _NavigationMapPageState createState() => _NavigationMapPageState();
}

class _NavigationMapPageState extends State<NavigationMapPage> {
  TrackAsiaMapController? _mapController;
  NavigationMapRoute? _navigationMapRoute;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TrackAsiaMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: LatLng(10.7720, 106.6980),
          zoom: 14.0,
        ),
        myLocationEnabled: true,
        myLocationTrackingMode: MyLocationTrackingMode.tracking,
      ),
    );
  }
  
  void _onMapCreated(TrackAsiaMapController controller) {
    _mapController = controller;
    _navigationMapRoute = controller.createNavigationMapRoute();
  }
}
```

### 2. Tính Toán Route

```dart
Future<void> calculateRoute(List<LatLng> waypoints) async {
  try {
    setState(() {
      _isCalculatingRoute = true;
    });
    
    // Sử dụng TrackAsia Navigation để tính route
    final route = await TrackAsiaNavigation.instance.calculateRoute(
      waypoints: waypoints,
      profile: 'driving', // driving, walking, cycling
      language: 'vi',
      alternatives: true,
    );
    
    if (route != null && _navigationMapRoute != null) {
      // Hiển thị route trên map
      await _navigationMapRoute!.addRoute(route, isPrimary: true);
      
      // Fit camera để hiển thị toàn bộ route
      await _navigationMapRoute!.fitCameraToRoutes(
        padding: EdgeInsets.all(50),
      );
      
      setState(() {
        _routeInfo = 'Khoảng cách: ${route.distance}m, Thời gian: ${route.duration}s';
      });
    }
  } catch (e) {
    _showError('Lỗi tính toán route: $e');
  } finally {
    setState(() {
      _isCalculatingRoute = false;
    });
  }
}
```

### 3. Tùy Chỉnh Styling

```dart
Future<void> applyCustomStyling() async {
  final style = NavigationRouteStyle(
    routeStyle: RouteStyle(
      routeColor: Colors.blue,
      routeWidth: 8.0,
      routeOpacity: 0.8,
    ),
    alternativeRouteStyle: RouteStyle(
      routeColor: Colors.grey,
      routeWidth: 6.0,
      routeOpacity: 0.6,
    ),
    waypointStyle: WaypointStyle(
      waypointColor: Colors.red,
      waypointRadius: 8.0,
    ),
  );
  
  await _navigationMapRoute?.updateStyle(style);
}
```

### 4. Quản Lý Multiple Routes

```dart
Future<void> addMultipleRoutes() async {
  final waypoints = [
    LatLng(10.7720, 106.6980),
    LatLng(10.8231, 106.6297),
  ];
  
  // Tính toán routes với các profile khác nhau
  final profiles = ['driving', 'walking', 'cycling'];
  final colors = [Colors.blue, Colors.green, Colors.orange];
  
  for (int i = 0; i < profiles.length; i++) {
    try {
      final route = await TrackAsiaNavigation.instance.calculateRoute(
        waypoints: waypoints,
        profile: profiles[i],
      );
      
      if (route != null) {
        // Tạo style riêng cho mỗi route
        final style = NavigationRouteStyle(
          routeStyle: RouteStyle(
            routeColor: colors[i],
            routeWidth: 6.0 + i * 2,
          ),
        );
        
        await _navigationMapRoute?.addRoute(route, isPrimary: i == 0);
        await _navigationMapRoute?.updateStyle(style);
      }
    } catch (e) {
      print('Lỗi tính route ${profiles[i]}: $e');
    }
  }
}
```

## Tính Năng Nâng Cao

### 1. Turn-by-Turn Navigation

```dart
Future<void> startNavigation(DirectionsRoute route) async {
  try {
    // Bắt đầu navigation
    await TrackAsiaNavigation.instance.startNavigation(
      route,
      simulate: false, // true cho testing
    );
    
    // Lắng nghe progress updates
    TrackAsiaNavigation.instance.onProgressChanged.listen((progress) {
      setState(() {
        _currentProgress = progress;
      });
    });
    
    // Lắng nghe navigation instructions
    TrackAsiaNavigation.instance.onInstructionChanged.listen((instruction) {
      _showNavigationInstruction(instruction);
    });
    
  } catch (e) {
    _showError('Lỗi bắt đầu navigation: $e');
  }
}

void _showNavigationInstruction(NavigationInstruction instruction) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(instruction.text),
      duration: Duration(seconds: 3),
    ),
  );
}
```

### 2. Route Visibility Control

```dart
Future<void> toggleRouteVisibility(String routeId) async {
  final isVisible = _routeVisibility[routeId] ?? true;
  await _navigationMapRoute?.setVisible(routeId, !isVisible);
  setState(() {
    _routeVisibility[routeId] = !isVisible;
  });
}
```

### 3. Camera Management

```dart
Future<void> focusOnRoute(String routeId) async {
  await _navigationMapRoute?.fitCameraToRoutes(
    routeIds: [routeId],
    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 100),
  );
}

Future<void> animateToWaypoint(LatLng waypoint) async {
  await _mapController?.animateCamera(
    CameraUpdateOptions(
      target: waypoint,
      zoom: 16.0,
    ),
  );
}
```

## Error Handling và Best Practices

### 1. Comprehensive Error Handling

```dart
class NavigationErrorHandler {
  static void handleNavigationError(dynamic error) {
    if (error is NetworkException) {
      _showError('Lỗi kết nối mạng. Vui lòng kiểm tra internet.');
    } else if (error is RouteNotFoundException) {
      _showError('Không tìm thấy tuyến đường. Vui lòng thử lại.');
    } else if (error is LocationPermissionException) {
      _showError('Cần cấp quyền truy cập vị trí.');
    } else {
      _showError('Đã xảy ra lỗi: ${error.toString()}');
    }
  }
  
  static void _showError(String message) {
    // Implementation để hiển thị error
  }
}
```

### 2. Performance Optimization

```dart
class NavigationPerformanceOptimizer {
  // Debounce route calculations
  Timer? _routeCalculationTimer;
  
  void debouncedCalculateRoute(List<LatLng> waypoints) {
    _routeCalculationTimer?.cancel();
    _routeCalculationTimer = Timer(Duration(milliseconds: 500), () {
      calculateRoute(waypoints);
    });
  }
  
  // Cleanup resources
  void dispose() {
    _routeCalculationTimer?.cancel();
    _navigationMapRoute?.clearRoutes();
  }
}
```

### 3. State Management

```dart
class NavigationState {
  final List<NavigationRoute> routes;
  final bool isCalculating;
  final String? error;
  final NavigationProgress? progress;
  
  NavigationState({
    this.routes = const [],
    this.isCalculating = false,
    this.error,
    this.progress,
  });
  
  NavigationState copyWith({
    List<NavigationRoute>? routes,
    bool? isCalculating,
    String? error,
    NavigationProgress? progress,
  }) {
    return NavigationState(
      routes: routes ?? this.routes,
      isCalculating: isCalculating ?? this.isCalculating,
      error: error ?? this.error,
      progress: progress ?? this.progress,
    );
  }
}
```

## Testing

### 1. Unit Tests

```dart
void main() {
  group('Navigation Tests', () {
    test('should calculate route successfully', () async {
      final waypoints = [
        LatLng(10.7720, 106.6980),
        LatLng(10.8231, 106.6297),
      ];
      
      final route = await TrackAsiaNavigation.instance.calculateRoute(
        waypoints: waypoints,
        profile: 'driving',
      );
      
      expect(route, isNotNull);
      expect(route!.waypoints.length, equals(2));
    });
  });
}
```

### 2. Integration Tests

```dart
void main() {
  group('Navigation Integration Tests', () {
    testWidgets('should display route on map', (WidgetTester tester) async {
      await tester.pumpWidget(MyApp());
      
      // Tap calculate route button
      await tester.tap(find.byKey(Key('calculate_route_button')));
      await tester.pumpAndSettle();
      
      // Verify route is displayed
      expect(find.text('Khoảng cách:'), findsOneWidget);
    });
  });
}
```

## Deployment

### 1. Production Configuration

```dart
class NavigationConfig {
  static const String apiKey = String.fromEnvironment('TRACKASIA_API_KEY');
  static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: false);
  
  static void configure() {
    TrackAsiaNavigation.configure(
      apiKey: apiKey,
      enableLogging: enableLogging,
    );
  }
}
```

### 2. Security Best Practices

- Không hardcode API keys trong source code
- Sử dụng environment variables
- Implement proper input validation
- Use HTTPS cho tất cả API calls
- Validate user permissions trước khi access location

## Kết Luận

Hướng dẫn này cung cấp foundation hoàn chỉnh để triển khai TrackAsia Navigation trong Flutter app. Kết hợp với các file documentation khác (TRACKASIA_NAVIGATION_ARCHITECTURE.md, ANDROID_NAVIGATION_IMPLEMENTATION.md, IOS_NAVIGATION_IMPLEMENTATION.md), bạn có thể xây dựng navigation solution mạnh mẽ và scalable.

### Tài Liệu Tham Khảo

- [TRACKASIA_NAVIGATION_ARCHITECTURE.md](./TRACKASIA_NAVIGATION_ARCHITECTURE.md)
- [ANDROID_NAVIGATION_IMPLEMENTATION.md](./ANDROID_NAVIGATION_IMPLEMENTATION.md)
- [IOS_NAVIGATION_IMPLEMENTATION.md](./IOS_NAVIGATION_IMPLEMENTATION.md)
- [DEMO_IMPLEMENTATIONS_ANALYSIS.md](./DEMO_IMPLEMENTATIONS_ANALYSIS.md)
- [NAVIGATION_ROUTE_EXAMPLE_ANALYSIS.md](./NAVIGATION_ROUTE_EXAMPLE_ANALYSIS.md)
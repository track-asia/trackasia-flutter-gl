# TrackAsia Navigation - iOS Native Implementation

## Overview

The iOS native implementation of TrackAsia Navigation is built using Swift and integrates with the TrackAsia Maps SDK for iOS. The main components are `RouteHandler.swift` for route calculation and management, and `WayPointView.swift` for waypoint visualization.

## Core Components

### RouteHandler.swift

**Location**: `ios/Classes/RouteHandler.swift`

**Purpose**: Central handler for route calculation, navigation management, and route display

#### Class Structure

```swift
import Foundation
import TrackasiaGL
import CoreLocation

class RouteHandler: ObservableObject {
    // Type aliases for completion handlers
    typealias RouteRequestSuccess = ([Routelog]) -> Void
    typealias RouteRequestFailure = (Error) -> Void
    
    // Core properties
    @Published var mapView: MGLMapView?
    @Published var routes: [Routelog] = []
    @Published var waypoints: [CLLocationCoordinate2D] = []
    @Published var routeOptions: RouteOptions?
    @Published var currentRoute: Routelog?
    
    // Navigation state
    private var isNavigationActive = false
    private var currentRouteSource: MGLSource?
    private var currentRouteLayer: MGLLineStyleLayer?
    
    init(mapView: MGLMapView?) {
        self.mapView = mapView
    }
}
```

#### Key Dependencies

```swift
// TrackAsia Maps SDK
import TrackasiaGL

// Core Location for coordinates
import CoreLocation

// Foundation for networking and data handling
import Foundation

// Combine for reactive programming
import Combine
```

## Core Functionality

### 1. Route Calculation

#### handleRequestRoute Method

```swift
func handleRequestRoute(
    origin: CLLocationCoordinate2D,
    destination: CLLocationCoordinate2D,
    waypoints: [CLLocationCoordinate2D] = [],
    profile: String = "driving",
    language: String = "en",
    alternatives: Bool = false,
    success: @escaping RouteRequestSuccess = defaultSuccess,
    failure: @escaping RouteRequestFailure = defaultFailure
) {
    // Create navigation route options
    let routeOptions = NavigationRouteOptions(
        coordinates: [origin] + waypoints + [destination],
        profileIdentifier: .automobile
    )
    
    // Store route options for later use
    self.routeOptions = routeOptions
    self.waypoints = [origin] + waypoints + [destination]
    
    // Request route calculation
    requestRoute(
        routeOptions: routeOptions,
        success: success,
        failure: failure
    )
}
```

#### requestRoute Method

```swift
private func requestRoute(
    routeOptions: RouteOptions,
    success: @escaping RouteRequestSuccess,
    failure: @escaping RouteRequestFailure
) {
    // Build API request URL
    let baseUrl = "https://maps.track-asia.com/route/v1"
    let profile = "driving" // Default profile
    let coordinates = routeOptions.coordinates.map { "\($0.longitude),\($0.latitude)" }.joined(separator: ";")
    
    guard let url = URL(string: "\(baseUrl)/\(profile)/\(coordinates).json?geometries=polyline6&steps=true&overview=full&alternatives=\(routeOptions.includesAlternativeRoutes)&language=en&key=public_key") else {
        failure(RouteError.invalidURL)
        return
    }
    
    // Create URL request
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("TrackAsia iOS Navigation SDK", forHTTPHeaderField: "User-Agent")
    
    // Perform network request
    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        DispatchQueue.main.async {
            if let error = error {
                failure(error)
                return
            }
            
            guard let data = data else {
                failure(RouteError.noData)
                return
            }
            
            // Parse response
            self?.parseRouteResponse(data: data, success: success, failure: failure)
        }
    }.resume()
}
```

#### Route Response Parsing

```swift
private func parseRouteResponse(
    data: Data,
    success: @escaping RouteRequestSuccess,
    failure: @escaping RouteRequestFailure
) {
    do {
        // Decode JSON response
        let decoder = JSONDecoder()
        let response = try decoder.decode(DirectionsResponse.self, from: data)
        
        guard !response.routes.isEmpty else {
            failure(RouteError.noRoutes)
            return
        }
        
        // Convert to Routelog objects
        let routes = response.routes.map { route in
            Routelog(
                geometry: route.geometry ?? "",
                distance: route.distance ?? 0,
                duration: route.duration ?? 0,
                legs: route.legs?.map { leg in
                    Leg(
                        distance: leg.distance ?? 0,
                        duration: leg.duration ?? 0,
                        steps: leg.steps?.map { step in
                            Step(
                                distance: step.distance ?? 0,
                                duration: step.duration ?? 0,
                                instruction: step.maneuver?.instruction ?? "",
                                maneuver: Maneuver(
                                    instruction: step.maneuver?.instruction ?? "",
                                    type: step.maneuver?.type ?? "",
                                    location: step.maneuver?.location ?? [0, 0]
                                )
                            )
                        } ?? []
                    )
                } ?? []
            )
        }
        
        // Update state
        self.routes = routes
        self.currentRoute = routes.first
        
        // Call success handler
        success(routes)
        
    } catch {
        failure(error)
    }
}
```

### 2. Route Display

#### addRoute Method

```swift
func addRoute(_ route: Routelog, isPrimary: Bool = true) {
    guard let mapView = mapView else {
        print("MapView not available")
        return
    }
    
    // Remove existing route if this is primary
    if isPrimary {
        removeCurrentRoute()
    }
    
    // Decode polyline geometry
    guard let coordinates = decodePolyline(route.geometry) else {
        print("Failed to decode route geometry")
        return
    }
    
    // Create route line
    let routeLine = MGLPolyline(coordinates: coordinates, count: UInt(coordinates.count))
    
    // Create source
    let sourceIdentifier = isPrimary ? "route-source" : "route-alternative-source-\(UUID().uuidString)"
    let source = MGLShapeSource(identifier: sourceIdentifier, shape: routeLine, options: nil)
    
    // Add source to map
    mapView.style?.addSource(source)
    
    // Create line layer
    let layerIdentifier = isPrimary ? "route-layer" : "route-alternative-layer-\(UUID().uuidString)"
    let lineLayer = MGLLineStyleLayer(identifier: layerIdentifier, source: source)
    
    // Configure line style
    if isPrimary {
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.systemBlue)
        lineLayer.lineWidth = NSExpression(forConstantValue: 6)
    } else {
        lineLayer.lineColor = NSExpression(forConstantValue: UIColor.systemGray)
        lineLayer.lineWidth = NSExpression(forConstantValue: 4)
    }
    
    lineLayer.lineOpacity = NSExpression(forConstantValue: 0.8)
    lineLayer.lineCap = NSExpression(forConstantValue: "round")
    lineLayer.lineJoin = NSExpression(forConstantValue: "round")
    
    // Add layer to map
    mapView.style?.addLayer(lineLayer)
    
    // Store references for primary route
    if isPrimary {
        currentRouteSource = source
        currentRouteLayer = lineLayer
    }
    
    print("Route added to map: \(isPrimary ? "primary" : "alternative")")
}
```

#### removeCurrentRoute Method

```swift
func removeCurrentRoute() {
    guard let mapView = mapView else { return }
    
    // Remove current route layer and source
    if let layer = currentRouteLayer {
        mapView.style?.removeLayer(layer)
        currentRouteLayer = nil
    }
    
    if let source = currentRouteSource {
        mapView.style?.removeSource(source)
        currentRouteSource = nil
    }
}
```

#### clearAllRoutes Method

```swift
func clearAllRoutes() {
    guard let mapView = mapView else { return }
    
    // Remove all route-related layers and sources
    if let style = mapView.style {
        let layers = style.layers
        let sources = style.sources
        
        // Remove route layers
        for layer in layers {
            if layer.identifier.hasPrefix("route-") {
                style.removeLayer(layer)
            }
        }
        
        // Remove route sources
        for source in sources {
            if source.identifier.hasPrefix("route-") {
                style.removeSource(source)
            }
        }
    }
    
    // Clear state
    routes.removeAll()
    currentRoute = nil
    currentRouteSource = nil
    currentRouteLayer = nil
    waypoints.removeAll()
}
```

### 3. Utility Methods

#### decodePolyline Method

```swift
private func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D]? {
    guard !encoded.isEmpty else { return nil }
    
    var coordinates: [CLLocationCoordinate2D] = []
    var index = encoded.startIndex
    var lat = 0
    var lng = 0
    
    while index < encoded.endIndex {
        var b: Int
        var shift = 0
        var result = 0
        
        // Decode latitude
        repeat {
            guard index < encoded.endIndex else { break }
            b = Int(encoded[index].asciiValue! - 63)
            index = encoded.index(after: index)
            result |= (b & 0x1f) << shift
            shift += 5
        } while b >= 0x20
        
        let deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
        lat += deltaLat
        
        shift = 0
        result = 0
        
        // Decode longitude
        repeat {
            guard index < encoded.endIndex else { break }
            b = Int(encoded[index].asciiValue! - 63)
            index = encoded.index(after: index)
            result |= (b & 0x1f) << shift
            shift += 5
        } while b >= 0x20
        
        let deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
        lng += deltaLng
        
        let coordinate = CLLocationCoordinate2D(
            latitude: Double(lat) / 1e6,
            longitude: Double(lng) / 1e6
        )
        coordinates.append(coordinate)
    }
    
    return coordinates
}
```

## Data Models

### Routelog Structure

```swift
struct Routelog: Codable {
    let geometry: String
    let distance: Double
    let duration: Double
    let legs: [Leg]
    
    init(geometry: String, distance: Double, duration: Double, legs: [Leg]) {
        self.geometry = geometry
        self.distance = distance
        self.duration = duration
        self.legs = legs
    }
}
```

### Leg Structure

```swift
struct Leg: Codable {
    let distance: Double
    let duration: Double
    let steps: [Step]
    
    init(distance: Double, duration: Double, steps: [Step]) {
        self.distance = distance
        self.duration = duration
        self.steps = steps
    }
}
```

### Step Structure

```swift
struct Step: Codable {
    let distance: Double
    let duration: Double
    let instruction: String
    let maneuver: Maneuver
    
    init(distance: Double, duration: Double, instruction: String, maneuver: Maneuver) {
        self.distance = distance
        self.duration = duration
        self.instruction = instruction
        self.maneuver = maneuver
    }
}
```

### Maneuver Structure

```swift
struct Maneuver: Codable {
    let instruction: String
    let type: String
    let location: [Double]
    
    init(instruction: String, type: String, location: [Double]) {
        self.instruction = instruction
        self.type = type
        self.location = location
    }
}
```

## WayPointView.swift

**Purpose**: Manages waypoint visualization and annotation handling

### Class Structure

```swift
import Foundation
import TrackasiaGL
import CoreLocation

class WayPointView: NSObject {
    private weak var mapView: MGLMapView?
    private var waypoints: [CLLocationCoordinate2D] = []
    private var annotations: [MGLAnnotation] = []
    
    init(mapView: MGLMapView?) {
        self.mapView = mapView
        super.init()
    }
}
```

### Annotation Management

#### view(for annotation) Method

```swift
func view(for annotation: MGLAnnotation) -> MGLAnnotationView? {
    guard let mapView = mapView else { return nil }
    
    let reuseIdentifier = "waypoint-annotation"
    
    // Try to reuse existing annotation view
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
    
    if annotationView == nil {
        // Create new annotation view
        annotationView = MGLAnnotationView(reuseIdentifier: reuseIdentifier)
        annotationView?.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        
        // Create custom view
        let containerView = UIView(frame: annotationView!.bounds)
        containerView.backgroundColor = UIColor.systemBlue
        containerView.layer.cornerRadius = 15
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.white.cgColor
        
        // Add label for waypoint number
        let label = UILabel(frame: containerView.bounds)
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.text = annotation.title ?? ""
        
        containerView.addSubview(label)
        annotationView?.addSubview(containerView)
    }
    
    return annotationView
}
```

#### addWaypoints Method

```swift
func addWaypoints(_ coordinates: [CLLocationCoordinate2D]) {
    guard let mapView = mapView else { return }
    
    // Clear existing waypoints
    clearWaypoints()
    
    self.waypoints = coordinates
    
    // Create annotations for each waypoint
    for (index, coordinate) in coordinates.enumerated() {
        let annotation = MGLPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = "\(index + 1)"
        
        mapView.addAnnotation(annotation)
        annotations.append(annotation)
    }
    
    print("Added \(coordinates.count) waypoints to map")
}
```

#### onWaypoints Method

```swift
func onWaypoints(_ coordinates: [CLLocationCoordinate2D]) {
    guard coordinates.count >= 2 else {
        print("At least 2 waypoints required")
        return
    }
    
    guard let mapView = mapView else { return }
    
    // Clear existing waypoints
    clearWaypoints()
    
    // Add origin marker
    let originAnnotation = MGLPointAnnotation()
    originAnnotation.coordinate = coordinates.first!
    originAnnotation.title = "Origin"
    mapView.addAnnotation(originAnnotation)
    annotations.append(originAnnotation)
    
    // Add destination marker
    let destinationAnnotation = MGLPointAnnotation()
    destinationAnnotation.coordinate = coordinates.last!
    destinationAnnotation.title = "Destination"
    mapView.addAnnotation(destinationAnnotation)
    annotations.append(destinationAnnotation)
    
    // Add intermediate waypoints if any
    if coordinates.count > 2 {
        let intermediateWaypoints = Array(coordinates[1..<coordinates.count-1])
        for (index, coordinate) in intermediateWaypoints.enumerated() {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Waypoint \(index + 1)"
            mapView.addAnnotation(annotation)
            annotations.append(annotation)
        }
    }
    
    self.waypoints = coordinates
    print("Added origin, destination and \(coordinates.count - 2) intermediate waypoints")
}
```

#### clearWaypoints Method

```swift
func clearWaypoints() {
    guard let mapView = mapView else { return }
    
    // Remove all annotations
    for annotation in annotations {
        mapView.removeAnnotation(annotation)
    }
    
    annotations.removeAll()
    waypoints.removeAll()
    
    print("Cleared all waypoints")
}
```

## Error Handling

### RouteError Enumeration

```swift
enum RouteError: Error, LocalizedError {
    case invalidURL
    case noData
    case noRoutes
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for route request"
        case .noData:
            return "No data received from route service"
        case .noRoutes:
            return "No routes found"
        case .decodingError:
            return "Failed to decode route response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
```

### Default Error Handlers

```swift
static let defaultSuccess: RouteRequestSuccess = { routes in
    print("Route calculation successful: \(routes.count) routes found")
    for (index, route) in routes.enumerated() {
        print("Route \(index + 1): \(route.distance)m, \(route.duration)s")
    }
}

static let defaultFailure: RouteRequestFailure = { error in
    print("Route calculation failed: \(error.localizedDescription)")
}
```

## Integration with Flutter

### Method Channel Integration

```swift
// In FlutterTrackAsiaMapController.swift
private var routeHandler: RouteHandler?
private var waypointView: WayPointView?

func setupNavigation() {
    routeHandler = RouteHandler(mapView: mapView)
    waypointView = WayPointView(mapView: mapView)
    
    // Set delegate for annotation views
    mapView.delegate = self
}

// MARK: - MGLMapViewDelegate
extension FlutterTrackAsiaMapController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return waypointView?.view(for: annotation)
    }
}
```

### Flutter Method Handling

```swift
func handleNavigationMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments", details: nil))
        return
    }
    
    switch call.method {
    case "calculateRoute":
        handleCalculateRoute(args: args, result: result)
    case "addNavigationRoute":
        handleAddNavigationRoute(args: args, result: result)
    case "removeNavigationRoute":
        handleRemoveNavigationRoute(args: args, result: result)
    case "clearNavigationRoutes":
        handleClearNavigationRoutes(result: result)
    case "addWaypoints":
        handleAddWaypoints(args: args, result: result)
    case "clearWaypoints":
        handleClearWaypoints(result: result)
    default:
        result(FlutterMethodNotImplemented)
    }
}

private func handleCalculateRoute(args: [String: Any], result: @escaping FlutterResult) {
    guard let waypointsData = args["waypoints"] as? [[String: Double]],
          waypointsData.count >= 2 else {
        result(FlutterError(code: "INVALID_WAYPOINTS", message: "At least 2 waypoints required", details: nil))
        return
    }
    
    let coordinates = waypointsData.compactMap { waypoint -> CLLocationCoordinate2D? in
        guard let lat = waypoint["latitude"], let lng = waypoint["longitude"] else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }
    
    guard coordinates.count >= 2 else {
        result(FlutterError(code: "INVALID_COORDINATES", message: "Invalid coordinate data", details: nil))
        return
    }
    
    let origin = coordinates.first!
    let destination = coordinates.last!
    let waypoints = Array(coordinates[1..<coordinates.count-1])
    
    routeHandler?.handleRequestRoute(
        origin: origin,
        destination: destination,
        waypoints: waypoints,
        success: { routes in
            let routeData = routes.map { route in
                return [
                    "geometry": route.geometry,
                    "distance": route.distance,
                    "duration": route.duration,
                    "legs": route.legs.map { leg in
                        return [
                            "distance": leg.distance,
                            "duration": leg.duration,
                            "steps": leg.steps.map { step in
                                return [
                                    "instruction": step.instruction,
                                    "distance": step.distance,
                                    "duration": step.duration
                                ]
                            }
                        ]
                    }
                ]
            }
            result(routeData)
        },
        failure: { error in
            result(FlutterError(code: "ROUTE_CALCULATION_ERROR", message: error.localizedDescription, details: nil))
        }
    )
}
```

## Performance Considerations

1. **Memory Management**: Use weak references to avoid retain cycles
2. **Main Thread**: Ensure UI updates are performed on the main thread
3. **Annotation Reuse**: Implement annotation view reuse for better performance
4. **Polyline Optimization**: Use appropriate coordinate precision
5. **Network Caching**: Implement route caching for repeated requests

## Threading Considerations

- All map operations must be performed on the main thread
- Network requests are performed asynchronously
- Use `DispatchQueue.main.async` for UI thread operations
- Proper error handling in completion handlers

## Security Best Practices

1. **API Key Management**: Store API keys securely in iOS Keychain
2. **Input Validation**: Validate all coordinate and parameter inputs
3. **HTTPS**: Use secure connections for all API calls
4. **Location Privacy**: Handle location permissions appropriately
5. **Error Information**: Don't expose sensitive information in error messages

This iOS implementation provides a robust foundation for navigation functionality with proper error handling, memory management, and integration with the TrackAsia Maps SDK for iOS.
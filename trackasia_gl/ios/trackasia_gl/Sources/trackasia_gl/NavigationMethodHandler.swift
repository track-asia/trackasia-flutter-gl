/*
 * TrackAsia Navigation Method Handler for Flutter
 * Based on iOS Native Demo Implementation
 * Copyright (c) TrackAsia
 */

import Flutter
import Foundation
import TrackAsia
import UIKit
import CoreLocation

// TrackAsia Navigation imports (conditional)
#if canImport(MapboxDirections)
import MapboxDirections
#endif

#if canImport(MapboxCoreNavigation)
import MapboxCoreNavigation
#endif

#if canImport(MapboxNavigation)
import MapboxNavigation
#endif

/**
 * Handles navigation-related method calls from Flutter
 * Implements iOS native demo functionality for route calculation and navigation
 */
class NavigationMethodHandler: NSObject {
    private let registrar: FlutterPluginRegistrar
    
    // Navigation state
    private var isNavigationActive = false
    private var currentRouteData: [String: Any]?
    private var currentProgress: [String: Any]?
    
    // Map controllers registry to access MapView (from TrackAsiaMapController)
    private static var mapControllers: [Int: TrackAsiaMapController] = [:]
    
    // Route management similar to native demo (conditional)
    #if canImport(MapboxDirections)
    private var currentRoute: Route?
    #endif
    private var waypoints: [CLLocationCoordinate2D] = []
    private var routePolylines: [String: MLNPolyline] = [:]
    private var routeStyles: [String: [String: Any]] = [:]
    
    init(registrar: FlutterPluginRegistrar) {
        print("NavigationMethodHandler: Initializing...")
        self.registrar = registrar
        
        super.init()
        
        print("NavigationMethodHandler: Initialization complete")
    }
    
    // MARK: - Map Controller Registry
    
    static func registerMapController(_ controller: TrackAsiaMapController, withId id: Int) {
        mapControllers[id] = controller
        print("NavigationMethodHandler: Registered map controller with ID: \(id), total controllers: \(mapControllers.count)")
    }
    
    static func unregisterMapController(withId id: Int) {
        mapControllers.removeValue(forKey: id)
        print("NavigationMethodHandler: Unregistered map controller with ID: \(id)")
    }
    
    private func getMapView(fromCall call: FlutterMethodCall) -> MLNMapView? {
        // Try to get mapId from arguments
        if let arguments = call.arguments as? [String: Any],
           let mapId = arguments["mapId"] as? Int,
           let controller = NavigationMethodHandler.mapControllers[mapId] {
            return controller.mapView
        }
        
        // Fallback: use first available map controller
        if let firstController = NavigationMethodHandler.mapControllers.values.first {
            return firstController.mapView
        }
        
        print("❌ No MapView available for navigation operations")
        return nil
    }
    
    // MARK: - Method Call Handler
    
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("NavigationMethodHandler: Handling method: \(call.method)")
        switch call.method {
        case "navigation#calculateRoute":
            calculateRoute(call, result: result)
        case "navigation#start":
            startNavigation(call, result: result)
        case "navigation#stop":
            result(FlutterMethodNotImplemented) // stopNavigation(result: result)
        case "navigation#pause":
            result(FlutterMethodNotImplemented) // pauseNavigation(result: result)
        case "navigation#resume":
            result(FlutterMethodNotImplemented) // resumeNavigation(result: result)
        case "navigation#isActive":
            result(isNavigationActive)
        case "navigation#getProgress":
            result(currentProgress)
        // NavigationMapRoute methods
        case "navigationMapRoute#addRoute":
            addNavigationRoute(call, result: result)
        case "navigationMapRoute#addRoutes":
            result(FlutterMethodNotImplemented)
        case "navigationMapRoute#removeRoute":
            result(FlutterMethodNotImplemented)
        case "navigationMapRoute#clearRoutes":
            result(FlutterMethodNotImplemented)
        case "navigationMapRoute#setVisibility":
            result(FlutterMethodNotImplemented)
        case "navigationMapRoute#fitCameraToRoutes":
            result(FlutterMethodNotImplemented)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Route Calculation (Based on Native Demo)
    
    private func calculateRoute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("NavigationMethodHandler: calculateRoute called with arguments: \(String(describing: call.arguments))")
        
        guard let arguments = call.arguments as? [String: Any] else {
            print("NavigationMethodHandler: Failed to parse arguments")
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Arguments is not a dictionary",
                details: nil
            ))
            return
        }
        
        guard let waypoints = arguments["waypoints"] as? [[Double]] else {
            print("NavigationMethodHandler: Failed to parse waypoints")
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid waypoints format",
                details: nil
            ))
            return
        }
        
        guard waypoints.count >= 2 else {
            result(FlutterError(
                code: "INVALID_WAYPOINTS",
                message: "At least 2 waypoints are required",
                details: nil
            ))
            return
        }
        
        let options = arguments["options"] as? [String: Any]
        let profile = options?["profile"] as? String ?? "car"
        let language = options?["language"] as? String ?? "en"
        
        let coordinates = waypoints.compactMap { waypoint -> CLLocationCoordinate2D? in
            guard waypoint.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: waypoint[0], longitude: waypoint[1])
        }
        
        print("🔄 Calculating route from \(coordinates[0]) to \(coordinates[1])")
        
        // Use MapboxDirections if available (like native demo)
        #if canImport(MapboxDirections)
        calculateRouteWithMapboxDirections(from: coordinates[0], to: coordinates[1], profile: profile, language: language, result: result)
        #else
        // Fallback to TrackAsia API similar to Android
        calculateTrackAsiaRoute(from: coordinates[0], to: coordinates[1], profile: profile, language: language) { [weak self] routeData in
            DispatchQueue.main.async {
                if let routeData = routeData {
                    self?.currentRouteData = routeData
                    print("✅ Route calculated successfully: \(routeData["distance"] as? Double ?? 0.0)m")
                    result(routeData)
                } else {
                    print("⚠️ API failed, using straight line")
                    let straightLineRoute = self?.createStraightLineRoute(from: coordinates[0], to: coordinates[1])
                    self?.currentRouteData = straightLineRoute
                    result(straightLineRoute)
                }
            }
        }
        #endif
    }
    
    // MARK: - Route Calculation with MapboxDirections (Native Demo Style)
    
    #if canImport(MapboxDirections)
    private func calculateRouteWithMapboxDirections(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, profile: String, language: String, result: @escaping FlutterResult) {
        
        let originWaypoint = Waypoint(coordinate: origin)
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        let options = NavigationRouteOptions(waypoints: [originWaypoint, destinationWaypoint])
        
        // Set profile based on input
        switch profile.lowercased() {
        case "walking":
            options.profileIdentifier = .walking
        case "cycling":
            options.profileIdentifier = .cycling
        default:
            options.profileIdentifier = .automobile
        }
        
        print("🔄 Using MapboxDirections for route calculation...")
        
        Directions.shared.calculate(options) { [weak self] (waypoints, routes, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ MapboxDirections error: \(error.localizedDescription)")
                    // Fallback to straight line like native demo
                    let straightLineRoute = self?.createStraightLineRoute(from: origin, to: destination)
                    self?.currentRouteData = straightLineRoute
                    result(straightLineRoute)
                    return
                }
                
                if let route = routes?.first {
                    print("✅ Route calculated via MapboxDirections: \(String(format: "%.2f", route.distance / 1000)) km")
                    
                    // Store route object for navigation
                    #if canImport(MapboxDirections)
                    self?.currentRoute = route
                    #endif
                    
                    // Convert to Flutter format
                    let routeData = self?.convertRouteToFlutterFormat(route)
                    self?.currentRouteData = routeData
                    result(routeData)
                } else {
                    print("⚠️ No routes returned, using straight line")
                    let straightLineRoute = self?.createStraightLineRoute(from: origin, to: destination)
                    self?.currentRouteData = straightLineRoute
                    result(straightLineRoute)
                }
            }
        }
    }
    
    // Convert Mapbox Route to Flutter format (matching native demo data structure)
    private func convertRouteToFlutterFormat(_ route: Route) -> [String: Any] {
        let coordinates = route.coordinates ?? []
        
        // Convert coordinates to geometry (polyline encoding)
        let geometryString = encodePolyline(coordinates: coordinates)
        
        return [
            "geometry": geometryString,
            "distance": route.distance,
            "duration": route.expectedTravelTime,
            "weight": route.expectedTravelTime,
            "waypoints": route.routeOptions.waypoints.map { waypoint in
                [
                    "latitude": waypoint.coordinate.latitude,
                    "longitude": waypoint.coordinate.longitude
                ]
            }
        ]
    }
    #endif
    
    // MARK: - TrackAsia API Route Calculation (Fallback)
    
    private func calculateTrackAsiaRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, profile: String, language: String, completion: @escaping ([String: Any]?) -> Void) {
        
        // TrackAsia API endpoint (similar to Android implementation)
        let baseURL = "https://api.track-asia.com/route/v1"
        let coordinates = "\(origin.longitude),\(origin.latitude);\(destination.longitude),\(destination.latitude)"
        let urlString = "\(baseURL)/\(profile)/\(coordinates)?overview=full&geometries=polyline&language=\(language)"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid TrackAsia URL")
            completion(nil)
            return
        }
        
        print("🔄 Requesting route: \(urlString)")
        
        var request = URLRequest(url: url)
        request.setValue("TrackAsia Flutter Navigation Plugin", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Route request failed: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received from route API")
                    completion(nil)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let routes = json["routes"] as? [[String: Any]],
                       let route = routes.first {
                        
                        let routeData = self?.parseTrackAsiaRouteResponse(route, origin: origin, destination: destination)
                        completion(routeData)
                    } else {
                        print("❌ Invalid route response format")
                        completion(nil)
                    }
                } catch {
                    print("❌ Error parsing route response: \(error)")
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // Parse TrackAsia route response similar to native demo
    private func parseTrackAsiaRouteResponse(_ route: [String: Any], origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> [String: Any] {
        let geometry = route["geometry"] as? String ?? ""
        let distance = route["distance"] as? Double ?? 0.0
        let duration = route["duration"] as? Double ?? 0.0
        let weight = route["weight"] as? Double ?? duration
        
        return [
            "geometry": geometry,
            "distance": distance,
            "duration": duration,
            "weight": weight,
            "waypoints": [
                [
                    "latitude": origin.latitude,
                    "longitude": origin.longitude
                ],
                [
                    "latitude": destination.latitude,
                    "longitude": destination.longitude
                ]
            ]
        ]
    }
    
    // Create straight line route as fallback (matching native demo behavior)
    private func createStraightLineRoute(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> [String: Any] {
        
        // Calculate distance using Haversine formula (like native demo)
        let distance = calculateDistance(from: origin, to: destination)
        let estimatedTime = distance / 13.8 // ~50 km/h average speed
        
        // Create simple polyline geometry
        let coordinates = [origin, destination]
        let geometryString = encodePolyline(coordinates: coordinates)
        
        return [
            "geometry": geometryString,
            "distance": distance,
            "duration": estimatedTime,
            "weight": estimatedTime,
            "waypoints": [
                [
                    "latitude": origin.latitude,
                    "longitude": origin.longitude
                ],
                [
                    "latitude": destination.latitude,
                    "longitude": destination.longitude
                ]
            ]
        ]
    }
    
    // Distance calculation (Haversine formula - from native demo)
    private func calculateDistance(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        let earthRadius = 6371000.0 // Earth radius in meters
        
        let lat1 = start.latitude * .pi / 180
        let lat2 = end.latitude * .pi / 180
        let deltaLat = (end.latitude - start.latitude) * .pi / 180
        let deltaLon = (end.longitude - start.longitude) * .pi / 180
        
        let a = sin(deltaLat/2) * sin(deltaLat/2) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon/2) * sin(deltaLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        
        return earthRadius * c
    }
    
    // MARK: - Navigation Start (Based on Native Demo)
    
    private func startNavigation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("🚗 NavigationMethodHandler: Starting navigation...")
        
        guard let arguments = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Arguments is not a dictionary",
                details: nil
            ))
            return
        }
        
        guard let routeData = currentRouteData else {
            result(FlutterError(
                code: "NO_ROUTE",
                message: "No route available. Please calculate a route first.",
                details: nil
            ))
            return
        }
        
        let options = arguments["options"] as? [String: Any]
        let simulateRoute = options?["simulateRoute"] as? Bool ?? false
        
        // Check if we have a Route object (from MapboxDirections) or need to create one
        #if canImport(MapboxDirections)
        if let route = currentRoute {
            // Use full navigation with Route object (like native demo)
            #if canImport(MapboxNavigation) && canImport(MapboxCoreNavigation)
            startFullNavigation(with: route, simulateRoute: simulateRoute, result: result)
            #else
            startBasicNavigation(with: routeData, options: options, result: result)
            #endif
        } else {
            // Basic navigation without full UI
            startBasicNavigation(with: routeData, options: options, result: result)
        }
        #else
        // Basic navigation without full UI (no MapboxDirections available)
        startBasicNavigation(with: routeData, options: options, result: result)
        #endif
    }
    
    // Full navigation with NavigationViewController (like native demo)
    #if canImport(MapboxNavigation) && canImport(MapboxCoreNavigation) && canImport(MapboxDirections)
    private func startFullNavigation(with route: Route, simulateRoute: Bool, result: @escaping FlutterResult) {
        // Get the root view controller to present navigation
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            result(FlutterError(
                code: "NO_VIEW_CONTROLLER",
                message: "Could not find root view controller",
                details: nil
            ))
            return
        }
        
        // Create NavigationViewController (like native demo)
        let navigationViewController = NavigationViewController(dayStyle: DayStyle(), nightStyle: NightStyle())
        
        if simulateRoute {
            let simulatedLocationManager = SimulatedLocationManager(route: route)
            simulatedLocationManager.speedMultiplier = 2.0
            navigationViewController.startNavigation(with: route, animated: true, locationManager: simulatedLocationManager)
        } else {
            navigationViewController.startNavigation(with: route, animated: true)
        }
        
        // Present navigation view controller
        navigationViewController.modalPresentationStyle = .fullScreen
        rootViewController.present(navigationViewController, animated: true) {
            self.isNavigationActive = true
            print("✅ Full navigation started successfully")
            result(["status": "started"])
        }
    }
    #endif
    
    // Basic navigation tracking without full UI
    private func startBasicNavigation(with routeData: [String: Any], options: [String: Any]?, result: @escaping FlutterResult) {
        // Initialize navigation state
        isNavigationActive = true
        
        // Initialize progress
        let distance = routeData["distance"] as? Double ?? 0.0
        let duration = routeData["duration"] as? Double ?? 0.0
        let simulateRoute = options?["simulateRoute"] as? Bool ?? false
        
        currentProgress = [
            "distanceRemaining": distance,
            "durationRemaining": duration,
            "distanceTraveled": 0.0,
            "fractionTraveled": 0.0,
            "currentStepIndex": 0,
            "currentLegIndex": 0
        ]
        
        print("✅ Basic navigation started")
        result(["status": "started", "mode": "basic"])
    }
    
    // MARK: - Route Drawing (Based on Native Demo MapViewManager)
    
    private func addNavigationRoute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("NavigationMethodHandler: addNavigationRoute called")
        
        guard let arguments = call.arguments as? [String: Any],
              let routeMap = arguments["route"] as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Route data is required",
                details: nil
            ))
            return
        }
        
        let routeId = arguments["routeId"] as? String ?? "route_\(Date().timeIntervalSince1970)"
        let isPrimary = arguments["isPrimary"] as? Bool ?? false
        let style = arguments["style"] as? [String: Any]
        
        // Get the map view
        guard let mapView = getMapView(fromCall: call) else {
            result(FlutterError(
                code: "NO_MAP_VIEW",
                message: "Map view not available",
                details: nil
            ))
            return
        }
        
        // Parse route data and draw on map (like native demo)
        if let geometry = routeMap["geometry"] as? String {
                if let coordinates = decodePolyline(geometry) {
                addPolylineToMap(mapView: mapView, coordinates: coordinates, routeId: routeId, style: style, isPrimary: isPrimary)
                print("🗺️ Route drawn with \(coordinates.count) coordinates")
                }
        } else if let coordinatesData = routeMap["coordinates"] as? [[Double]] {
                // Handle coordinates array format
                let coordinates = coordinatesData.compactMap { coord -> CLLocationCoordinate2D? in
                    guard coord.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                }
                
                if !coordinates.isEmpty {
                addPolylineToMap(mapView: mapView, coordinates: coordinates, routeId: routeId, style: style, isPrimary: isPrimary)
                print("🗺️ Route drawn with \(coordinates.count) coordinates")
            }
        }
        
        result(["routeId": routeId])
    }
    
    // Add route using TRUE NavigationMapView approach (matching showRoutes() exactly)
    private func addPolylineToMap(mapView: MLNMapView, coordinates: [CLLocationCoordinate2D], routeId: String, style: [String: Any]?, isPrimary: Bool) {
        
        guard let mapStyle = mapView.style else {
            print("⚠️ Cannot add polyline: map style is nil")
            return
        }
        
        print("🗺️ Adding route using TRUE NavigationMapView approach...")
        
        // Create route polyline like NavigationMapView
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        
        // TRUE NavigationMapView architecture: separate sources + layers for route + casing
        let routeSourceId = "routeSource-\(routeId)"
        let routeCasingSourceId = "routeCasingSource-\(routeId)" 
        let routeLayerId = "routeLayer-\(routeId)"
        let routeCasingLayerId = "routeLayerCasing-\(routeId)"
        
        // 1. Create route casing source (for border) - like NavigationMapView
        let routeCasingSource = MLNShapeSource(identifier: routeCasingSourceId, shape: polyline, options: [.maximumZoomLevel: 16])
        mapStyle.addSource(routeCasingSource)
        
        // 2. Create main route source - like NavigationMapView  
        let routeSource = MLNShapeSource(identifier: routeSourceId, shape: polyline, options: [.maximumZoomLevel: 16])
        mapStyle.addSource(routeSource)
        
        // 3. Create route casing layer (MUST be below main route) - like NavigationMapView.routeCasingStyleLayer()
        let routeCasingLayer = createRouteCasingStyleLayer(identifier: routeCasingLayerId, source: routeCasingSource, isPrimary: isPrimary)
        
        // 4. Create main route layer (on top) - like NavigationMapView.routeStyleLayer()
        let routeLayer = createRouteStyleLayer(identifier: routeLayerId, source: routeSource, isPrimary: isPrimary)
        
        // 5. Add layers in correct order (casing first, then route) - like NavigationMapView.showRoutes()
        // Insert below symbol layers like NavigationMapView does
        var layerInserted = false
        for layer in mapStyle.layers.reversed() {
            if !(layer is MLNSymbolStyleLayer) {
                mapStyle.insertLayer(routeLayer, below: layer)
                mapStyle.insertLayer(routeCasingLayer, below: routeLayer)
                layerInserted = true
                break
            }
        }
        
        // Fallback: add layers at the end if no suitable layer found
        if !layerInserted {
            mapStyle.addLayer(routeCasingLayer)
            mapStyle.addLayer(routeLayer)
        }
        
        print("✅ Route added using TRUE NavigationMapView approach: route + casing layers with dynamic width")
        
        // Store for later management
        routePolylines[routeId] = polyline
        if let style = style {
            routeStyles[routeId] = style
        }
        
        print("✅ Polyline added successfully with ID: \(routeId)")
    }
    
    // MARK: - NavigationMapView Style Layer Creation (Exact Match)
    
    // Create route style layer exactly like NavigationMapView.routeStyleLayer()
    private func createRouteStyleLayer(identifier: String, source: MLNSource, isPrimary: Bool) -> MLNLineStyleLayer {
        let layer = MLNLineStyleLayer(identifier: identifier, source: source)
        
        // TRUE NavigationMapView dynamic width by zoom level (from Constants.swift)
        let nativeRouteLineWidthByZoomLevel: [NSNumber: NSNumber] = [
            10: 8,   // Zoom 10 = 8px width
            13: 9,   // Zoom 13 = 9px width  
            16: 11,  // Zoom 16 = 11px width
            19: 22,  // Zoom 19 = 22px width
            22: 28   // Zoom 22 = 28px width
        ]
        
        layer.lineWidth = NSExpression(forMLNInterpolating: .zoomLevelVariable,
                                      curveType: .linear,
                                      parameters: nil,
                                      stops: NSExpression(forConstantValue: nativeRouteLineWidthByZoomLevel))
        
        // TRUE NavigationMapView colors (from ConfigManager.swift)
        let routeLineColor = UIColor(red: 0, green: 0.4980392157, blue: 0.9098039216, alpha: 1) // #0080E8
        layer.lineColor = NSExpression(forConstantValue: routeLineColor)
        layer.lineOpacity = NSExpression(forConstantValue: 1.0) // routeLineAlpha = 1
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        
        return layer
    }
    
    // Create route casing style layer exactly like NavigationMapView.routeCasingStyleLayer()
    private func createRouteCasingStyleLayer(identifier: String, source: MLNSource, isPrimary: Bool) -> MLNLineStyleLayer {
        let layer = MLNLineStyleLayer(identifier: identifier, source: source)
        
        // TRUE NavigationMapView casing width: 1.5x multiplier (from NavigationMapView.swift line 964)
        let nativeRouteLineWidthByZoomLevel: [NSNumber: NSNumber] = [
            10: 8,   // Zoom 10 = 8px width
            13: 9,   // Zoom 13 = 9px width  
            16: 11,  // Zoom 16 = 11px width
            19: 22,  // Zoom 19 = 22px width
            22: 28   // Zoom 22 = 28px width
        ]
        
        // Apply 1.5x multiplier for casing (exactly like NavigationMapView)
        let casingWidthByZoomLevel = nativeRouteLineWidthByZoomLevel.mapValues { NSNumber(value: $0.doubleValue * 1.5) }
        
        layer.lineWidth = NSExpression(forMLNInterpolating: .zoomLevelVariable,
                                      curveType: .linear,
                                      parameters: nil,
                                      stops: NSExpression(forConstantValue: casingWidthByZoomLevel))
        
        // TRUE NavigationMapView casing colors (from ConfigManager.swift)
        let routeLineCasingColor = UIColor(red: 0, green: 0.3450980392, blue: 0.6352941176, alpha: 1) // #0058A2
        layer.lineColor = NSExpression(forConstantValue: routeLineCasingColor)
        layer.lineOpacity = NSExpression(forConstantValue: 1.0) // routeLineCasingAlpha = 1
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        
        return layer
    }
    
    // MARK: - Utility Methods
    
    // Parse color from hex string using existing extension
    private func parseColor(_ colorString: String?) -> UIColor? {
        guard let colorString = colorString else { return nil }
        return UIColor(hexString: colorString)
    }
    
    // Simple polyline encoding (basic implementation)
    private func encodePolyline(coordinates: [CLLocationCoordinate2D]) -> String {
        // For now, return simple coordinate string
        // In production, implement proper polyline encoding algorithm
        return coordinates.map { "\($0.latitude),\($0.longitude)" }.joined(separator: ";")
    }
    
    // Enhanced polyline decoding with multiple format support
    private func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D]? {
        // Check if it's a simple coordinate string first
        if encoded.contains(";") && encoded.contains(",") {
            let pairs = encoded.components(separatedBy: ";")
            return pairs.compactMap { pair in
                let coords = pair.components(separatedBy: ",")
                if coords.count >= 2,
                   let lat = Double(coords[0]),
                   let lng = Double(coords[1]) {
                    return CLLocationCoordinate2D(latitude: lat, longitude: lng)
                }
                return nil
            }
        }
        
        // Try Google Polyline Algorithm 5 (standard)
        if let coords = decodeGooglePolyline(encoded, precision: 5) {
            return coords
        }
        
        // Try Google Polyline Algorithm 6 (TrackAsia format)
        if let coords = decodeGooglePolyline(encoded, precision: 6) {
            return coords
        }
        
        print("⚠️ Unable to decode polyline: \(encoded.prefix(50))...")
        return nil
    }
    
    // Google Polyline Algorithm implementation
    private func decodeGooglePolyline(_ encoded: String, precision: Int) -> [CLLocationCoordinate2D]? {
        let factor = pow(10.0, Double(precision))
        var coordinates: [CLLocationCoordinate2D] = []
        var lat = 0, lng = 0
        var index = encoded.startIndex
        
        while index < encoded.endIndex {
            var shift = 0, result = 0
            
            // Decode latitude
            repeat {
                if index >= encoded.endIndex { return nil }
                let char = encoded[index]
                index = encoded.index(after: index)
                
                guard let ascii = char.asciiValue else { return nil }
                let value = Int(ascii) - 63
                result |= (value & 0x1f) << shift
                shift += 5
            } while result & 0x20 != 0
            
            let deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lat += deltaLat
            
            shift = 0
            result = 0
            
            // Decode longitude
            repeat {
                if index >= encoded.endIndex { return nil }
                let char = encoded[index]
                index = encoded.index(after: index)
                
                guard let ascii = char.asciiValue else { return nil }
                let value = Int(ascii) - 63
                result |= (value & 0x1f) << shift
                shift += 5
            } while result & 0x20 != 0
            
            let deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lng += deltaLng
            
            let coordinate = CLLocationCoordinate2D(
                latitude: Double(lat) / factor,
                longitude: Double(lng) / factor
            )
            coordinates.append(coordinate)
        }
        
        return coordinates.isEmpty ? nil : coordinates
    }
}

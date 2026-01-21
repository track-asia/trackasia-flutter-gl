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

// MapboxDirections is declared as CocoaPods dependency in podspec
// Using direct import since it should always be available
import MapboxDirections
import Turf

// NOTE: NavigationViewController, DayStyle, NightStyle, SimulatedLocationManager
// are defined in ios/Navigation/UI/ folder and are part of the same target,
// so they don't need explicit imports

/**
 * Handles navigation-related method calls from Flutter
 * Implements iOS native demo functionality for route calculation and navigation
 */
class NavigationMethodHandler: NSObject {
    private let registrar: FlutterPluginRegistrar
    
    // Navigation state - STATIC to persist across instances
    private var isNavigationActive = false
    private static var currentRouteDataStatic: [String: Any]?
    private var currentProgress: [String: Any]?
    
    // Map controllers registry to access MapView (from TrackAsiaMapController)
    private static var mapControllers: [Int: TrackAsiaMapController] = [:]
    
    // Route management - STATIC to persist across instances
    // This ensures currentRoute set in calculateRoute is available in startNavigation
    private static var currentRouteStatic: Route?
    private var waypoints: [CLLocationCoordinate2D] = []
    private var routePolylines: [String: MLNPolyline] = [:]
    private var routeStyles: [String: [String: Any]] = [:]
    
    // Accessors for static route data
    private var currentRoute: Route? {
        get { NavigationMethodHandler.currentRouteStatic }
        set { NavigationMethodHandler.currentRouteStatic = newValue }
    }
    
    private var currentRouteData: [String: Any]? {
        get { NavigationMethodHandler.currentRouteDataStatic }
        set { NavigationMethodHandler.currentRouteDataStatic = newValue }
    }
    
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
        NSLog("🔴 NavigationMethodHandler: Handling method: %@", call.method)
        switch call.method {
        case "navigation#calculateRoute":
            calculateRoute(call, result: result)
        case "navigation#start":
            startNavigation(call, result: result)
        case "navigation#stop":
            stopNavigation(result: result)
        case "navigation#pause":
            pauseNavigation(result: result)
        case "navigation#resume":
            resumeNavigation(result: result)
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
        
        print("🔄 ===== COORDINATE DEBUG =====")
        print("   Input waypoints from Flutter: \(waypoints)")
        for (i, coord) in coordinates.enumerated() {
            print("   Parsed coord[\(i)]: lat=\(coord.latitude), lng=\(coord.longitude)")
            let isVietnam = coord.latitude > 8 && coord.latitude < 23 && coord.longitude > 102 && coord.longitude < 110
            print("   In Vietnam range: \(isVietnam)")
        }
        print("🔄 Calculating route from \(coordinates[0]) to \(coordinates[1])")
        
        // Use TrackAsia API and create Route object manually for full navigation UI
        calculateTrackAsiaRouteWithRouteObject(
            from: coordinates[0], 
            to: coordinates[1], 
            profile: profile, 
            language: language, 
            flutterResult: result
        )
    }

    
    // MARK: - Route Calculation with MapboxDirections (Native Demo Style)
    
    // MapboxDirections is always available
    private func calculateRouteWithMapboxDirections(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, profile: String, language: String, flutterResult: @escaping FlutterResult) {
        
        let originWaypoint = Waypoint(coordinate: origin)
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        // Use RouteOptions instead of NavigationRouteOptions (which requires MapboxCoreNavigation)
        let options = RouteOptions(waypoints: [originWaypoint, destinationWaypoint])
        options.includesSteps = true
        options.routeShapeResolution = .full
        
        // Set profile based on input
        switch profile.lowercased() {
        case "walking":
            options.profileIdentifier = .walking
        case "cycling":
            options.profileIdentifier = .cycling
        default:
            options.profileIdentifier = .automobile
        }
        
        print("🔄 Using MapboxDirections with TrackAsia host for route calculation...")
        
        // Create custom Directions instance with TrackAsia API host
        // TrackAsia API doesn't require a real token, but MapboxDirections requires non-empty token
        let trackAsiaHost = URL(string: "https://api.track-asia.com")!
        let credentials = Credentials(accessToken: "trackasia_public", host: trackAsiaHost)
        let directions = Directions(credentials: credentials)
        
        // MapboxDirections 2.14+ uses Result type callback
        directions.calculate(options) { [weak self] (session, routeResult) in
            DispatchQueue.main.async {
                switch routeResult {
                case .failure(let error):
                    print("❌ MapboxDirections error: \(error.localizedDescription)")
                    // Fallback to straight line like native demo
                    let straightLineRoute = self?.createStraightLineRoute(from: origin, to: destination)
                    self?.currentRouteData = straightLineRoute
                    flutterResult(straightLineRoute)
                    
                case .success(let response):
                    if let route = response.routes?.first {
                        print("✅ Route calculated via MapboxDirections: \(String(format: "%.2f", route.distance / 1000)) km")
                        
                        // Store route object for navigation
                        self?.currentRoute = route
                        
                        // Convert to Flutter format
                        let routeData = self?.convertRouteToFlutterFormat(route, waypoints: [origin, destination])
                        self?.currentRouteData = routeData
                        flutterResult(routeData)
                    } else {
                        print("⚠️ No routes returned, using straight line")
                        let straightLineRoute = self?.createStraightLineRoute(from: origin, to: destination)
                        self?.currentRouteData = straightLineRoute
                        flutterResult(straightLineRoute)
                    }
                }
            }
        }
    }
    
    // Convert Mapbox Route to Flutter format (matching native demo data structure)
    private func convertRouteToFlutterFormat(_ route: Route, waypoints: [CLLocationCoordinate2D]) -> [String: Any] {
        // Get coordinates from route shape
        var coordinates: [CLLocationCoordinate2D] = []
        if let shape = route.shape {
            coordinates = shape.coordinates
        }
        
        // Convert coordinates to geometry (polyline encoding)
        let geometryString = encodePolyline(coordinates: coordinates)
        
        return [
            "geometry": geometryString,
            "distance": route.distance,
            "duration": route.expectedTravelTime,
            "weight": route.expectedTravelTime,
            "waypoints": waypoints.map { coord in
                [
                    "latitude": coord.latitude,
                    "longitude": coord.longitude
                ]
            }
        ]
    }
    
    // MARK: - TrackAsia API Route Calculation with Route Object Creation
    
    /// Calls TrackAsia routing API and creates a Route object for NavigationViewController
    private func calculateTrackAsiaRouteWithRouteObject(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, profile: String, language: String, flutterResult: @escaping FlutterResult) {
        
        // TrackAsia API endpoint - using maps.track-asia.com (correct host)
        // TrackAsia API uses 'car/walk/bike' profiles (not 'driving/walking/cycling')
        let profilePath = profile.lowercased() == "walking" ? "walk" : (profile.lowercased() == "cycling" ? "bike" : "car")
        let baseURL = "https://maps.track-asia.com/route/v1"
        let coordinates = "\(origin.longitude),\(origin.latitude);\(destination.longitude),\(destination.latitude)"
        // TrackAsia API key (same as used in U-Map Flutter app - Constants.apiKeyVN)
        let apiKey = "c83d316e47617682005753cf8d2528b98e"
        // IMPORTANT: URL must end with .json before query params (matching Flutter api_service.dart format)
        // CRITICAL: Use polyline6 (precision 6) to match Flutter app - NOT polyline (precision 5)
        let urlString = "\(baseURL)/\(profilePath)/\(coordinates).json?key=\(apiKey)&overview=full&geometries=polyline6&steps=true"
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid TrackAsia URL")
            flutterResult(FlutterError(code: "INVALID_URL", message: "Invalid TrackAsia routing URL", details: nil))
            return
        }
        
        print("🔄 Requesting route from TrackAsia: \(urlString)")
        
        var request = URLRequest(url: url)
        request.setValue("TrackAsia Flutter Navigation Plugin", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 30
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                // Log HTTP response details
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 TrackAsia API HTTP Status: \(httpResponse.statusCode)")
                }
                
                if let error = error {
                    print("❌ TrackAsia route request failed: \(error.localizedDescription)")
                    flutterResult(FlutterError(code: "NETWORK_ERROR", message: error.localizedDescription, details: nil))
                    return
                }
                
                guard let data = data else {
                    print("❌ No data received from TrackAsia API")
                    flutterResult(FlutterError(code: "NO_DATA", message: "No data received from routing API", details: nil))
                    return
                }
                
                // Log raw response for debugging
                if let rawString = String(data: data, encoding: .utf8) {
                    print("📦 TrackAsia API Raw Response (first 500 chars):")
                    print(String(rawString.prefix(500)))
                }
                
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                        print("❌ Failed to parse JSON response")
                        print("📦 Raw data: \(String(data: data, encoding: .utf8) ?? "nil")")
                        flutterResult(FlutterError(code: "INVALID_JSON", message: "Failed to parse JSON", details: nil))
                        return
                    }
                    
                    // Log JSON structure
                    print("📋 TrackAsia API Response keys: \(json.keys.joined(separator: ", "))")
                    
                    // Check for error message in response
                    if let message = json["message"] as? String {
                        print("❌ TrackAsia API Error: \(message)")
                        flutterResult(FlutterError(code: "API_ERROR", message: message, details: nil))
                        return
                    }
                    
                    // Check for code other than 'Ok'
                    if let code = json["code"] as? String, code != "Ok" {
                        print("❌ TrackAsia API returned code: \(code)")
                        let message = json["message"] as? String ?? "Unknown error"
                        flutterResult(FlutterError(code: "API_ERROR", message: "Code: \(code), Message: \(message)", details: nil))
                        return
                    }
                    
                    guard let routes = json["routes"] as? [[String: Any]],
                          let routeJson = routes.first else {
                        print("❌ Invalid TrackAsia route response format - no routes array")
                        print("📋 Available keys: \(json.keys.joined(separator: ", "))")
                        flutterResult(FlutterError(code: "INVALID_RESPONSE", message: "Invalid route response format", details: nil))
                        return
                    }
                    
                    // Parse route data
                    guard let geometryString = routeJson["geometry"] as? String,
                          let distance = routeJson["distance"] as? Double,
                          let duration = routeJson["duration"] as? Double else {
                        print("❌ Missing required route fields")
                        flutterResult(FlutterError(code: "MISSING_FIELDS", message: "Missing required route fields", details: nil))
                        return
                    }
                    
                    print("✅ TrackAsia route received: \(String(format: "%.2f", distance / 1000)) km, \(String(format: "%.1f", duration / 60)) min")
                    
                    // Create Route object from OSRM response
                    if let route = self?.createRouteFromOSRMResponse(
                        geometry: geometryString,
                        distance: distance,
                        duration: duration,
                        legs: routeJson["legs"] as? [[String: Any]],
                        origin: origin,
                        destination: destination
                    ) {
                        print("✅ Route object created successfully")
                        print("   Route legs: \(route.legs.count)")
                        print("   Route distance: \(route.distance)")
                        
                        // Store route for navigation - use strong self
                        self?.currentRoute = route
                        
                        // Confirm Route was stored
                        if self?.currentRoute != nil {
                            print("✅ currentRoute successfully stored!")
                        } else {
                            print("❌ currentRoute is STILL nil after assignment!")
                        }
                        
                        // Convert to Flutter format
                        let routeData = self?.convertRouteToFlutterFormat(route, waypoints: [origin, destination])
                        self?.currentRouteData = routeData
                        flutterResult(routeData)
                    } else {
                        print("❌ Failed to create Route object - createRouteFromOSRMResponse returned nil")
                        print("   Attempting to create simple fallback Route from geometry...")
                        
                        // Try to create a simple Route directly from geometry
                        if let strongSelf = self,
                           let coords = strongSelf.decodePolyline(geometryString),
                           !coords.isEmpty {
                            print("   ✅ Fallback: decoded \(coords.count) coords from geometry")
                            
                            // Create minimal Route object for navigation
                            // Use actual geometry endpoints so markers display correctly
                            let shape = LineString(coords)
                            let actualOrigin = coords.first ?? origin
                            let actualDest = coords.last ?? destination
                            let originWpt = Waypoint(coordinate: actualOrigin)
                            let destWpt = Waypoint(coordinate: actualDest)
                            
                            // Create a simple RouteLeg with the full shape
                            let leg = RouteLeg(
                                steps: [],
                                name: "Route",
                                distance: distance,
                                expectedTravelTime: duration,
                                typicalTravelTime: nil,
                                profileIdentifier: .automobile
                            )
                            leg.source = originWpt
                            leg.destination = destWpt
                            
                            let fallbackRoute = Route(
                                legs: [leg],
                                shape: shape,
                                distance: distance,
                                expectedTravelTime: duration
                            )
                            
                            // CRITICAL: Store the fallback route!
                            strongSelf.currentRoute = fallbackRoute
                            print("   ✅ Fallback Route created and stored!")
                            
                            let routeData = strongSelf.convertRouteToFlutterFormat(fallbackRoute, waypoints: [origin, destination])
                            strongSelf.currentRouteData = routeData
                            flutterResult(routeData)
                        } else {
                            print("   ❌ Fallback failed - no self or cannot decode geometry")
                            // Last resort: dictionary format (will trigger startBasicNavigation)
                            let routeData = self?.parseTrackAsiaRouteResponse(routeJson, origin: origin, destination: destination)
                            self?.currentRouteData = routeData
                            flutterResult(routeData)
                        }
                    }
                    
                } catch {
                    print("❌ Error parsing TrackAsia route response: \(error)")
                    flutterResult(FlutterError(code: "PARSE_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }.resume()
    }
    
    /// Creates a Route object from OSRM-format response
    private func createRouteFromOSRMResponse(
        geometry: String,
        distance: Double,
        duration: Double,
        legs: [[String: Any]]?,
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) -> Route? {
        // Decode polyline to coordinates
        print("🔄 createRouteFromOSRMResponse: Decoding geometry (length: \(geometry.count) chars)")
        print("   Geometry prefix: \(String(geometry.prefix(50)))...")
        
        guard let coordinates = decodePolyline(geometry), !coordinates.isEmpty else {
            print("❌ Failed to decode route geometry")
            print("   decodePolyline returned nil or empty array")
            return nil
        }
        
        print("✅ Decoded \(coordinates.count) coordinates from geometry")
        if let first = coordinates.first, let last = coordinates.last {
            print("   First coord: lat=\(first.latitude), lng=\(first.longitude)")
            print("   Last coord: lat=\(last.latitude), lng=\(last.longitude)")
            // Vietnam should be: lat ~8-23, lng ~102-110
            let isVietnamRange = first.latitude > 8 && first.latitude < 23 && first.longitude > 102 && first.longitude < 110
            print("   In Vietnam range: \(isVietnamRange)")
        }
        
        // Create LineString shape
        let shape = LineString(coordinates)
        
        // Create Waypoint objects using actual route geometry endpoints
        // This ensures markers display at the correct snapped road positions
        let actualOrigin = coordinates.first ?? origin
        let actualDestination = coordinates.last ?? destination
        let originWaypoint = Waypoint(coordinate: actualOrigin)
        let destinationWaypoint = Waypoint(coordinate: actualDestination)
        
        // Create RouteLeg
        let routeLegs = createRouteLegs(
            from: legs,
            origin: originWaypoint,
            destination: destinationWaypoint,
            distance: distance,
            duration: duration,
            shape: shape
        )
        
        // Create Route
        let route = Route(
            legs: routeLegs,
            shape: shape,
            distance: distance,
            expectedTravelTime: duration
        )
        
        return route
    }
    
    /// Creates RouteLeg array from OSRM legs data
    private func createRouteLegs(
        from legsData: [[String: Any]]?,
        origin: Waypoint,
        destination: Waypoint,
        distance: Double,
        duration: Double,
        shape: LineString
    ) -> [RouteLeg] {
        var routeLegs: [RouteLeg] = []
        
        if let legsData = legsData, !legsData.isEmpty {
            for (index, legData) in legsData.enumerated() {
                let legDistance = legData["distance"] as? Double ?? distance
                let legDuration = legData["duration"] as? Double ?? duration
                
                // Create steps from leg steps
                let stepsData = legData["steps"] as? [[String: Any]] ?? []
                let steps = createRouteSteps(from: stepsData)
                
                let leg = RouteLeg(
                    steps: steps,
                    name: legData["summary"] as? String ?? "",
                    distance: legDistance,
                    expectedTravelTime: legDuration,
                    profileIdentifier: .automobile
                )
                
                // Set source and destination as properties
                if index == 0 {
                    leg.source = origin
                }
                if index == legsData.count - 1 {
                    leg.destination = destination
                }
                
                routeLegs.append(leg)
            }
        } else {
            // Create single leg if no legs data
            let leg = RouteLeg(
                steps: [],
                name: "",
                distance: distance,
                expectedTravelTime: duration,
                profileIdentifier: .automobile
            )
            leg.source = origin
            leg.destination = destination
            routeLegs.append(leg)
        }
        
        return routeLegs
    }
    
    /// Creates RouteStep array from OSRM steps data
    private func createRouteSteps(from stepsData: [[String: Any]]) -> [RouteStep] {
        var steps: [RouteStep] = []
        
        for (index, stepData) in stepsData.enumerated() {
            let stepDistance = stepData["distance"] as? Double ?? 0
            let stepDuration = stepData["duration"] as? Double ?? 0
            let stepName = stepData["name"] as? String ?? ""
            
            // Get maneuver info
            let maneuverData = stepData["maneuver"] as? [String: Any] ?? [:]
            let maneuverInstruction = maneuverData["instruction"] as? String
            let maneuverType = maneuverData["type"] as? String ?? "turn"
            let maneuverModifier = maneuverData["modifier"] as? String
            
            // Parse location from maneuver
            var maneuverLoc = CLLocationCoordinate2D(latitude: 0, longitude: 0)
            if let locationArray = maneuverData["location"] as? [Double], locationArray.count >= 2 {
                maneuverLoc = CLLocationCoordinate2D(latitude: locationArray[1], longitude: locationArray[0])
            }
            
            // Get step geometry - CRITICAL for navigation location tracking
            var stepShape: LineString? = nil
            if let stepGeometry = stepData["geometry"] as? String,
               let coords = decodePolyline(stepGeometry),
               !coords.isEmpty {
                stepShape = LineString(coords)
                print("   Step \(index): Got geometry with \(coords.count) coordinates")
            } else {
                // FALLBACK: Create shape from maneuver location when geometry is missing
                // This prevents crashes in RouteProgress.nearbyCoordinates and RouteController
                if maneuverLoc.latitude != 0 && maneuverLoc.longitude != 0 {
                    // Get next step's maneuver location if available
                    var nextCoord = maneuverLoc
                    if index + 1 < stepsData.count,
                       let nextStepData = stepsData[index + 1]["maneuver"] as? [String: Any],
                       let nextLocArray = nextStepData["location"] as? [Double],
                       nextLocArray.count >= 2 {
                        nextCoord = CLLocationCoordinate2D(latitude: nextLocArray[1], longitude: nextLocArray[0])
                    }
                    stepShape = LineString([maneuverLoc, nextCoord])
                    print("   Step \(index): Created fallback geometry from maneuver locations")
                }
            }
            
            // Create maneuver type and direction
            let (type, direction) = parseManeuver(type: maneuverType, modifier: maneuverModifier)
            
            let step = RouteStep(
                transportType: .automobile,
                maneuverLocation: maneuverLoc,
                maneuverType: type,
                instructions: maneuverInstruction ?? "Continue on \(stepName)",
                drivingSide: .right,
                distance: stepDistance,
                expectedTravelTime: stepDuration
            )
            
            // CRITICAL: Set step shape for coordinates - required by RouteProgress.nearbyCoordinates
            step.shape = stepShape
            
            steps.append(step)
        }
        
        return steps
    }
    
    /// Parse OSRM maneuver type and modifier to MapboxDirections types
    private func parseManeuver(type: String, modifier: String?) -> (ManeuverType, ManeuverDirection) {
        let mt: ManeuverType
        switch type {
        case "depart": mt = .depart
        case "arrive": mt = .arrive
        case "turn": mt = .turn
        case "merge": mt = .merge
        case "off ramp": mt = .takeOffRamp
        case "on ramp": mt = .takeOnRamp
        case "roundabout": mt = .takeRoundabout
        case "rotary": mt = .takeRotary
        case "continue": mt = .continue
        case "fork": mt = .turn  // fork not available, use turn
        case "new name": mt = .turn  // notification not available, use turn
        default: mt = .turn
        }
        
        let md: ManeuverDirection
        switch modifier {
        case "left": md = .left
        case "right": md = .right
        case "slight left": md = .slightLeft
        case "slight right": md = .slightRight
        case "sharp left": md = .sharpLeft
        case "sharp right": md = .sharpRight
        case "uturn": md = .uTurn
        case "straight": md = .straightAhead
        default: md = .straightAhead
        }
        
        return (mt, md)
    }
    
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
        NSLog("��🚗 NavigationMethodHandler: Starting navigation...")
        
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
        
        // Navigation modules are now integrated into trackasia_gl pod
        // Always use full navigation when we have a Route object
        NSLog("��🚗 NavigationMethodHandler: Checking currentRoute...")
        if let route = currentRoute {
            NSLog("🔴✅ NavigationMethodHandler: currentRoute available - starting full navigation")
            NSLog("🔴   Route distance: %f meters", route.distance)
            startFullNavigation(with: route, simulateRoute: simulateRoute, result: result)
        } else {
            print("⚠️ NavigationMethodHandler: currentRoute is NIL - falling back to basic navigation")
            print("   routeData keys: \(routeData.keys.joined(separator: ", "))")
            // Basic navigation without full UI
            startBasicNavigation(with: routeData, options: options, result: result)
        }
    }
    
    // Full navigation with NavigationViewController (like native demo)
    // Navigation modules are now integrated into trackasia_gl pod
    // MapboxDirections is always available
    private func startFullNavigation(with route: Route, simulateRoute: Bool, result: @escaping FlutterResult) {
        print("🚗 startFullNavigation called with route distance: \(route.distance)")
        
        // Get the root view controller to present navigation
        var rootViewController: UIViewController?
        
        if #available(iOS 13.0, *) {
            // iOS 13+ uses window scenes
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                rootViewController = windowScene.windows.first?.rootViewController
            }
        }
        
        // Fallback for older iOS versions or if scene approach failed
        if rootViewController == nil {
            rootViewController = UIApplication.shared.windows.first?.rootViewController
        }
        
        guard let rootVC = rootViewController else {
            print("❌ Could not find root view controller")
            result(FlutterError(
                code: "NO_VIEW_CONTROLLER",
                message: "Could not find root view controller",
                details: nil
            ))
            return
        }
        
        presentNavigationController(with: route, simulateRoute: simulateRoute, on: rootVC, result: result)
    }
    
    private func presentNavigationController(with route: Route, simulateRoute: Bool, on rootViewController: UIViewController, result: @escaping FlutterResult) {
        print("🚗 Presenting NavigationViewController...")
        
        // Get the map style URL from the registered Flutter map controller
        // This ensures navigation uses the same map style as the main app
        NSLog("🔴 mapControllers count: %d", Self.mapControllers.count)
        let mapStyleURL: URL
        if let firstController = Self.mapControllers.values.first,
           let styleURL = firstController.mapView.styleURL {
            mapStyleURL = styleURL
            NSLog("🔴 Using map style URL from Flutter: %@", mapStyleURL.absoluteString)
        } else {
            // Fallback to TrackAsia VN streets style v2 (matching U-Map Constants.urlStyleStreetsVN)
            mapStyleURL = URL(string: "https://maps.track-asia.com/styles/v2/streets.json?key=c83d316e47617682005753cf8d2528b98e")!
            NSLog("🔴 Using fallback TrackAsia VN style URL")
        }
        
        // Create NavigationViewController with the correct map style
        let navigationViewController = NavigationViewController(dayStyle: DayStyle(mapStyleURL: mapStyleURL), nightStyle: NightStyle(mapStyleURL: mapStyleURL))
        
        if simulateRoute {
            print("   Using simulated location")
            let simulatedLocationManager = SimulatedLocationManager(route: route)
            simulatedLocationManager.speedMultiplier = 2.0
            navigationViewController.startNavigation(with: route, animated: true, locationManager: simulatedLocationManager)
        } else {
            print("   Using real GPS location")
            navigationViewController.startNavigation(with: route, animated: true)
        }
        
        // Present navigation view controller
        navigationViewController.modalPresentationStyle = .fullScreen
        rootViewController.present(navigationViewController, animated: true) {
            self.isNavigationActive = true
            print("✅ Full navigation started successfully - NavigationViewController presented")
            result(["status": "started"])
        }
    }
    
    // Basic navigation tracking without full UI
    private func startBasicNavigation(with routeData: [String: Any], options: [String: Any]?, result: @escaping FlutterResult) {
        print("🚗 Starting basic navigation with route drawing...")
        
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
        
        // Draw route on map
        if let geometry = routeData["geometry"] as? String,
           let waypoints = routeData["waypoints"] as? [[String: Any]],
           waypoints.count >= 2 {
            
            // Draw route polyline on all registered map controllers
            for (_, controller) in Self.mapControllers {
                drawRouteOnMap(geometry: geometry, mapView: controller.mapView)
            }
            
            // Get origin and destination coordinates
            if let origin = waypoints.first,
               let destination = waypoints.last,
               let originLat = origin["latitude"] as? Double,
               let originLng = origin["longitude"] as? Double,
               let destLat = destination["latitude"] as? Double,
               let destLng = destination["longitude"] as? Double {
                
                // Open external navigation app for turn-by-turn
                let destCoord = CLLocationCoordinate2D(latitude: destLat, longitude: destLng)
                openExternalNavigation(to: destCoord)
            }
        }
        
        print("✅ Basic navigation started with route displayed")
        result(["status": "started", "mode": "basic"])
    }
    
    // Draw route polyline on map
    private func drawRouteOnMap(geometry: String, mapView: MLNMapView) {
        // Decode polyline geometry
        guard let coordinates = decodePolyline(geometry), coordinates.count > 1 else {
            print("⚠️ Failed to decode polyline or no coordinates")
            return
        }
        
        // Create polyline annotation
        var coordsArray = coordinates
        let polyline = MLNPolyline(coordinates: &coordsArray, count: UInt(coordinates.count))
        
        // Store for later removal
        let routeId = "nav_route_\(Date().timeIntervalSince1970)"
        routePolylines[routeId] = polyline
        
        // Add to map
        mapView.addAnnotation(polyline)
        
        // Fit camera to show entire route
        if let first = coordinates.first, let last = coordinates.last {
            let bounds = MLNCoordinateBounds(sw: first, ne: last)
            let camera = mapView.cameraThatFitsCoordinateBounds(bounds, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 100, right: 50))
            mapView.setCamera(camera, animated: true)
        }
        
        print("✅ Route drawn on map with \(coordinates.count) points")
    }
    
    // Open Apple Maps or Google Maps for navigation
    private func openExternalNavigation(to destination: CLLocationCoordinate2D) {
        let appleMapsURL = URL(string: "http://maps.apple.com/?daddr=\(destination.latitude),\(destination.longitude)&dirflg=d")!
        let googleMapsURL = URL(string: "comgooglemaps://?daddr=\(destination.latitude),\(destination.longitude)&directionsmode=driving")!
        
        DispatchQueue.main.async {
            if UIApplication.shared.canOpenURL(googleMapsURL) {
                UIApplication.shared.open(googleMapsURL, options: [:], completionHandler: nil)
                print("🗺️ Opened Google Maps for navigation")
            } else {
                UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
                print("🗺️ Opened Apple Maps for navigation")
            }
        }
    }
    
    // MARK: - Navigation Control Methods
    
    private func stopNavigation(result: @escaping FlutterResult) {
        print("🛑 Stopping navigation...")
        
        // Reset navigation state
        isNavigationActive = false
        currentProgress = nil
        currentRouteData = nil
        
        currentRoute = nil
        
        // Clear route from map if we have map controller
        for (_, controller) in Self.mapControllers {
            let mapView = controller.mapView
            // Remove route polylines
            for (_, polyline) in routePolylines {
                mapView.removeAnnotation(polyline)
            }
            routePolylines.removeAll()
            routeStyles.removeAll()
        }
        
        print("✅ Navigation stopped successfully")
        result(["status": "stopped"])
    }
    
    private func pauseNavigation(result: @escaping FlutterResult) {
        print("⏸️ Pausing navigation...")
        // Navigation pause logic
        result(["status": "paused"])
    }
    
    private func resumeNavigation(result: @escaping FlutterResult) {
        print("▶️ Resuming navigation...")
        // Navigation resume logic
        result(["status": "resumed"])
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
        
        // Try Google Polyline Algorithm 6 first (TrackAsia/Mapbox format)
        if let coords = decodeGooglePolyline(encoded, precision: 6), !coords.isEmpty {
            // Validate: coordinates should be in valid lat/lng range
            if let first = coords.first, 
               first.latitude >= -90 && first.latitude <= 90 &&
               first.longitude >= -180 && first.longitude <= 180 {
                print("   ✅ Decoded with precision 6: \(coords.count) coords")
                print("   ✅ P6 First coord: lat=\(first.latitude), lng=\(first.longitude)")
                if let last = coords.last {
                    print("   ✅ P6 Last coord: lat=\(last.latitude), lng=\(last.longitude)")
                }
                return coords
            }
        }
        
        // Try Google Polyline Algorithm 5 (OSRM standard)
        if let coords = decodeGooglePolyline(encoded, precision: 5), !coords.isEmpty {
            if let first = coords.first,
               first.latitude >= -90 && first.latitude <= 90 &&
               first.longitude >= -180 && first.longitude <= 180 {
                print("   ✅ Decoded with precision 5: \(coords.count) coords")
                return coords
            }
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

import Flutter
import Foundation
import TrackAsia
import UIKit
import TrackAsiaNavigation
import TrackAsiaDirections
import CoreLocation

/**
 * Handles navigation-related method calls from Flutter.
 */
class NavigationMethodHandler: NSObject {
    private let methodChannel: FlutterMethodChannel
    private let registrar: FlutterPluginRegistrar
    private let directions: Directions
    
    // Navigation state
    private var isNavigationActive = false
    private var currentRoute: Route?
    private var currentProgress: [String: Any]?
    private var navigationViewController: NavigationViewController?
    private var routeController: RouteController?
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        // Remove separate method channel - navigation methods will be handled through main channel
        self.methodChannel = FlutterMethodChannel(
            name: "plugins.flutter.io/trackasia_gl_navigation", 
            binaryMessenger: registrar.messenger()
        )
        
        // Initialize TrackAsia Directions
        self.directions = Directions.shared
        
        super.init()
        
        // Don't set method call handler here - will be handled by main plugin
    }
    
    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "navigation#calculateRoute":
            calculateRoute(call, result: result)
        case "navigation#start":
            startNavigation(call, result: result)
        case "navigation#stop":
            stopNavigation(call, result: result)
        case "navigation#pause":
            pauseNavigation(call, result: result)
        case "navigation#resume":
            resumeNavigation(call, result: result)
        case "navigation#isActive":
            result(isNavigationActive)
        case "navigation#getProgress":
            result(currentProgress)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func calculateRoute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let waypoints = arguments["waypoints"] as? [[Double]]
        else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid arguments for calculateRoute",
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
        
        // Convert waypoints to CLLocationCoordinate2D
        let coordinates = waypoints.compactMap { waypoint -> CLLocationCoordinate2D? in
            guard waypoint.count >= 2 else { return nil }
            return CLLocationCoordinate2D(latitude: waypoint[0], longitude: waypoint[1])
        }
        
        // Create route options
        let options = RouteOptions(coordinates: coordinates)
        options.includesSteps = true
        options.routeShapeResolution = .full
        
        // Apply navigation options if provided
        if let navigationOptions = arguments["options"] as? [String: Any] {
            if let profile = navigationOptions["profile"] as? String {
                switch profile {
                case "walking":
                    options.profileIdentifier = .walking
                case "cycling":
                    options.profileIdentifier = .cycling
                default:
                    options.profileIdentifier = .automobile
                }
            }
        }
        
        // Calculate route
        directions.calculate(options) { [weak self] (waypoints, routes, error) in
            DispatchQueue.main.async {
                if let error = error {
                    NSLog("Route calculation error: \(error.localizedDescription)")
                    result(FlutterError(
                        code: "ROUTE_CALCULATION_ERROR",
                        message: error.localizedDescription,
                        details: nil
                    ))
                    return
                }
                
                guard let route = routes?.first else {
                    result(FlutterError(
                        code: "NO_ROUTE_FOUND",
                        message: "No route found",
                        details: nil
                    ))
                    return
                }
                
                // Store the route for later use
                self?.currentRoute = route
                
                // Convert route to dictionary for Flutter
                let routeDict: [String: Any] = [
                    "geometry": route.coordinateCount > 0 ? "encoded_polyline" : "",
                    "distance": route.distance,
                    "duration": route.expectedTravelTime,
                    "waypoints": waypoints?.map { [$0.coordinate.latitude, $0.coordinate.longitude] } ?? []
                ]
                
                NSLog("Successfully calculated route with distance: \(route.distance)m")
                result(routeDict)
            }
        }
    }
    
    private func startNavigation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let routeDict = arguments["route"] as? [String: Any]
        else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid arguments for startNavigation",
                details: nil
            ))
            return
        }
        
        guard let route = currentRoute else {
            result(FlutterError(
                code: "NO_ROUTE",
                message: "No route available. Please calculate a route first.",
                details: nil
            ))
            return
        }
        
        // Initialize navigation
        isNavigationActive = true
        
        // Create route controller
        routeController = RouteController(along: route)
        
        // Initialize progress
        let distance = routeDict["distance"] as? Double ?? route.distance
        let duration = routeDict["duration"] as? Double ?? route.expectedTravelTime
        
        currentProgress = [
            "distanceRemaining": distance,
            "durationRemaining": duration,
            "fractionTraveled": 0.0,
            "currentStepIndex": 0,
            "currentLegIndex": 0
        ]
        
        NSLog("Started navigation with route distance: \(distance)m")
        
        // Send navigation event
        sendNavigationEvent(eventType: "navigation_started", data: nil)
        
        result(nil)
    }
    
    private func stopNavigation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Cleanup navigation resources
        isNavigationActive = false
        currentRoute = nil
        currentProgress = nil
        routeController = nil
        
        // Dismiss navigation view controller if present
        if let navVC = navigationViewController {
            navVC.dismiss(animated: true, completion: nil)
            navigationViewController = nil
        }
        
        NSLog("Stopped navigation")
        
        // Send navigation event
        sendNavigationEvent(eventType: "navigation_stopped", data: nil)
        
        result(nil)
    }
    
    private func pauseNavigation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // TODO: Integrate with TrackAsia Navigation iOS SDK
        NSLog("Paused navigation")
        
        // Send navigation event
        sendNavigationEvent(eventType: "navigation_paused", data: nil)
        
        result(nil)
    }
    
    private func resumeNavigation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // TODO: Integrate with TrackAsia Navigation iOS SDK
        NSLog("Resumed navigation")
        
        // Send navigation event
        sendNavigationEvent(eventType: "navigation_resumed", data: nil)
        
        result(nil)
    }
    
    private func sendNavigationEvent(eventType: String, data: [String: Any]?) {
        var event: [String: Any] = [
            "type": eventType,
            "timestamp": Int64(Date().timeIntervalSince1970 * 1000)
        ]
        
        if let data = data {
            event["data"] = data
        }
        
        methodChannel.invokeMethod("navigation#onEvent", arguments: event)
    }
    
    private func sendRouteProgress(_ progress: [String: Any]) {
        methodChannel.invokeMethod("navigation#onRouteProgress", arguments: progress)
    }
    
    private func sendVoiceInstruction(_ instruction: [String: Any]) {
        methodChannel.invokeMethod("navigation#onVoiceInstruction", arguments: instruction)
    }
    
    private func sendBannerInstruction(_ instruction: [String: Any]) {
        methodChannel.invokeMethod("navigation#onBannerInstruction", arguments: instruction)
    }
}
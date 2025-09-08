import Flutter
import Foundation
import TrackAsia
import UIKit
import CoreLocation
// TODO: Add MapboxDirections and Turf when properly configured
// import MapboxDirections
// import Turf

/**
 * Handles navigation-related method calls from Flutter
 */
class NavigationMethodHandler: NSObject {
    private let methodChannel: FlutterMethodChannel
    private let registrar: FlutterPluginRegistrar
    // TODO: Enable when MapboxDirections is properly configured
    // private let directions: Directions
    
    // Navigation state
    private var isNavigationActive = false
    private var currentRouteData: [String: Any]?
    private var currentProgress: [String: Any]?
    // Note: NavigationViewController and RouteController are not available in current setup
    // These will need to be implemented when TrackAsia Navigation is properly integrated
    
    // Core navigation components
    private var routeHandler: RouteHandler
    private var mapRouteView: MapRouteView?
    
    // Legacy route management (for backward compatibility)
    private var activeRoutes: [String: MLNPolyline] = [:]
    private var routeStyles: [String: [String: Any]] = [:]
    
    init(registrar: FlutterPluginRegistrar) {
        print("NavigationMethodHandler: Initializing...")
        self.registrar = registrar
        self.methodChannel = FlutterMethodChannel(
            name: "plugins.flutter.io/trackasia_gl_navigation",
            binaryMessenger: registrar.messenger()
        )
        
        // Initialize core navigation components
        self.routeHandler = RouteHandler()
        
        // TODO: Initialize Directions when MapboxDirections is properly configured
        // let apiKey = Bundle.main.object(forInfoDictionaryKey: "TrackAsiaAPIKey") as? String ?? ""
        // self.directions = Directions(accessToken: apiKey)
        
        super.init()
        
        // Set up route handler delegate
        self.routeHandler.delegate = self
        
        // Set up method channel handler
        methodChannel.setMethodCallHandler { [weak self] (call, result) in
            print("NavigationMethodHandler: Received method call: \(call.method)")
            self?.handleMethodCall(call, result: result)
        }
        
        print("NavigationMethodHandler: Initialization complete")
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
        // NavigationMapRoute methods
        case "navigationMapRoute#addRoute":
            addNavigationRoute(call, result: result)
        case "navigationMapRoute#addRoutes":
            addNavigationRoutes(call, result: result)
        case "navigationMapRoute#removeRoute":
            removeNavigationRoute(call, result: result)
        case "navigationMapRoute#clearRoutes":
            clearNavigationRoutes(result: result)
        case "navigationMapRoute#setVisibility":
            setRouteVisibility(call, result: result)
        case "navigationMapRoute#fitCameraToRoutes":
            fitCameraToRoutes(call, result: result)
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
        
        // TODO: Directions API is not available yet, return error for now
        result(FlutterError(
            code: "DIRECTIONS_NOT_AVAILABLE",
            message: "Directions API is not properly configured. Please configure TrackAsia Directions first.",
            details: nil
        ))
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
        
        guard let routeData = currentRouteData else {
            result(FlutterError(
                code: "NO_ROUTE",
                message: "No route available. Please calculate a route first.",
                details: nil
            ))
            return
        }
        
        // TODO: Implement navigation UI when TrackAsia Navigation is properly integrated
        // This would require NavigationViewController, NavigationService, and RouteController classes
        // that are not currently available in the TrackAsia SDK
        
        // Initialize navigation state
        isNavigationActive = true
        
        // Initialize progress
        let distance = routeData["distance"] as? Double ?? 0.0
        let duration = routeData["duration"] as? Double ?? 0.0
        
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
        
        result(["success": true, "message": "Navigation started"])
    }
    
    private func stopNavigation(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // TODO: Stop navigation service when TrackAsia Navigation is properly integrated
        
        // Cleanup navigation resources
        isNavigationActive = false
        currentRouteData = nil
        currentProgress = nil
        
        NSLog("Stopped navigation")
        
        // Send navigation event
        sendNavigationEvent(eventType: "navigation_stopped", data: nil)
        
        result(["success": true, "message": "Navigation stopped"])
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
    
    // MARK: - NavigationMapRoute Methods
    
    private func addNavigationRoute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let routeData = arguments["route"] as? [String: Any] else {
            result(FlutterError(code: "INVALID_ROUTE", message: "Route data is required", details: nil))
            return
        }
        
        let styleData = arguments["style"] as? [String: Any]
        let isPrimary = arguments["isPrimary"] as? Bool ?? true
        let routeId = arguments["routeId"] as? String ?? "route_\(Int(Date().timeIntervalSince1970 * 1000))"
        
        guard let geometry = routeData["geometry"] as? String else {
            result(FlutterError(code: "INVALID_GEOMETRY", message: "Route geometry is required", details: nil))
            return
        }
        
        // Create NavigationRoute from route data
        let navigationRoute = NavigationRoute(
            id: routeId,
            coordinates: [], // TODO: Parse coordinates from geometry
            distance: routeData["distance"] as? Double ?? 0.0,
            duration: routeData["duration"] as? Double ?? 0.0,
            waypoints: [], // TODO: Parse waypoints from routeData
            legs: [] // TODO: Parse legs from routeData
        )
        
        // Add route using RouteHandler
        let finalRouteId = routeHandler.addRoute(navigationRoute, routeId: routeId)
        
        // Display route on map using MapRouteView
        let routeStyle = RouteStyle.defaultPrimaryStyle()
        mapRouteView?.addRoute(withId: finalRouteId, route: navigationRoute, style: routeStyle)
        
        // Store route for navigation if it's primary
        if isPrimary {
            currentRouteData = routeData
            NSLog("Primary route added: %@", finalRouteId)
        }
        
        NSLog("Navigation route added successfully: %@", finalRouteId)
        result(["routeId": finalRouteId, "success": true])
    }
    
    private func addNavigationRoutes(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let routes = arguments["routes"] as? [[String: Any]], !routes.isEmpty else {
            result(FlutterError(code: "INVALID_ROUTES", message: "Routes list is required and cannot be empty", details: nil))
            return
        }
        
        let primaryStyle = arguments["primaryStyle"] as? [String: Any]
        let alternativeStyle = arguments["alternativeStyle"] as? [String: Any]
        let config = arguments["config"] as? [String: Any]
        
        var routeIds: [String] = []
        
        for (index, route) in routes.enumerated() {
            let isPrimary = index == 0
            let routeId = route["id"] as? String ?? "route_\(Int(Date().timeIntervalSince1970 * 1000))_\(index)"
            
            routeIds.append(routeId)
            
            // Handle geometry if present (similar to RouteHandler.swift addRoute method)
            if let geometry = route["geometry"] as? String {
                if let coordinates = decodePolyline(geometry) {
                    addRouteToMap(routeId: routeId, coordinates: coordinates, isPrimary: isPrimary)
                }
            } else if let coordinatesData = route["coordinates"] as? [[Double]] {
                // Handle coordinates array format
                let coordinates = coordinatesData.compactMap { coord -> CLLocationCoordinate2D? in
                    guard coord.count >= 2 else { return nil }
                    return CLLocationCoordinate2D(latitude: coord[1], longitude: coord[0])
                }
                
                if !coordinates.isEmpty {
                    addRouteToMap(routeId: routeId, coordinates: coordinates, isPrimary: isPrimary)
                }
            }
            
            // Store route style if provided
            if let style = route["style"] as? [String: Any] {
                routeStyles[routeId] = style
            } else if isPrimary && primaryStyle != nil {
                routeStyles[routeId] = primaryStyle
            } else if !isPrimary && alternativeStyle != nil {
                routeStyles[routeId] = alternativeStyle
            }
        }
        
        // Return routeIds array to match Android implementation
        result(["routeIds": routeIds, "success": true])
    }
    
    // Helper method to decode polyline geometry
    private func decodePolyline(_ encoded: String) -> [CLLocationCoordinate2D]? {
        // TODO: Implement proper polyline decoding when TrackAsia Navigation is available
        // For now, return empty array to avoid compilation errors
        guard !encoded.isEmpty else { return nil }
        
        // Placeholder implementation - needs proper polyline decoding library
        NSLog("Polyline decoding not yet implemented: \(encoded)")
        return []
    }
    
    // Helper method to add route to map
    private func addRouteToMap(routeId: String, coordinates: [CLLocationCoordinate2D], isPrimary: Bool) {
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        
        // Store the route
        activeRoutes[routeId] = polyline
        
        // In a real implementation, you would add this polyline to the map view
        // For now, just log the addition
        NSLog("Route \(routeId) added to map with \(coordinates.count) coordinates (primary: \(isPrimary))")
    }
    
    private func removeNavigationRoute(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let routeId = arguments["routeId"] as? String else {
            result(FlutterError(code: "INVALID_ROUTE_ID", message: "Route ID is required", details: nil))
            return
        }
        
        // Remove route using RouteHandler
        routeHandler.removeRoute(withId: routeId)
        
        // Remove route from map using MapRouteView
        mapRouteView?.removeRoute(withId: routeId)
        
        // Legacy cleanup for backward compatibility
        activeRoutes.removeValue(forKey: routeId)
        routeStyles.removeValue(forKey: routeId)
        
        NSLog("Navigation route removed: %@", routeId)
        result(["routeId": routeId, "success": true])
    }
    
    private func clearNavigationRoutes(result: @escaping FlutterResult) {
        // Clear routes using RouteHandler
        routeHandler.clearAllRoutes()
        
        // Clear routes from map using MapRouteView
        mapRouteView?.clearAllRoutes()
        
        // Legacy cleanup for backward compatibility
        activeRoutes.removeAll()
        routeStyles.removeAll()
        
        NSLog("All navigation routes cleared")
        result(["success": true])
    }
    
    private func setRouteVisibility(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let arguments = call.arguments as? [String: Any],
              let routeId = arguments["routeId"] as? String else {
            result(FlutterError(code: "INVALID_ROUTE_ID", message: "Route ID is required", details: nil))
            return
        }
        
        let visible = arguments["visible"] as? Bool ?? true
        
        // Set route visibility using MapRouteView
        mapRouteView?.setRouteVisibility(routeId: routeId, visible: visible)
        
        NSLog("Route visibility changed: %@ -> %@", routeId, visible ? "true" : "false")
        result(["routeId": routeId, "visible": visible, "success": true])
    }
    
    private func fitCameraToRoutes(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // TODO: Implement camera fitting when map view integration is available
        // This would calculate bounds from all active routes and fit camera
        NSLog("Fit camera to routes requested")
        
        // Fit camera to routes using MapRouteView
        mapRouteView?.fitCameraToRoutes()
        
        result(["success": true])
    }
    
}

// MARK: - Navigation Delegate Methods (Placeholder)
extension NavigationMethodHandler {
    
    // TODO: Implement navigation delegate methods when TrackAsia Navigation classes are available
    // These methods would handle:
    // - Route progress updates
    // - Waypoint arrivals
    // - Navigation completion/cancellation
    
    private func handleRouteProgress(_ progressData: [String: Any]) {
        currentProgress = progressData
        sendNavigationEvent(eventType: "navigation_progress", data: progressData)
    }
    
    private func handleWaypointArrival(_ waypointData: [String: Any]) {
        sendNavigationEvent(eventType: "navigation_waypoint_arrival", data: waypointData)
    }
    
    private func handleNavigationDismissal(canceled: Bool) {
        isNavigationActive = false
        currentRouteData = nil
        currentProgress = nil
        
        let dismissData: [String: Any] = ["canceled": canceled]
        sendNavigationEvent(eventType: "navigation_dismissed", data: dismissData)
    }
}

// MARK: - RouteHandlerDelegate
extension NavigationMethodHandler: RouteHandlerDelegate {
    func routeHandler(_ handler: RouteHandler, didAddRoute route: NavigationRoute, withId routeId: String, isPrimary: Bool) {
        NSLog("Route added via RouteHandler: %@ (primary: %@)", routeId, isPrimary ? "true" : "false")
    }
    
    func routeHandler(_ handler: RouteHandler, didRemoveRoute route: NavigationRoute, withId routeId: String) {
        NSLog("Route removed via RouteHandler: %@", routeId)
    }
    
    func routeHandler(_ handler: RouteHandler, didClearAllRoutes routeIds: [String]) {
        NSLog("All routes cleared via RouteHandler: %@", routeIds.joined(separator: ", "))
    }
    
    func routeHandler(_ handler: RouteHandler, didUpdateStyleForRouteId routeId: String, style: RouteStyle) {
        NSLog("Route style updated via RouteHandler: %@", routeId)
    }
}

// MARK: - Navigation Route Models

struct NavigationRoute {
    let id: String
    let geometry: String?
    let coordinates: [CLLocationCoordinate2D]?
    let distance: Double
    let duration: Double
    let waypoints: [Waypoint]
    let legs: [RouteLeg]
    
    init(id: String, geometry: String? = nil, coordinates: [CLLocationCoordinate2D]? = nil, distance: Double = 0.0, duration: Double = 0.0, waypoints: [Waypoint] = [], legs: [RouteLeg] = []) {
        self.id = id
        self.geometry = geometry
        self.coordinates = coordinates
        self.distance = distance
        self.duration = duration
        self.waypoints = waypoints
        self.legs = legs
    }
}

struct Waypoint {
    let coordinate: CLLocationCoordinate2D
    let name: String?
    
    init(coordinate: CLLocationCoordinate2D, name: String? = nil) {
        self.coordinate = coordinate
        self.name = name
    }
}

struct RouteLeg {
    let distance: Double
    let duration: Double
    let steps: [RouteStep]
    
    init(distance: Double = 0.0, duration: Double = 0.0, steps: [RouteStep] = []) {
        self.distance = distance
        self.duration = duration
        self.steps = steps
    }
}

struct RouteStep {
    let distance: Double
    let duration: Double
    let instruction: String
    let coordinate: CLLocationCoordinate2D
    
    init(distance: Double = 0.0, duration: Double = 0.0, instruction: String = "", coordinate: CLLocationCoordinate2D) {
        self.distance = distance
        self.duration = duration
        self.instruction = instruction
        self.coordinate = coordinate
    }
}

struct RouteStyle {
    let lineColor: UIColor
    let lineWidth: CGFloat
    let lineCap: String
    let lineJoin: String
    let lineOpacity: Float
    let casingColor: UIColor?
    let casingWidth: CGFloat?
    let casingOpacity: Float?
    
    init(lineColor: UIColor = .systemBlue, lineWidth: CGFloat = 5.0, lineCap: String = "round", lineJoin: String = "round", lineOpacity: Float = 1.0, casingColor: UIColor? = nil, casingWidth: CGFloat? = nil, casingOpacity: Float? = nil) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.lineCap = lineCap
        self.lineJoin = lineJoin
        self.lineOpacity = lineOpacity
        self.casingColor = casingColor
        self.casingWidth = casingWidth
        self.casingOpacity = casingOpacity
    }
    
    static func defaultPrimaryStyle() -> RouteStyle {
        return RouteStyle(
            lineColor: .systemBlue,
            lineWidth: 8.0,
            lineOpacity: 0.8,
            casingColor: .white,
            casingWidth: 10.0,
            casingOpacity: 1.0
        )
    }
    
    static func defaultAlternativeStyle() -> RouteStyle {
        return RouteStyle(
            lineColor: .systemGray,
            lineWidth: 6.0,
            lineOpacity: 0.6,
            casingColor: .lightGray,
            casingWidth: 8.0,
            casingOpacity: 0.8
        )
    }
}

// MARK: - Route Handler

protocol RouteHandlerDelegate: AnyObject {
    func routeHandler(_ handler: RouteHandler, didAddRoute route: NavigationRoute, withId routeId: String, isPrimary: Bool)
    func routeHandler(_ handler: RouteHandler, didRemoveRoute route: NavigationRoute, withId routeId: String)
    func routeHandler(_ handler: RouteHandler, didClearAllRoutes routeIds: [String])
    func routeHandler(_ handler: RouteHandler, didUpdateStyleForRouteId routeId: String, style: RouteStyle)
}

// MARK: - RouteHandler Class

class RouteHandler: NSObject {
    
    // MARK: - Properties
    
    private var activeRoutes: [String: NavigationRoute] = [:]
    
    // MARK: - Route Styles
    private var routeStyles: [String: RouteStyle] = [:]
    
    // MARK: - Delegate
    weak var delegate: RouteHandlerDelegate?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
    }
    
    // MARK: - Route Management
    
    func addRoute(_ route: NavigationRoute, style: RouteStyle? = nil, routeId: String? = nil, isPrimary: Bool = false) -> String {
        let finalRouteId = routeId ?? UUID().uuidString
        let finalStyle = style ?? (isPrimary ? RouteStyle.defaultPrimaryStyle() : RouteStyle.defaultAlternativeStyle())
        
        activeRoutes[finalRouteId] = route
        routeStyles[finalRouteId] = finalStyle
        
        delegate?.routeHandler(self, didAddRoute: route, withId: finalRouteId, isPrimary: isPrimary)
        
        return finalRouteId
    }
    
    func removeRoute(withId routeId: String) -> Bool {
        guard let route = activeRoutes.removeValue(forKey: routeId) else {
            return false
        }
        
        routeStyles.removeValue(forKey: routeId)
        delegate?.routeHandler(self, didRemoveRoute: route, withId: routeId)
        
        return true
    }
    
    func clearAllRoutes() {
        let routeIds = Array(activeRoutes.keys)
        activeRoutes.removeAll()
        routeStyles.removeAll()
        delegate?.routeHandler(self, didClearAllRoutes: routeIds)
    }
    
    func getRoute(withId routeId: String) -> NavigationRoute? {
        return activeRoutes[routeId]
    }
    
    func getAllRoutes() -> [String: NavigationRoute] {
        return activeRoutes
    }
    
    func getRouteStyle(withId routeId: String) -> RouteStyle? {
        return routeStyles[routeId]
    }
    
    func updateRouteStyle(withId routeId: String, style: RouteStyle) {
        routeStyles[routeId] = style
        delegate?.routeHandler(self, didUpdateStyleForRouteId: routeId, style: style)
    }
    
    func hasRoute(withId routeId: String) -> Bool {
        return activeRoutes[routeId] != nil
    }
    
    func getRouteCount() -> Int {
        return activeRoutes.count
    }
}

// MARK: - MapRouteView Class

class MapRouteView: NSObject {
    
    // MARK: - Properties
    
    private weak var mapView: MLNMapView?
    private var routePolylines: [String: MLNPolyline] = [:]
    private var routeCasings: [String: MLNPolyline] = [:]
    private var routeVisibility: [String: Bool] = [:]
    
    private let routeSourcePrefix = "route-source-"
    private let routeLayerPrefix = "route-layer-"
    private let casingSourcePrefix = "casing-source-"
    private let casingLayerPrefix = "casing-layer-"
    
    // MARK: - Initialization
    
    init(mapView: MLNMapView) {
        super.init()
        self.mapView = mapView
    }
    
    // MARK: - Route Display Management
    
    func addRoute(withId routeId: String, route: NavigationRoute, style: RouteStyle, isPrimary: Bool = false) {
        guard let coordinates = route.coordinates, !coordinates.isEmpty else {
            NSLog("Cannot add route with empty coordinates")
            return
        }
        
        let polyline = MLNPolyline(coordinates: coordinates, count: UInt(coordinates.count))
        addRoutePolylineToMap(routeId: routeId, polyline: polyline, style: style, isPrimary: isPrimary)
        routePolylines[routeId] = polyline
        routeVisibility[routeId] = true
    }
    
    func removeRoute(withId routeId: String) {
        removeRouteFromMap(routeId: routeId)
        routePolylines.removeValue(forKey: routeId)
        routeCasings.removeValue(forKey: routeId)
        routeVisibility.removeValue(forKey: routeId)
    }
    
    func clearAllRoutes() {
        for routeId in routePolylines.keys {
            removeRouteFromMap(routeId: routeId)
        }
        routePolylines.removeAll()
        routeCasings.removeAll()
        routeVisibility.removeAll()
    }
    
    func setRouteVisibility(routeId: String, visible: Bool) {
        routeVisibility[routeId] = visible
        updateRouteLayerVisibility(routeId: routeId, visible: visible)
    }
    
    func fitCameraToRoutes(padding: UIEdgeInsets = UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: Bool = true) {
        guard !routePolylines.isEmpty else {
            return
        }
        
        var allCoordinates: [CLLocationCoordinate2D] = []
        for polyline in routePolylines.values {
            let coordinates = polyline.coordinates
            for i in 0..<polyline.pointCount {
                allCoordinates.append(coordinates[Int(i)])
            }
        }
        
        if !allCoordinates.isEmpty {
            let bounds = MLNCoordinateBounds(coordinates: allCoordinates)
            mapView?.setVisibleCoordinateBounds(bounds, edgePadding: padding, animated: animated)
        }
    }
    
    // MARK: - Private Methods
    
    private func addRoutePolylineToMap(routeId: String, polyline: MLNPolyline, style: RouteStyle, isPrimary: Bool) {
        guard let mapView = mapView, let mapStyle = mapView.style else {
            return
        }
        
        // Add casing layer first (if specified)
        if let casingColor = style.casingColor, let casingWidth = style.casingWidth {
            addCasingLayer(routeId: routeId, polyline: polyline, color: casingColor, width: casingWidth, opacity: style.casingOpacity ?? 1.0)
        }
        
        // Add main route layer
        addRouteLayer(routeId: routeId, polyline: polyline, style: style)
    }
    
    private func addRouteLayer(routeId: String, polyline: MLNPolyline, style: RouteStyle) {
        guard let mapView = mapView, let mapStyle = mapView.style else {
            return
        }
        
        let sourceId = routeSourcePrefix + routeId
        let layerId = routeLayerPrefix + routeId
        
        // Create source
        let source = MLNShapeSource(identifier: sourceId, shape: polyline, options: nil)
        mapStyle.addSource(source)
        
        // Create layer
        let layer = MLNLineStyleLayer(identifier: layerId, source: source)
        layer.lineColor = NSExpression(forConstantValue: style.lineColor)
        layer.lineWidth = NSExpression(forConstantValue: style.lineWidth)
        layer.lineCap = NSExpression(forConstantValue: style.lineCap)
        layer.lineJoin = NSExpression(forConstantValue: style.lineJoin)
        layer.lineOpacity = NSExpression(forConstantValue: style.lineOpacity)
        
        mapStyle.addLayer(layer)
    }
    
    private func addCasingLayer(routeId: String, polyline: MLNPolyline, color: UIColor, width: CGFloat, opacity: Float) {
        guard let mapView = mapView, let mapStyle = mapView.style else {
            return
        }
        
        let sourceId = casingSourcePrefix + routeId
        let layerId = casingLayerPrefix + routeId
        
        // Create source
        let source = MLNShapeSource(identifier: sourceId, shape: polyline, options: nil)
        mapStyle.addSource(source)
        
        // Create layer
        let layer = MLNLineStyleLayer(identifier: layerId, source: source)
        layer.lineColor = NSExpression(forConstantValue: color)
        layer.lineWidth = NSExpression(forConstantValue: width)
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineOpacity = NSExpression(forConstantValue: opacity)
        
        mapStyle.addLayer(layer)
        
        routeCasings[routeId] = polyline
    }
    
    private func removeRouteFromMap(routeId: String) {
        guard let mapView = mapView, let mapStyle = mapView.style else {
            return
        }
        
        // Remove main route layer and source
        let routeLayerId = routeLayerPrefix + routeId
        let routeSourceId = routeSourcePrefix + routeId
        
        if let layer = mapStyle.layer(withIdentifier: routeLayerId) {
            mapStyle.removeLayer(layer)
        }
        if let source = mapStyle.source(withIdentifier: routeSourceId) {
            mapStyle.removeSource(source)
        }
        
        // Remove casing layer and source
        let casingLayerId = casingLayerPrefix + routeId
        let casingSourceId = casingSourcePrefix + routeId
        
        if let layer = mapStyle.layer(withIdentifier: casingLayerId) {
            mapStyle.removeLayer(layer)
        }
        if let source = mapStyle.source(withIdentifier: casingSourceId) {
            mapStyle.removeSource(source)
        }
    }
    
    private func updateRouteLayerVisibility(routeId: String, visible: Bool) {
        guard let mapView = mapView, let mapStyle = mapView.style else {
            return
        }
        
        let routeLayerId = routeLayerPrefix + routeId
        let casingLayerId = casingLayerPrefix + routeId
        
        if let layer = mapStyle.layer(withIdentifier: routeLayerId) as? MLNLineStyleLayer {
            layer.isVisible = visible
        }
        if let layer = mapStyle.layer(withIdentifier: casingLayerId) as? MLNLineStyleLayer {
            layer.isVisible = visible
        }
    }
}

// MARK: - MLNCoordinateBounds Extension

extension MLNCoordinateBounds {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self.init()
            return
        }
        
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLng = coordinates[0].longitude
        var maxLng = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLng = min(minLng, coordinate.longitude)
            maxLng = max(maxLng, coordinate.longitude)
        }
        
        let sw = CLLocationCoordinate2D(latitude: minLat, longitude: minLng)
        let ne = CLLocationCoordinate2D(latitude: maxLat, longitude: maxLng)
        
        self.init(sw: sw, ne: ne)
    }
}
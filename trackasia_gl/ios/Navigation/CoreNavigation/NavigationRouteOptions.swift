import Foundation
import MapboxDirections
import CoreLocation

/**
 A `NavigationRouteOptions` object specifies turn-by-turn-optimized criteria for results returned by the Directions API.

 `NavigationRouteOptions` is a subclass of `RouteOptions` that has been optimized for navigation.
 */
public class NavigationRouteOptions: RouteOptions {
    /**
     Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.
     */
    public convenience init(waypoints: [Waypoint], profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic) {
        self.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        })
        self.profileIdentifier = profileIdentifier
        configureForNavigation()
    }

    /**
     Initializes a navigation route options object for routes between the given locations and an optional profile identifier optimized for navigation.
     */
    public convenience init(locations: [CLLocation], profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }

    /**
     Initializes a route options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic) {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, profileIdentifier: profileIdentifier)
    }
    
    private func configureForNavigation() {
        includesAlternativeRoutes = true
        includesSteps = true
        routeShapeResolution = .full
        attributeOptions = [.congestionLevel, .expectedTravelTime]
        includesSpokenInstructions = true
        locale = Locale.nationalizedCurrent
        distanceMeasurementSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        includesVisualInstructions = true
    }
}

/**
 A `NavigationMatchOptions` object specifies turn-by-turn-optimized criteria for results returned by the Map Matching API.
 
 `NavigationMatchOptions` is a subclass of `MatchOptions` that has been optimized for navigation.
 */
public class NavigationMatchOptions: MatchOptions {
    /**
     Initializes a navigation match options object for routes between the given waypoints and an optional profile identifier optimized for navigation.
     */
    public convenience init(waypoints: [Waypoint], profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic) {
        self.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        })
        self.profileIdentifier = profileIdentifier
        configureForNavigation()
    }
    
    /**
     Initializes a navigation match options object for routes between the given locations and an optional profile identifier optimized for navigation.
     */
    public convenience init(locations: [CLLocation], profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }
    
    /**
     Initializes a navigation match options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: ProfileIdentifier = .automobileAvoidingTraffic) {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, profileIdentifier: profileIdentifier)
    }
    
    private func configureForNavigation() {
        includesSteps = true
        routeShapeResolution = .full
        attributeOptions = [.congestionLevel, .expectedTravelTime]
        includesSpokenInstructions = true
        locale = Locale.nationalizedCurrent
        distanceMeasurementSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        includesVisualInstructions = true
    }
}

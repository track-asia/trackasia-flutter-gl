import CoreLocation
import MapboxDirections

extension RouteOptions {
    var activityType: CLActivityType {
        switch profileIdentifier {
        case .cycling, .walking:
            .fitness
        default:
            .automotiveNavigation
        }
    }
    
    /**
     Returns a copy of RouteOptions without the specified waypoint.
     
     - parameter waypoint: the Waypoint to exclude.
     - returns: a copy of self excluding the specified waypoint.
     */
    public func without(waypoint: Waypoint) -> RouteOptions {
        let waypointsWithoutSpecified = waypoints.filter { $0 != waypoint }
        let copy = RouteOptions(waypoints: waypointsWithoutSpecified)
        // Copy relevant properties
        copy.profileIdentifier = profileIdentifier
        copy.includesSteps = includesSteps
        copy.routeShapeResolution = routeShapeResolution
        copy.attributeOptions = attributeOptions
        copy.locale = locale
        copy.includesSpokenInstructions = includesSpokenInstructions
        copy.distanceMeasurementSystem = distanceMeasurementSystem
        copy.includesVisualInstructions = includesVisualInstructions
        
        return copy
    }
}

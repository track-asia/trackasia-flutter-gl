import CoreLocation
import MapboxDirections

// MARK: - MapboxDirections API Compatibility
// Centralized compatibility definitions for older MapboxNavigation code
// to work with newer MapboxDirections library versions (2.x).

// MARK: - Type Aliases

/// Alias for ProfileIdentifier to maintain API compatibility
/// In MapboxDirections 2.x, DirectionsProfileIdentifier was renamed to ProfileIdentifier
public typealias DirectionsProfileIdentifier = ProfileIdentifier

// MARK: - Route Extensions

extension Route {
    /// Returns the coordinates along the route
    /// Compatibility wrapper for shape.coordinates
    public var coordinates: [CLLocationCoordinate2D]? {
        shape?.coordinates
    }
}

// MARK: - RouteStep Extensions

extension RouteStep {
    /// Returns the coordinates along this step
    /// Compatibility wrapper for shape.coordinates
    public var coordinates: [CLLocationCoordinate2D]? {
        shape?.coordinates
    }
}

// MARK: - RouteLeg Extensions

extension RouteLeg {
    /// Returns the expected segment travel times for this leg
    /// Note: Returns nil as this property format changed in newer API
    public var expectedSegmentTravelTimes: [TimeInterval]? {
        return nil
    }
}

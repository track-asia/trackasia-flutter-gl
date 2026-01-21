// Route+Testing.swift - Temporarily disabled due to API incompatibility
// This feature is only used for testing with fixture JSON files

import CoreLocation
import MapboxDirections

// FIXME: MapboxDirections 2.x uses different Route initialization
// extension Route {
//     convenience init(jsonFileName: String, waypoints: [CLLocationCoordinate2D], polylineShapeFormat: RouteShapeFormat = .polyline6, bundle: Bundle = .main, accessToken: String) {
//         let convertedWaypoints = waypoints.compactMap { waypoint in
//             Waypoint(coordinate: waypoint)
//         }
//         let routeOptions = NavigationRouteOptions(waypoints: convertedWaypoints)
//         routeOptions.shapeFormat = polylineShapeFormat
//         self.init(json: Fixture.JSONFromFileNamed(name: jsonFileName, bundle: bundle), waypoints: convertedWaypoints, options: routeOptions)
//     }
// }

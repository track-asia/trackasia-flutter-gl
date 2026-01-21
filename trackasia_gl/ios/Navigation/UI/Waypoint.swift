import CoreLocation
import MapboxDirections

extension Waypoint {
    var location: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    // MapboxDirections 2.x uses VisualInstruction.Component enum
    var instructionComponent: VisualInstruction.Component? {
        guard let name else { return nil }
        let textRep = VisualInstruction.Component.TextRepresentation(
            text: name,
            abbreviation: nil,
            abbreviationPriority: nil
        )
        return .text(text: textRep)
    }
    
    var instructionComponents: [VisualInstruction.Component]? {
        (self.instructionComponent != nil) ? [self.instructionComponent!] : nil
    }
}

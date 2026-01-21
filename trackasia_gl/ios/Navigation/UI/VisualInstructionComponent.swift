import MapboxDirections
import UIKit

// MARK: - MapboxDirections 2.x Compatibility
// VisualInstructionComponent class was replaced by VisualInstruction.Component enum in 2.x
public typealias VisualInstructionComponent = VisualInstruction.Component

/// Type enum for compatibility with old VisualInstructionComponent class API
public enum VisualInstructionComponentType {
    case text
    case image
    case exit
    case exitCode
    case delimiter
    case guidanceView
    case lane
}

extension VisualInstruction.Component {
    static let scale = UIScreen.main.scale
    
    /// Compatibility property for old class-based API
    var type: VisualInstructionComponentType {
        switch self {
        case .text: return .text
        case .image: return .image
        case .exit: return .exit
        case .exitCode: return .exitCode
        case .delimiter: return .delimiter
        case .guidanceView: return .guidanceView
        case .lane: return .lane
        }
    }
    
    /// Compatibility property for old class-based API
    var text: String? {
        switch self {
        case .text(let text), .delimiter(let text), .exit(let text), .exitCode(let text):
            return text.text
        case .image(_, let alt):
            return alt.text
        case .guidanceView(_, let alt):
            return alt.text
        case .lane:
            return nil
        }
    }
    
    /// Compatibility property for old class-based API
    var imageURL: URL? {
        switch self {
        case .image(let image, _):
            return image.imageBaseURL
        case .guidanceView(let image, _):
            return image.imageURL
        default:
            return nil
        }
    }
    
    /// Compatibility property for old class-based API
    var abbreviation: String? {
        switch self {
        case .text(let text), .delimiter(let text), .exit(let text), .exitCode(let text):
            return text.abbreviation
        default:
            return nil
        }
    }
    
    /// Compatibility property for old class-based API
    var abbreviationPriority: Int {
        switch self {
        case .text(let text), .delimiter(let text), .exit(let text), .exitCode(let text):
            return text.abbreviationPriority ?? Int.max
        default:
            return Int.max
        }
    }
    
    var cacheKey: String? {
        switch self {
        case .exit(let text), .exitCode(let text):
            return "exit-" + text.text + "-\(VisualInstruction.Component.scale)"
        case .image(let image, _):
            guard let imageURL = image.imageBaseURL else { return self.genericCacheKey }
            return "\(imageURL.absoluteString)-\(VisualInstruction.Component.scale)"
        case .text, .delimiter, .guidanceView, .lane:
            return nil
        }
    }
    
    var genericCacheKey: String {
        switch self {
        case .text(let text), .delimiter(let text), .exit(let text), .exitCode(let text):
            return "generic-" + text.text
        case .image(_, let alt):
            return "generic-" + alt.text
        case .guidanceView(_, let alt):
            return "generic-" + alt.text
        case .lane:
            return "generic-lane"
        }
    }
}

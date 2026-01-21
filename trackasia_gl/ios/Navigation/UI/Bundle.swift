import UIKit

extension Bundle {
    // For CocoaPods, use main bundle since SPM .module is not available
    // In a real SPM setup, .module would point to the resource bundle
    class var mapboxNavigation: Bundle {
        // Try to find the bundle containing navigation resources
        if let bundlePath = Bundle.main.path(forResource: "MapboxNavigation", ofType: "bundle"),
           let bundle = Bundle(path: bundlePath) {
            return bundle
        }
        // Fallback to main bundle
        return .main
    }
    
    func image(named: String) -> UIImage? {
        UIImage(named: named, in: self, compatibleWith: nil)
    }
    
    var microphoneUsageDescription: String? {
        let para = "NSMicrophoneUsageDescription"
        let key = "Privacy - Microphone Usage Description"
        return object(forInfoDictionaryKey: para) as? String ?? object(forInfoDictionaryKey: key) as? String
    }
}


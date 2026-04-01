import UIKit

extension Bundle {
    // For CocoaPods with Flutter, resources are typically in the framework bundle
    class var mapboxNavigation: Bundle {
        // Try to find the bundle containing navigation resources
        // For Flutter plugins, resources are in the plugin's framework bundle
        
        // First, try to find the trackasia_gl plugin bundle
        // The class is defined in the plugin, so we can use it to find the bundle
        let pluginBundle = Bundle(for: NavigationViewController.self)
        
        // Check if the resources exist in the plugin bundle
        if pluginBundle.path(forResource: "close", ofType: "pdf") != nil ||
           pluginBundle.path(forResource: "Assets", ofType: "car") != nil {
            return pluginBundle
        }
        
        // Try to find MapboxNavigation bundle (SPM or manual setup)
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


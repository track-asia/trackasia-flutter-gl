import CoreLocation
import Foundation
#if os(iOS)
import UIKit
#endif

#if os(iOS)
public extension UIDevice {
    /**
     Returns a `Bool` whether the device is plugged in. Returns false if not an iOS device.
     */
    @objc var isPluggedIn: Bool {
        return [.charging, .full].contains(UIDevice.current.batteryState)
    }
}
#else
// Mock UIDevice for macOS to help with compilation
public class UIDevice {
    public static let current = UIDevice()
    
    @objc public var isPluggedIn: Bool {
        return false
    }
}
#endif

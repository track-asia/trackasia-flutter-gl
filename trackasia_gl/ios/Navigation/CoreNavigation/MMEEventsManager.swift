import AVFoundation
import MapboxDirections
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

let SecondsBeforeCollectionAfterFeedbackEvent: TimeInterval = 20
let EventVersion = 8

#if os(iOS)
extension UIDevice {
    @nonobjc var machine: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { (identifier: String, element: Mirror.Child) in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
#elseif os(macOS)
// macOS equivalent functionality if needed
// For now just a placeholder struct to avoid compilation errors
struct DeviceInfo {
    static var machine: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        return machineMirror.children.reduce("") { (identifier: String, element: Mirror.Child) in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
    }
}
#endif

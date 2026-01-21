import Foundation
#if canImport(MapboxCoreNavigationObjC)
#endif
#if canImport(MapboxNavigationObjC)
#endif

// Swift fallback definitions when ObjC modules not available
#if !canImport(MapboxCoreNavigationObjC)
let MBErrorDomain = "ErrorDomain"
#endif

#if !canImport(MapboxNavigationObjC)
let MBSpokenInstructionErrorCodeKey = "MBSpokenInstructionErrorCode"
#endif

extension NSError {
    /**
     Creates a custom `Error` object.
     */
    convenience init(code: MBErrorCode, localizedFailureReason: String, spokenInstructionCode: SpokenInstructionErrorCode? = nil) {
        var userInfo = [
            NSLocalizedFailureReasonErrorKey: localizedFailureReason
        ]
        if let spokenInstructionCode {
            userInfo[MBSpokenInstructionErrorCodeKey] = String(spokenInstructionCode.rawValue)
        }
        self.init(domain: MBErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
}

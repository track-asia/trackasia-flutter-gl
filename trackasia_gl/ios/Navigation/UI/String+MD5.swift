import Foundation
import CommonCrypto

// MARK: - MD5 String Extension for Cache compatibility
extension String {
    func md5() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { buffer in
            CC_MD5(buffer.baseAddress, CC_UINT32_TRUNCATING(data.count), &digest)
        }
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}

// Helper macro for CC_MD5 unsigned int conversion
private func CC_UINT32_TRUNCATING(_ value: Int) -> CC_LONG {
    return CC_LONG(truncatingIfNeeded: value)
}

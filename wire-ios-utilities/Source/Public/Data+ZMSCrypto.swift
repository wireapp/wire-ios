//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import CommonCrypto
import CryptoKit
import Foundation

// MARK: - AESError

/// Advanced Encryption Standard errors
public enum AESError: Error {
    /// The key length is incorrect
    case keySizeError

    /// Encryption failed
    case encryptionFailed
}

// Mapping of @c NSData helper methods to Swift 3 @c Data. See original methods for description.
extension Data {
    public init?(hexString: String) {
        guard let decodedData = hexString.zmHexDecodedData() else {
            return nil
        }
        self = decodedData
    }

    public func zmMD5Digest() -> Data {
        var md5Hash = Insecure.MD5()

        // We may have a lot of data to hash, so compute in chunks of 512 bytes.
        for range in (startIndex ..< endIndex).chunked(by: 512) {
            md5Hash.update(data: self[range])
        }

        let digest = md5Hash.finalize()
        return Data(digest)
    }

    public func zmHMACSHA256Digest(key: Data) -> Data {
        (self as NSData).zmHMACSHA256Digest(withKey: key)
    }

    public func zmHexEncodedString() -> String {
        let hexDigits = Array("0123456789abcdef".utf16)
        var characters: [unichar] = []
        characters.reserveCapacity(count * 2)

        for byte in self {
            characters.append(hexDigits[Int(byte / 16)])
            characters.append(hexDigits[Int(byte % 16)])
        }

        return String(utf16CodeUnits: characters, count: characters.count)
    }

    public static func zmRandomSHA256Key() -> Data {
        NSData.zmRandomSHA256Key()
    }

    public func zmSHA256Digest() -> Data {
        (self as NSData).zmSHA256Digest()
    }

    public func base64String() -> String {
        (self as NSData).base64String()
    }

    public func zmEncryptPrefixingIV(key: Data) -> Data {
        (self as NSData).zmEncryptPrefixingIV(withKey: key)
    }

    public func zmDecryptPrefixedIV(key: Data) -> Data {
        (self as NSData).zmDecryptPrefixedIV(withKey: key)
    }

    public func zmEncryptPrefixingPlainTextIV(key: Data) throws -> Data {
        let keyLength = key.count
        guard keyLength == kCCKeySizeAES256 else {
            throw AESError.keySizeError
        }

        let dataLength = size_t(count + kCCBlockSizeAES128)
        var encryptedData = Data(count: dataLength)
        var copiedBytes: size_t = 0

        let ivSize = kCCBlockSizeAES128
        let iv = Data.secureRandomData(length: UInt(ivSize))

        let encryptedDataBytes = encryptedData.withUnsafeMutableBytes {
            $0.baseAddress
        }
        let status = CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            Array(key),
            keyLength,
            Array(iv),
            Array(self),
            count,
            encryptedDataBytes,
            encryptedData.count,
            &copiedBytes
        )

        guard status == kCCSuccess else {
            throw AESError.encryptionFailed
        }

        encryptedData.count = copiedBytes
        return iv + encryptedData
    }

    public func zmDecryptPrefixedPlainTextIV(key: Data) -> Data? {
        (self as NSData).zmDecryptPrefixedPlainTextIV(withKey: key)
    }

    public static func secureRandomData(length: UInt) -> Data {
        NSData.secureRandomData(ofLength: length)
    }

    public static func randomEncryptionKey() -> Data {
        NSData.randomEncryptionKey()
    }
}

extension Range where Index == Int {
    fileprivate func chunked(by chunkSize: Int) -> [Self] {
        guard chunkSize > 0 else { return [] }

        let numberOfWholeChunks = endIndex / chunkSize
        let numberOfChunks = endIndex.isMultiple(of: chunkSize) ? numberOfWholeChunks : numberOfWholeChunks + 1

        return (0 ..< numberOfChunks).map { chunkIndex in
            let start = chunkIndex * chunkSize
            let end = Swift.min(start + chunkSize, endIndex)
            return start ..< end
        }
    }
}

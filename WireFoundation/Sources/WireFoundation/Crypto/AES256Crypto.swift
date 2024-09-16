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
import Foundation

/// A namespace for AES256 cryptographic operations.

public enum AES256Crypto {


    /// Generate a random encryption key for AES256 cryptography.
    /// - Returns: A 32-byte key.

    public static func generateRandomEncryptionKey() throws -> Data {
        try SecureRandomByteGenerator.generateBytes(count: UInt(kCCKeySizeAES256))
    }

    /// Encrypt data all at once.
    ///
    /// The entire cryptographic operation will occur in memory, therefore
    /// this method should only be used with relatively small data.
    ///
    /// - Parameters:
    ///   - plaintext: The data to encrypt.
    ///   - key: The encryption key. It must be 32 bytes.
    ///
    /// - Returns: The encrypted ciphertext.

    public static func encryptAllAtOnce(
        plaintext: Data,
        key: Data
    ) throws -> Data {
        // Validate key.
        guard key.count == kCCKeySizeAES256 else {
            throw AES256CryptoError.invalidKeyLength
        }

        // Buffer for ciphertext with extra space for maximum
        // amount of padding that could be added.
        let ciphertextLength = plaintext.count + kCCBlockSizeAES128
        var ciphertext = Data(count: ciphertextLength)
        var totalBytesEncrypted: size_t = 0

        // Perform the encryption.
        let status = ciphertext.withUnsafeMutableBytes { ciphertextBytes in
            plaintext.withUnsafeBytes { plaintextBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),          // Encrypt
                        CCAlgorithm(kCCAlgorithmAES),     // AES
                        CCOptions(kCCOptionPKCS7Padding), // PKCS7 Padding
                        keyBytes.baseAddress,             // Key data
                        key.count,                        // Key length
                        nil,                              // No IV
                        plaintextBytes.baseAddress,       // Input data
                        plaintext.count,                  // Input length
                        ciphertextBytes.baseAddress,      // Output buffer
                        ciphertextLength,                 // Output buffer length
                        &totalBytesEncrypted              // Number of bytes written to output
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw AES256CryptoError.cryptorError(status)
        }

        // Strip the trailing white space.
        return ciphertext.prefix(totalBytesEncrypted)
    }

    /// Decrypt data all at once.
    ///
    /// The entire cryptographic operation will occur in memory, therefore
    /// this method should only be used with relatively small data.
    ///
    /// - Parameters:
    ///   - ciphertext: The data to decrypt.
    ///   - key: The decryption key. It must be 32 bytes.
    ///
    /// - Returns: The decrypted plaintext.

    public static func decryptAllAtOnce(
        ciphertext: Data,
        key: Data
    ) throws -> Data {
        // Validate key.
        guard key.count == kCCKeySizeAES256 else {
            throw AES256CryptoError.invalidKeyLength
        }

        // The max space needed for the plaintext is the same as the ciphertext
        // because any padding added to the ciphertext is stripped during decryption.
        let plaintextLength = ciphertext.count
        var plaintext = Data(count: plaintextLength)
        var totalBytesDecrypted: size_t = 0

        let status = plaintext.withUnsafeMutableBytes { plaintextBytes in
            ciphertext.withUnsafeBytes { ciphertextBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),          // Decrypt
                        CCAlgorithm(kCCAlgorithmAES),     // AES
                        CCOptions(kCCOptionPKCS7Padding), // PKCS7 Padding
                        keyBytes.baseAddress,             // Key
                        key.count,                        // Key length
                        nil,                              // No IV
                        ciphertextBytes.baseAddress,      // Input data
                        ciphertext.count,                 // Input length
                        plaintextBytes.baseAddress,       // Output buffer
                        plaintextLength,                  // Output buffer length
                        &totalBytesDecrypted              // Number of bytes written to output
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw AES256CryptoError.cryptorError(status)
        }

        // Strip the trailing white space.
        return plaintext.prefix(totalBytesDecrypted)
    }

}

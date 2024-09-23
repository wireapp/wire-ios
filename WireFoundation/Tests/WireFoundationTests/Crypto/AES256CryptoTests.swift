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
import XCTest

@testable import WireFoundation

final class AES256CryptoTests: XCTestCase {

    // Plain old encryption / decryption

    // AES operates on fixed-size blocks of data, which for AES is 128 bits (16 bytes).
    // Therefore we want to test encryption and decryption with data that is not a
    // mutliple of the block size and with data that is. This ensures we test correct
    // buffer allocation that accomodates potential padding and returning ciphertext
    // and plaintext that strips potential padding.

    func testEncryptionDecryption_DataNotMultipleOfBlockSize() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world")
        let key = try Scaffolding.randomKey()

        XCTAssertFalse(originalData.count.isMultiple(of: kCCBlockSizeAES128))

        // When
        let ciphertext = try AES256Crypto.encryptAllAtOnce(
            plaintext: originalData,
            key: key
        )

        // Then
        XCTAssertNotEqual(ciphertext, originalData)

        // When
        let plaintext = try AES256Crypto.decryptAllAtOnce(
            ciphertext: ciphertext,
            key: key
        )

        // Then
        XCTAssertEqual(plaintext, originalData)
    }

    func testEncryptionDecryption_DataIsMultipleOfBlockSize() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world!!!!")
        let key = try Scaffolding.randomKey()

        XCTAssertTrue(originalData.count.isMultiple(of: kCCBlockSizeAES128))

        // When
        let ciphertext = try AES256Crypto.encryptAllAtOnce(
            plaintext: originalData,
            key: key
        )

        // Then
        XCTAssertNotEqual(ciphertext, originalData)

        // When
        let plaintext = try AES256Crypto.decryptAllAtOnce(
            ciphertext: ciphertext,
            key: key
        )

        // Then
        XCTAssertEqual(plaintext, originalData)
    }

    func testEncryptionDecryption_ChangedCiphertext() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world")
        let key = try Scaffolding.randomKey()

        // When
        let ciphertext = try AES256Crypto.encryptAllAtOnce(
            plaintext: originalData,
            key: key
        )

        // Then
        XCTAssertNotEqual(ciphertext, originalData)

        // When
        let changedCiphertext = ciphertext + Data([1])
        let plaintext = try AES256Crypto.decryptAllAtOnce(
            ciphertext: changedCiphertext,
            key: key
        )

        // Then
        XCTAssertNotEqual(plaintext, originalData)
    }

    // MARK: - Prefixed IV

    func testEncryptDecryptWithPrefixedIV() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world")
        let key = try Scaffolding.randomKey()

        // When
        let ciphertext = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
            plaintext: originalData,
            key: key
        )

        // Then
        XCTAssertNotEqual(ciphertext.data, originalData)

        // When
        let plaintext = try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
            ciphertext: ciphertext,
            key: key
        )

        // Then
        XCTAssertEqual(plaintext, originalData)
    }

    func testEncryptWithPrefixedIV_IVIsRandomlyGenerated() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world")
        let key = try Scaffolding.randomKey()

        // When
        let ciphertext1 = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
            plaintext: originalData,
            key: key
        )

        let ciphertext2 = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
            plaintext: originalData,
            key: key
        )

        // Then
        XCTAssertNotEqual(ciphertext1.data, ciphertext2.data)
    }

    func testEncryptWithPrefixIV_DecryptWithoutPrefixedIV() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world")
        let key = try Scaffolding.randomKey()

        let ciphertext = try AES256Crypto.encryptAllAtOnceWithPrefixedIV(
            plaintext: originalData,
            key: key
        )

        // When
        let invalidPlaintext = try AES256Crypto.decryptAllAtOnce(
            ciphertext: ciphertext.data,
            key: key
        )

        let validPlaintext = try AES256Crypto.decryptAllAtOnceWithPrefixedIV(
            ciphertext: ciphertext,
            key: key
        )

        // Then
        XCTAssertNotEqual(invalidPlaintext, originalData)
        XCTAssertEqual(validPlaintext, originalData)
    }

    // MARK: - Keys

    func testKeyGeneration() throws {
        // When
        let key = try AES256Crypto.generateRandomEncryptionKey()

        // Then
        XCTAssertEqual(key.count, 32)
    }

    func testEncryption_InvalidKey() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world")
        let key = try Scaffolding.randomInvalidKey()

        do {
            // When
            _ = try AES256Crypto.encryptAllAtOnce(
                plaintext: originalData,
                key: key
            )

            XCTFail("expected an error")

        } catch AES256CryptoError.invalidKeyLength {
            // Then
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

    func testDecryption_InvalidKey() throws {
        // Given
        let originalData = Scaffolding.originalData(from: "Hello, world")
        let key = try Scaffolding.randomInvalidKey()

        do {
            // When
            _ = try AES256Crypto.decryptAllAtOnce(
                ciphertext: originalData,
                key: key
            )

            XCTFail("expected an error")

        } catch AES256CryptoError.invalidKeyLength {
            // Then
        } catch {
            XCTFail("unexpected error: \(error)")
        }
    }

}

private enum Scaffolding {

    static func originalData(from message: String) -> Data {
        message.data(using: .utf8)!
    }

    static func randomKey() throws -> Data {
        try SecureRandomByteGenerator.generateBytes(count: 32)
    }

    static func randomInvalidKey() throws -> Data {
        try Data(randomKey().dropLast())
    }

}

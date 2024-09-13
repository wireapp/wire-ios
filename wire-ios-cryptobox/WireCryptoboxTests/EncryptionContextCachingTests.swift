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

import XCTest
@testable import WireCryptobox

let someTextToEncrypt = "ENCRYPT THIS!"

class DebugEncryptor: Encryptor {
    var index = 0
    func encrypt(_ plainText: Data, for recipientIdentifier: EncryptionSessionIdentifier) throws -> Data {
        var result = plainText
        result.append(recipientIdentifier.rawValue.data(using: .utf8)!)
        result.append(Data("\(index)".utf8))
        index += 1
        return result
    }
}

class EncryptionContextCachingTests: XCTestCase {
    func testThatItDoesNotCachePerDefault() {
        // GIVEN
        let tempDir = createTempFolder()
        let mainContext = EncryptionContext(path: tempDir)

        let expectation = expectation(description: "Encryption succeeded")

        // WHEN
        mainContext.perform { sessionContext in
            try! sessionContext.createClientSession(hardcodedClientId, base64PreKeyString: hardcodedPrekey)

            let encryptedDataNonCachedFirst  = try! sessionContext.encrypt(
                someTextToEncrypt.data(using: .utf8)!,
                for: hardcodedClientId
            )
            let encryptedDataNonCachedSecond = try! sessionContext.encrypt(
                someTextToEncrypt.data(using: .utf8)!,
                for: hardcodedClientId
            )

            XCTAssertNotEqual(encryptedDataNonCachedFirst, encryptedDataNonCachedSecond)

            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 0) { _ in }
    }

    func testThatItCachesWhenRequested() {
        // GIVEN
        let tempDir = createTempFolder()
        let mainContext = EncryptionContext(path: tempDir)

        let expectation = expectation(description: "Encryption succeeded")

        // WHEN
        mainContext.perform { sessionContext in
            try! sessionContext.createClientSession(hardcodedClientId, base64PreKeyString: hardcodedPrekey)

            let encryptedDataFirst  = try! sessionContext.encryptCaching(
                someTextToEncrypt.data(using: .utf8)!,
                for: hardcodedClientId
            )
            let encryptedDataSecond = try! sessionContext.encryptCaching(
                someTextToEncrypt.data(using: .utf8)!,
                for: hardcodedClientId
            )

            XCTAssertEqual(encryptedDataFirst, encryptedDataSecond)

            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 0) { _ in }
    }

    func testThatCacheKeyDependsOnData() {
        // GIVEN
        let tempDir = createTempFolder()
        let mainContext = EncryptionContext(path: tempDir)

        let expectation = expectation(description: "Encryption succeeded")

        // WHEN
        mainContext.perform { sessionContext in
            try! sessionContext.createClientSession(hardcodedClientId, base64PreKeyString: hardcodedPrekey)

            let encryptedDataFirst  = try! sessionContext.encryptCaching(
                someTextToEncrypt.data(using: .utf8)!,
                for: hardcodedClientId
            )
            let encryptedDataSecond = try! sessionContext.encryptCaching(
                someTextToEncrypt.appending(someTextToEncrypt).data(using: .utf8)!,
                for: hardcodedClientId
            )

            XCTAssertNotEqual(encryptedDataFirst, encryptedDataSecond)

            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 0) { _ in }
    }

    func testThatItFlushesTheCache() {
        // GIVEN
        let tempDir = createTempFolder()
        let mainContext = EncryptionContext(path: tempDir)

        let expectation = expectation(description: "Encryption succeeded")

        // WHEN
        mainContext.perform { sessionContext in
            try! sessionContext.createClientSession(hardcodedClientId, base64PreKeyString: hardcodedPrekey)

            let encryptedDataFirst  = try! sessionContext.encryptCaching(
                someTextToEncrypt.data(using: .utf8)!,
                for: hardcodedClientId
            )
            sessionContext.purgeEncryptedPayloadCache()
            let encryptedDataSecond = try! sessionContext.encryptCaching(
                someTextToEncrypt.data(using: .utf8)!,
                for: hardcodedClientId
            )

            XCTAssertNotEqual(encryptedDataFirst, encryptedDataSecond)

            expectation.fulfill()
        }

        // THEN
        waitForExpectations(timeout: 0) { _ in }
    }
}

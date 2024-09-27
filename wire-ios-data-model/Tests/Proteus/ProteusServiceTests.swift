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

import Foundation
import WireCoreCrypto
import XCTest
@testable import WireDataModel
@testable import WireDataModelSupport

class ProteusServiceTests: XCTestCase {
    struct MockError: Error, Equatable {}

    var mockCoreCrypto: MockCoreCryptoProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var sut: ProteusService!

    // MARK: - Set up

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockCoreCrypto.proteusInit_MockMethod = {}
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        sut = ProteusService(coreCryptoProvider: mockCoreCryptoProvider)
    }

    override func tearDown() {
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Decrypting messages

    func test_DecryptDataForSession_SessionExists() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let encryptedData = Data.secureRandomData(length: 8)

        // Mock
        mockCoreCrypto.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return true
        }

        mockCoreCrypto.proteusDecryptSessionIdCiphertext_MockMethod = { id, ciphertext in
            XCTAssertEqual(id, sessionID.rawValue)
            XCTAssertEqual(ciphertext, encryptedData)
            return Data([0, 1, 2, 3, 4, 5])
        }

        // When
        let (didCreateNewSession, decryptedData) = try await sut.decrypt(
            data: encryptedData,
            forSession: sessionID
        )

        // Then
        XCTAssertFalse(didCreateNewSession)
        XCTAssertEqual(decryptedData, Data([0, 1, 2, 3, 4, 5]))
    }

    func test_DecryptDataForSession_SessionExists_Failure() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let encryptedData = Data.secureRandomData(length: 8)

        // Mock
        mockCoreCrypto.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return true
        }

        mockCoreCrypto.proteusLastErrorCode_MockMethod = {
            209
        }

        mockCoreCrypto.proteusDecryptSessionIdCiphertext_MockMethod = { _, _ in
            throw MockError()
        }

        // Then
        await assertItThrows(error: ProteusService.DecryptionError.failedToDecryptData(.duplicateMessage)) {
            // When
            _ = try await sut.decrypt(
                data: encryptedData,
                forSession: sessionID
            )
        }
    }

    func test_DecryptDataForSession_SessionDoesNotExist() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let encryptedData = Data.secureRandomData(length: 8)

        // Mock
        mockCoreCrypto.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return false
        }

        mockCoreCrypto.proteusSessionFromMessageSessionIdEnvelope_MockMethod = { id, ciphertext in
            XCTAssertEqual(id, sessionID.rawValue)
            XCTAssertEqual(ciphertext, encryptedData)
            return Data([0, 1, 2, 3, 4, 5])
        }

        // When
        let (didCreateNewSession, decryptedData) = try await sut.decrypt(
            data: encryptedData,
            forSession: sessionID
        )

        // Then
        XCTAssertTrue(didCreateNewSession)
        XCTAssertEqual(decryptedData, Data([0, 1, 2, 3, 4, 5]))
    }

    func test_DecryptDataForSession_SessionDoesNotExist_Failure() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let encryptedData = Data.secureRandomData(length: 8)

        // Mock
        mockCoreCrypto.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return false
        }

        mockCoreCrypto.proteusLastErrorCode_MockMethod = {
            209
        }

        mockCoreCrypto.proteusSessionFromMessageSessionIdEnvelope_MockMethod = { _, _ in
            throw MockError()
        }

        // Then
        await assertItThrows(
            error: ProteusService.DecryptionError
                .failedToEstablishSessionFromMessage(.duplicateMessage)
        ) {
            // When
            _ = try await sut.decrypt(
                data: encryptedData,
                forSession: sessionID
            )
        }
    }

    // MARK: - Encrypting messages

    func test_EncryptDataForSession_Success() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let plaintext = Data.secureRandomData(length: 8)

        // Mock
        var encryptCalls = 0
        mockCoreCrypto.proteusEncryptSessionIdPlaintext_MockMethod = { sessionIDString, plaintextData in
            encryptCalls += 1
            XCTAssertEqual(sessionIDString, sessionID.rawValue)
            XCTAssertEqual(plaintextData, plaintext)
            return Data([1, 2, 3, 4, 5])
        }

        // When
        let encryptedData = try await sut.encrypt(
            data: plaintext,
            forSession: sessionID
        )

        // Then
        XCTAssertEqual(encryptCalls, 1)
        XCTAssertEqual(encryptedData, Data([1, 2, 3, 4, 5]))
    }

    func test_EncryptDataForSession_Fail() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let plaintext = Data.secureRandomData(length: 8)

        let error = MockError()
        // Mock
        var encryptCalls = 0
        mockCoreCrypto.proteusEncryptSessionIdPlaintext_MockMethod = { sessionIDString, plaintextData in
            encryptCalls += 1
            XCTAssertEqual(sessionIDString, sessionID.rawValue)
            XCTAssertEqual(plaintextData, plaintext)
            throw error
        }

        // Then
        await assertItThrows(error: ProteusService.EncryptionError.failedToEncryptData(error)) {
            // When
            _ = try await sut.encrypt(
                data: plaintext,
                forSession: sessionID
            )
        }

        XCTAssertEqual(encryptCalls, 1)
    }

    // MARK: - Session deletion

    func test_DeleteSession_Success() async throws {
        // Given
        let sessionID = ProteusSessionID.random()

        // Mock
        var sessionDeleteCalls = [String]()
        mockCoreCrypto.proteusSessionDeleteSessionId_MockMethod = {
            sessionDeleteCalls.append($0)
        }

        // When
        try await sut.deleteSession(id: sessionID)

        // Then
        XCTAssertEqual(sessionDeleteCalls, [sessionID.rawValue])
    }

    func test_DeleteSession_Failure() async throws {
        // Given
        let sessionID = ProteusSessionID.random()

        // Mock
        mockCoreCrypto.proteusSessionDeleteSessionId_MockMethod = { _ in
            throw MockError()
        }

        // Then
        await assertItThrows(error: ProteusService.DeleteSessionError.failedToDeleteSession) {
            // When
            try await sut.deleteSession(id: sessionID)
        }
    }
}

// MARK: - Helpers

extension ProteusSessionID {
    fileprivate static func random() -> Self {
        ProteusSessionID(
            domain: .randomDomain(),
            userID: UUID.create().uuidString,
            clientID: .randomAlphanumerical(length: 6)
        )
    }
}

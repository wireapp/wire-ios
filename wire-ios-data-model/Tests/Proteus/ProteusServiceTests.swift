//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

    var mockCoreCryptoContext: MockCoreCryptoContextProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var sut: ProteusService!

    // MARK: - Set up

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockCoreCryptoContext = MockCoreCryptoContextProtocol()
        mockCoreCryptoContext.proteusInit_MockMethod = {}
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCryptoContext: mockCoreCryptoContext)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        sut = ProteusService(coreCryptoProvider: mockCoreCryptoProvider)
    }

    override func tearDown() {
        mockCoreCryptoContext = nil
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
        mockCoreCryptoContext.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return true
        }

        mockCoreCryptoContext.proteusDecryptSessionIdCiphertext_MockMethod = { id, ciphertext in
            XCTAssertEqual(id, sessionID.rawValue)
            XCTAssertEqual(ciphertext, encryptedData)
            return Data([0, 1, 2, 3, 4, 5])
        }

        // When
        let (didCreateNewSession, decryptedData) = try await sut.decrypt(
            data: encryptedData,
            forSession: sessionID,
            context: nil
        )

        // Then
        XCTAssertFalse(didCreateNewSession)
        XCTAssertEqual(decryptedData, Data([0, 1, 2, 3, 4, 5]))
        XCTAssertEqual(mockSafeCoreCrypto.performAsyncCount, 1)
    }

    func test_DecryptDataForSession_SessionExists_Failure() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let encryptedData = Data.secureRandomData(length: 8)

        // Mock
        mockCoreCryptoContext.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return true
        }

        mockCoreCryptoContext.proteusDecryptSessionIdCiphertext_MockMethod = { _, _ in
            throw CoreCryptoError.Proteus(.DuplicateMessage)
        }

        // Then
        await assertItThrows {
            // When
            _ = try await sut.decrypt(
                data: encryptedData,
                forSession: sessionID,
                context: nil
            )
        } errorHandler: { error in
            // Then
            guard case ProteusService.DecryptionError.failedToDecryptData(.DuplicateMessage) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func test_DecryptDataForSession_SessionDoesNotExist() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let encryptedData = Data.secureRandomData(length: 8)

        // Mock
        mockCoreCryptoContext.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return false
        }

        mockCoreCryptoContext.proteusSessionFromMessageSessionIdEnvelope_MockMethod = { id, ciphertext in
            XCTAssertEqual(id, sessionID.rawValue)
            XCTAssertEqual(ciphertext, encryptedData)
            return Data([0, 1, 2, 3, 4, 5])
        }

        // When
        let (didCreateNewSession, decryptedData) = try await sut.decrypt(
            data: encryptedData,
            forSession: sessionID,
            context: nil
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
        mockCoreCryptoContext.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return false
        }

        mockCoreCryptoContext.proteusSessionFromMessageSessionIdEnvelope_MockMethod = { _, _ in
            throw CoreCryptoError.Proteus(.DuplicateMessage)
        }

        await assertItThrows {
            // When
            _ = try await sut.decrypt(
                data: encryptedData,
                forSession: sessionID,
                context: nil
            )
        } errorHandler: { error in
            // Then
            guard case ProteusService.DecryptionError
                .failedToEstablishSessionFromMessage(.DuplicateMessage) = error else {
                XCTFail("Unexpected error: \(error)")
                return
            }
        }
    }

    func test_DecryptDataForSession_TransactionIsNotCreatedWhenProvided() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let encryptedData = Data.secureRandomData(length: 8)

        // Mock
        mockCoreCryptoContext.proteusSessionExistsSessionId_MockMethod = { id in
            XCTAssertEqual(id, sessionID.rawValue)
            return true
        }

        mockCoreCryptoContext.proteusDecryptSessionIdCiphertext_MockMethod = { id, ciphertext in
            XCTAssertEqual(id, sessionID.rawValue)
            XCTAssertEqual(ciphertext, encryptedData)
            return Data([0, 1, 2, 3, 4, 5])
        }

        // When
        let (didCreateNewSession, decryptedData) = try await sut.decrypt(
            data: encryptedData,
            forSession: sessionID,
            context: mockCoreCryptoContext
        )

        // Then
        XCTAssertFalse(didCreateNewSession)
        XCTAssertEqual(decryptedData, Data([0, 1, 2, 3, 4, 5]))
        XCTAssertEqual(mockSafeCoreCrypto.performAsyncCount, 0)
    }

    // MARK: - Encrypting messages

    func test_EncryptDataForSession_Success() async throws {
        // Given
        let sessionID = ProteusSessionID.random()
        let plaintext = Data.secureRandomData(length: 8)

        // Mock
        var encryptCalls = 0
        mockCoreCryptoContext.proteusEncryptSessionIdPlaintext_MockMethod = { sessionIDString, plaintextData in
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
        mockCoreCryptoContext.proteusEncryptSessionIdPlaintext_MockMethod = { sessionIDString, plaintextData in
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
        mockCoreCryptoContext.proteusSessionDeleteSessionId_MockMethod = {
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
        mockCoreCryptoContext.proteusSessionDeleteSessionId_MockMethod = { _ in
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

private extension ProteusSessionID {

    static func random() -> Self {
        ProteusSessionID(
            domain: .randomDomain(),
            userID: UUID.create().uuidString,
            clientID: .randomAlphanumerical(length: 6)
        )
    }

}

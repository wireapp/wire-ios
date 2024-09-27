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

final class MLSEncryptionServiceTests: XCTestCase {
    // MARK: - Message Encryption

    typealias EncryptionError = MLSEncryptionService.MLSMessageEncryptionError

    var sut: MLSEncryptionService!
    var mockCoreCrypto: MockCoreCryptoProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCrypto_MockValue = mockSafeCoreCrypto
        sut = MLSEncryptionService(coreCryptoProvider: mockCoreCryptoProvider)
    }

    override func tearDown() {
        sut = nil
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        super.tearDown()
    }

    func test_Encrypt_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let unencryptedMessage = Data.random()
        let encryptedMessage = Data.random()

        // Mock
        var mockEncryptMessageCount = 0
        mockCoreCrypto.encryptMessageConversationIdMessage_MockMethod = {
            mockEncryptMessageCount += 1
            XCTAssertEqual($0, groupID.data)
            XCTAssertEqual($1, unencryptedMessage)
            return encryptedMessage
        }

        // When
        let result = try await sut.encrypt(
            message: unencryptedMessage,
            for: groupID
        )

        // Then
        XCTAssertEqual(mockEncryptMessageCount, 1)
        XCTAssertEqual(result, encryptedMessage)
    }

    func test_Encrypt_Fails() async {
        // Given
        let groupID = MLSGroupID.random()
        let unencryptedMessage = Data.random()

        // Mock
        mockCoreCrypto.encryptMessageConversationIdMessage_MockMethod = { _, _ in
            throw CryptoError.InvalidByteArrayError(message: "invalid byte array error")
        }

        // Then
        await assertItThrows(error: EncryptionError.failedToEncryptMessage) {
            // Wnen
            _ = try await sut.encrypt(
                message: unencryptedMessage,
                for: groupID
            )
        }
    }
}

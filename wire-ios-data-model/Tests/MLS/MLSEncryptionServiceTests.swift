//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import XCTest
import WireCoreCrypto
@testable import WireDataModel
@testable import WireDataModelSupport

final class MLSEncryptionServiceTests: XCTestCase {

    var sut: MLSEncryptionService!
    var mockCoreCrypto: MockCoreCrypto!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCrypto()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCryptoRequireMLS_MockValue = mockSafeCoreCrypto
        sut = MLSEncryptionService(coreCryptoProvider: mockCoreCryptoProvider)
    }

    override func tearDown() {
        sut = nil
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        super.tearDown()
    }

    // MARK: - Message Encryption

    typealias EncryptionError = MLSEncryptionService.MLSMessageEncryptionError

    func test_Encrypt_IsSuccessful() {
        do {
            // Given
            let groupID = MLSGroupID.random()
            let unencryptedMessage = Data.random().bytes
            let encryptedMessage = Data.random().bytes

            // Mock
            var mockEncryptMessageCount = 0
            mockCoreCrypto.mockEncryptMessage = {
                mockEncryptMessageCount += 1
                XCTAssertEqual($0, groupID.bytes)
                XCTAssertEqual($1, unencryptedMessage)
                return encryptedMessage
            }

            // When
            let result = try sut.encrypt(
                message: unencryptedMessage,
                for: groupID
            )

            // Then
            XCTAssertEqual(mockEncryptMessageCount, 1)
            XCTAssertEqual(result, encryptedMessage)

        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }
    }

    func test_Encrypt_Fails() {
        // Given
        let groupID = MLSGroupID.random()
        let unencryptedMessage = Data.random().bytes

        // Mock
        mockCoreCrypto.mockEncryptMessage = { (_, _) in
            throw CryptoError.InvalidByteArrayError(message: "bad bytes!")
        }

        // Then
        assertItThrows(error: EncryptionError.failedToEncryptMessage) {
            // Wnen
            _ = try sut.encrypt(
                message: unencryptedMessage,
                for: groupID
            )
        }
    }

}

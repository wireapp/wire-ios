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
@testable import WireDataModel

final class ZMClientMessageTests_MLSEncryptedPayloadGenerator: BaseZMClientMessageTests {

    override func setUp() {
        DeveloperFlag.storage = UserDefaults(suiteName: UUID().uuidString)!
        var flag = DeveloperFlag.proteusViaCoreCrypto
        flag.isOn = true

        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        DeveloperFlag.storage = UserDefaults.standard
    }

    let encryptionFunction: (Data) throws -> Data = {
        $0.zmSHA256Digest()
    }

    func test_EncryptForTransport_GenericMessage() async throws {
        // Given
        let message = GenericMessage(content: Text(content: "Hello!"))

        // When
        let encryptedMessage = try await message.encryptForTransport(using: encryptionFunction)

        // Then
        let serializedMessage = try message.serializedData()
        let expectedEncryptedMessage = serializedMessage.zmSHA256Digest()
        XCTAssertEqual(encryptedMessage, expectedEncryptedMessage)
    }

    func test_EncryptForTransport_ClientMessage() async throws {
        // Given
        let message = await syncMOC.perform {
            try? self.syncConversation.appendText(content: "Hello!") as? ZMClientMessage
        }

        guard let message  else {
            return XCTFail("failed to create client message")
        }

        // When
        guard let encryptedMessage = try? await message.encryptForTransport(using: self.encryptionFunction) else {
            return XCTFail("failed to encrypt message")
        }

        await syncMOC.perform {
            // Then
            guard var genericMessage = message.underlyingMessage else {
                return XCTFail("failed to get generic message")
            }

            // When encrypting, the generic message is modified before sending.
            genericMessage.setLegalHoldStatus(.disabled)

            guard let serializedMessage = try? genericMessage.serializedData() else {
                return XCTFail("failed to serialize message")
            }

            let expectedEncryptedMessage = serializedMessage.zmSHA256Digest()
            XCTAssertEqual(encryptedMessage, expectedEncryptedMessage)
        }

    }

    func test_EncryptForTransport_AssetClientMessage() async throws {
        // Given
        let message = try await syncMOC.perform {
            try self.syncConversation.appendImage(from: self.verySmallJPEGData()) as? ZMAssetClientMessage
        }

        guard let message else {
            return XCTFail("failed to create client message")
        }

        // When
        let encryptedMessage = try await message.encryptForTransport(using: self.encryptionFunction)

        await syncMOC.perform {
            // Then
            guard var genericMessage = message.underlyingMessage else {
                return XCTFail("failed to get generic message")
            }

            // When encrypting, the generic message is modified before sending.
            genericMessage.setLegalHoldStatus(.disabled)

            guard let serializedMessage = try? genericMessage.serializedData() else {
                return XCTFail("failed to serialize message")
            }

            let expectedEncryptedMessage = serializedMessage.zmSHA256Digest()
            XCTAssertEqual(encryptedMessage, expectedEncryptedMessage)
        }

    }

}

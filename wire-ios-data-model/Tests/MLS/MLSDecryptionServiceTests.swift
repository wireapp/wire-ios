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

import Combine
import Foundation
import WireCoreCrypto
import WireTesting
import XCTest

@testable import WireDataModel
@testable import WireDataModelSupport

final class MLSDecryptionServiceTests: ZMConversationTestsBase {

    var sut: MLSDecryptionService!
    var mockMLSActionExecutor: MockMLSActionExecutor!
    var mockSubconversationGroupIDRepository: MockSubconversationGroupIDRepositoryInterface!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockMLSActionExecutor = MockMLSActionExecutor()
        mockSubconversationGroupIDRepository = MockSubconversationGroupIDRepositoryInterface()

        sut = MLSDecryptionService(
            context: syncMOC,
            mlsActionExecutor: mockMLSActionExecutor,
            subconversationGroupIDRepository: mockSubconversationGroupIDRepository
        )
    }

    override func tearDown() {
        sut = nil
        mockMLSActionExecutor = nil
        mockSubconversationGroupIDRepository = nil
        super.tearDown()
    }

    func mockDecryptedMessage(
        plaintext: Data = .random(byteCount: 1),
        senderClientId: ClientId? = nil
    ) throws -> DecryptedMessage {
        let senderClientId = try senderClientId ?? ClientId(
            userId: Uuid(uuid: UUID().uuidString),
            deviceId: DeviceId(id: 1),
            domain: "wire.com"
        )
        return DecryptedMessage.text(
            plaintext: plaintext,
            senderClientId: senderClientId,
            identity: .withBasicCredentials()
        )
    }

    func mockBufferedDecryptedMessage(
        plaintext: Data = .random(byteCount: 1),
        senderClientId: ClientId? = nil
    ) throws -> DecryptedMessage {
        let senderClientId = try senderClientId ?? ClientId(
            userId: Uuid(uuid: UUID().uuidString),
            deviceId: DeviceId(id: 1),
            domain: "wire.com"
        )
        let identity = WireIdentity.withBasicCredentials()
        let bufferedMessage = BufferedDecryptedMessage.text(
            plaintext: plaintext,
            senderClientId: senderClientId,
            identity: identity
        )
        return .commit(
            isActive: true,
            bufferedMessages: [bufferedMessage],
            identity: identity
        )
    }

    // MARK: - Message Decryption

    typealias DecryptionError = MLSDecryptionService.MLSMessageDecryptionError

    func test_Decrypt_ThrowsFailedToConvertMessageToBytes() async {
        // Given
        let groupID = MLSGroupID.random()
        let invalidBase64String = "%"

        // Then
        await assertItThrows(error: DecryptionError.failedToConvertMessageToBytes) {
            // When
            try _ = await sut.decrypt(
                message: invalidBase64String,
                for: groupID,
                subconversationType: nil,
                context: nil
            )
        }
    }

    func test_Decrypt_ThrowsFailedToDecryptMessage() async {
        // Given
        let groupID = MLSGroupID.random()
        let message = Data.random().base64EncodedString()
        let error = CoreCryptoError.Other(msg: "conversation not found")

        mockMLSActionExecutor.mockDecryptMessage = { _, _ in
            throw error
        }

        // Then
        await assertItThrows(error: DecryptionError.failedToDecryptMessage(reason: error)) {
            // When
            try _ = await sut.decrypt(
                message: message,
                for: groupID,
                subconversationType: nil,
                context: nil
            )
        }
    }

    func test_Decrypt_IgnoreOtherMissingCommitProposalError() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let message = Data.random().base64EncodedString()

        mockMLSActionExecutor.mockDecryptMessage = { _, _ in
            throw CoreCryptoError
                .Mls(
                    mlsError: MlsError
                        .Other(
                            msg: "Incoming message is a commit for which we have not yet received all the proposals. Buffering until all proposals have arrived."
                        )
                )
        }

        // When
        let results = try await sut.decrypt(
            message: message,
            for: groupID,
            subconversationType: nil,
            context: nil
        )

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    func test_Decrypt_ReturnsEmptyResult_WhenCoreCryptoReturnsCommitWithNoBufferedMessages() async throws {

        // Given
        let groupID = MLSGroupID.random()
        let messageBytes = [UInt8](Data.random())
        let decryptedMessage = DecryptedMessage.commit(
            isActive: true,
            bufferedMessages: [],
            identity: .withBasicCredentials()
        )
        mockMLSActionExecutor.mockDecryptMessage = { _, _ in
            decryptedMessage
        }

        // When
        let results = try await sut.decrypt(
            message: Data(messageBytes).base64EncodedString(),
            for: groupID,
            subconversationType: nil,
            context: nil
        )

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    func test_Decrypt_IsSuccessful() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let messageData = Data.random()
        let sender = MLSClientID.random()
        let decryptedMessage = try mockDecryptedMessage(
            plaintext: messageData,
            senderClientId: sender.cryptoId()
        )

        var mockDecryptMessageCount = 0
        mockMLSActionExecutor.mockDecryptMessage = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, messageData)
            XCTAssertEqual($1, groupID)
            return decryptedMessage
        }

        // When
        let results = try await sut.decrypt(
            message: messageData.base64EncodedString(),
            for: groupID,
            subconversationType: nil,
            context: nil
        )

        // Then
        XCTAssertEqual(mockDecryptMessageCount, 1)
        XCTAssertEqual(results.first, MLSDecryptResult.message(messageData, sender.clientID))
    }

    func test_Decrypt_ForSubconversation_IsSuccessful() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let messageData = Data.random()
        let sender = MLSClientID.random()
        let decryptedMessage = try mockDecryptedMessage(
            plaintext: messageData,
            senderClientId: sender.cryptoId()
        )

        mockSubconversationGroupIDRepository
            .fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        var mockDecryptMessageCount = 0
        mockMLSActionExecutor.mockDecryptMessage = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, messageData)
            XCTAssertEqual($1, subconversationGroupID)

            return decryptedMessage
        }

        // When
        let results = try await sut.decrypt(
            message: messageData.base64EncodedString(),
            for: parentGroupID,
            subconversationType: .conference,
            context: nil
        )

        // Then
        XCTAssertEqual(mockDecryptMessageCount, 1)
        XCTAssertEqual(results.first, MLSDecryptResult.message(messageData, sender.clientID))

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
    }

    func test_Decrypt_ReturnsAnEmptyMessageForBufferedDecryptedMessageError() async throws {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let messageData = Data.random()

        mockSubconversationGroupIDRepository
            .fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        mockMLSActionExecutor.mockDecryptMessage = { _, _ in
            throw MLSActionExecutor.Failure.bufferedDecryptedMessage
        }

        // When
        let results = try await sut.decrypt(
            message: messageData.base64EncodedString(),
            for: parentGroupID,
            subconversationType: .conference,
            context: nil
        )

        // Then
        XCTAssertEqual(results, [])

        XCTAssertEqual(
            mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_Invocations.count,
            1
        )
    }

    func test_Decrypt_ReturnsBufferedMessages() async throws {
        // Given
        let groupID = MLSGroupID.random()
        let messageData = Data.random()
        let sender = MLSClientID.random()
        let decryptedMessage = try mockBufferedDecryptedMessage(
            plaintext: messageData,
            senderClientId: sender.cryptoId()
        )

        var mockDecryptMessageCount = 0
        mockMLSActionExecutor.mockDecryptMessage = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, messageData)
            XCTAssertEqual($1, groupID)

            return decryptedMessage
        }

        // When
        let results = try await sut.decrypt(
            message: messageData.base64EncodedString(),
            for: groupID,
            subconversationType: nil,
            context: nil
        )

        // Then
        XCTAssertEqual(mockDecryptMessageCount, 1)
        XCTAssertEqual(results.first, MLSDecryptResult.message(messageData, sender.clientID))
    }
}

extension WireIdentity {

    static func withBasicCredentials() -> Self {
        .init(
            clientId: ClientId(
                userId: try! Uuid(uuid: UUID().transportString()),
                deviceId: try! DeviceId.fromHexString(hexString: "a68a96d1cc3941ab"),
                domain: "wire.com"
            ),
            status: .valid,
            thumbprint: "",
            credentialType: .basic,
            x509Identity: nil
        )
    }
}

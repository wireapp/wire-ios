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
        let error = CoreCryptoError.Other("conversation not found")

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
                    MlsError
                        .Other(
                            "Incoming message is a commit for which we have not yet received all the proposals. Buffering until all proposals have arrived."
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

    func test_Decrypt_ReturnsEmptyResult_WhenCoreCryptoReturnsNil() async throws {

        // Given
        let groupID = MLSGroupID.random()
        let messageBytes = [UInt8](Data.random())
        mockMLSActionExecutor.mockDecryptMessage = { _, _ in
            DecryptedMessage(
                message: nil,
                isActive: false,
                commitDelay: nil,
                senderClientId: nil,
                hasEpochChanged: false,
                identity: .withBasicCredentials(),
                bufferedMessages: nil,
                crlNewDistributionPoints: nil
            )
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
        let sender = MLSClientID(
            userID: UUID.create().transportString(),
            clientID: "client",
            domain: "example.com"
        )

        var mockDecryptMessageCount = 0
        mockMLSActionExecutor.mockDecryptMessage = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, messageData)
            XCTAssertEqual($1, groupID)
            return DecryptedMessage(
                message: messageData,
                isActive: false,
                commitDelay: nil,
                senderClientId: WireCoreCryptoUniffi.ClientId(bytes: sender.rawValue.data(using: .utf8)!),
                hasEpochChanged: false,
                identity: .withBasicCredentials(),
                bufferedMessages: nil,
                crlNewDistributionPoints: nil
            )
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

        mockSubconversationGroupIDRepository
            .fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        var mockDecryptMessageCount = 0
        mockMLSActionExecutor.mockDecryptMessage = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, messageData)
            XCTAssertEqual($1, subconversationGroupID)

            return DecryptedMessage(
                message: messageData,
                isActive: false,
                commitDelay: nil,
                senderClientId: WireCoreCryptoUniffi.ClientId(bytes: sender.rawValue.data(using: .utf8)!),
                hasEpochChanged: false,
                identity: .withBasicCredentials(),
                bufferedMessages: nil,
                crlNewDistributionPoints: nil
            )
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
        let sender = MLSClientID(
            userID: UUID.create().transportString(),
            clientID: "client",
            domain: "example.com"
        )

        var mockDecryptMessageCount = 0
        mockMLSActionExecutor.mockDecryptMessage = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, messageData)
            XCTAssertEqual($1, groupID)

            return DecryptedMessage(
                message: nil,
                isActive: false,
                commitDelay: nil,
                senderClientId: nil,
                hasEpochChanged: false,
                identity: .withBasicCredentials(),
                bufferedMessages: [
                    BufferedDecryptedMessage(
                        message: messageData,
                        isActive: false,
                        commitDelay: nil,
                        senderClientId: WireCoreCryptoUniffi.ClientId(bytes: sender.rawValue.data(using: .utf8)!),
                        hasEpochChanged: false,
                        identity: .withBasicCredentials(),
                        crlNewDistributionPoints: nil
                    )
                ], crlNewDistributionPoints: nil
            )
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

    func test_Decrypt_PublishesNewDistributionPoints() async throws {
        // Given
        let distributionPoint = "example.domain.com"
        let messageData = Data.random()
        let sender = MLSClientID(
            userID: UUID.create().transportString(),
            clientID: "client",
            domain: "example.com"
        )
        let senderData = try XCTUnwrap(sender.rawValue.data(using: .utf8))

        // Mock message decryption
        mockMLSActionExecutor.mockDecryptMessage = { _, _ in
            DecryptedMessage(
                message: messageData,
                isActive: false,
                commitDelay: nil,
                senderClientId: WireCoreCryptoUniffi.ClientId(bytes: senderData),
                hasEpochChanged: false,
                identity: .withBasicCredentials(),
                bufferedMessages: nil,
                crlNewDistributionPoints: [distributionPoint]
            )
        }

        // Set expectation to receive new distribution points
        let expectation = XCTestExpectation(description: "received value")
        let cancellable = sut.onNewCRLsDistributionPoints().sink { value in
            XCTAssertEqual(value, CRLsDistributionPoints(from: [distributionPoint]))
            expectation.fulfill()
        }

        // When
        _ = try await sut.decrypt(
            message: messageData.base64EncodedString(),
            for: .random(),
            subconversationType: nil,
            context: nil
        )

        // Then
        await fulfillment(of: [expectation])
        cancellable.cancel()
    }
}

extension WireIdentity {

    static func withBasicCredentials() -> Self {
        .init(
            clientId: "",
            status: .valid,
            thumbprint: "",
            credentialType: .basic,
            x509Identity: nil
        )
    }
}

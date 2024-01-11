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
import Combine
import WireCoreCrypto
import WireTesting

@testable import WireDataModel
@testable import WireDataModelSupport

final class MLSDecryptionServiceTests: ZMConversationTestsBase {

    var sut: MLSDecryptionService!
    var mockCoreCrypto: MockCoreCryptoProtocol!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockCoreCryptoProvider: MockCoreCryptoProviderProtocol!
    var mockSubconversationGroupIDRepository: MockSubconversationGroupIDRepositoryInterface!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCryptoProtocol()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockCoreCryptoProvider = MockCoreCryptoProviderProtocol()
        mockCoreCryptoProvider.coreCryptoRequireMLS_MockValue = mockSafeCoreCrypto
        mockSubconversationGroupIDRepository = MockSubconversationGroupIDRepositoryInterface()

        sut = MLSDecryptionService(
            context: syncMOC,
            coreCryptoProvider: mockCoreCryptoProvider,
            subconversationGroupIDRepository: mockSubconversationGroupIDRepository
        )
    }

    override func tearDown() {
        sut = nil
        mockCoreCrypto = nil
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
                subconversationType: nil
            )
        }
    }

    func test_Decrypt_ThrowsFailedToDecryptMessage() async {
        // Given
        let groupID = MLSGroupID.random()
        let message = Data.random().base64EncodedString()
        self.mockCoreCrypto.decryptMessageConversationIdPayload_MockError = CryptoError.ConversationNotFound(message: "conversation not found")

        // Then
        await assertItThrows(error: DecryptionError.failedToDecryptMessage) {
            // When
            try _ = await sut.decrypt(
                message: message,
                for: groupID,
                subconversationType: nil
            )
        }
    }

    func test_Decrypt_ReturnsNil_WhenCoreCryptoReturnsNil() async {

        // Given
        let groupID = MLSGroupID.random()
        let messageBytes = Data.random().bytes
        self.mockCoreCrypto.decryptMessageConversationIdPayload_MockValue =
            DecryptedMessage(
                message: nil,
                proposals: [],
                isActive: false,
                commitDelay: nil,
                senderClientId: nil,
                hasEpochChanged: false,
                identity: nil,
                bufferedMessages: nil
            )

        // When
        var result: MLSDecryptResult?
        do {
            result = try await sut.decrypt(
                message: messageBytes.data.base64EncodedString(),
                for: groupID,
                subconversationType: nil
            )
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }

        // Then
        XCTAssertNil(result)
    }

    func test_Decrypt_IsSuccessful() async {
        // Given
        let groupID = MLSGroupID.random()
        let messageData = Data.random()
        let sender = MLSClientID(
            userID: UUID.create().transportString(),
            clientID: "client",
            domain: "example.com"
        )

        var mockDecryptMessageCount = 0
        self.mockCoreCrypto.decryptMessageConversationIdPayload_MockMethod = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, groupID.data)
            XCTAssertEqual($1, messageData)

            return DecryptedMessage(
                message: messageData,
                proposals: [],
                isActive: false,
                commitDelay: nil,
                senderClientId: sender.rawValue.data(using: .utf8)!,
                hasEpochChanged: false,
                identity: nil,
                bufferedMessages: nil
            )
        }

        // When
        var result: MLSDecryptResult?
        do {
            result = try await sut.decrypt(
                message: messageData.base64EncodedString(),
                for: groupID,
                subconversationType: nil
            )
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }

        // Then
        XCTAssertEqual(mockDecryptMessageCount, 1)
        XCTAssertEqual(result, MLSDecryptResult.message(messageData, sender.clientID))
    }

    func test_Decrypt_ForSubconversation_IsSuccessful() async {
        // Given
        let parentGroupID = MLSGroupID.random()
        let subconversationGroupID = MLSGroupID.random()
        let messageData = Data.random()
        let sender = MLSClientID.random()

        mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

        var mockDecryptMessageCount = 0
        self.mockCoreCrypto.decryptMessageConversationIdPayload_MockMethod = {
            mockDecryptMessageCount += 1

            XCTAssertEqual($0, subconversationGroupID.data)
            XCTAssertEqual($1, messageData)

            return DecryptedMessage(
                message: messageData,
                proposals: [],
                isActive: false,
                commitDelay: nil,
                senderClientId: sender.rawValue.data(using: .utf8)!,
                hasEpochChanged: false,
                identity: nil,
                bufferedMessages: nil
            )
        }

        // When
        var result: MLSDecryptResult?
        do {
            result = try await sut.decrypt(
                message: messageData.base64EncodedString(),
                for: parentGroupID,
                subconversationType: .conference
            )
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }

        // Then
        XCTAssertEqual(mockDecryptMessageCount, 1)
        XCTAssertEqual(result, MLSDecryptResult.message(messageData, sender.clientID))

        XCTAssertEqual(mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_Invocations.count, 1)
    }

    func test_Decrypt_ReportsEpochChanged() async {
        // Given
        let groupID = MLSGroupID.random()
        let messageData = Data.random()
        let hasEpochChanged = true
        let sender = MLSClientID(
            userID: UUID.create().transportString(),
            clientID: "client",
            domain: "example.com"
        )

        var receivedGroupIDs = [MLSGroupID]()
        let didReceiveGroupIDs = customExpectation(description: "didReceiveGroupIDs")
        let cancellable = sut.onEpochChanged().collect(1).sink {
            receivedGroupIDs = $0
            didReceiveGroupIDs.fulfill()
        }

        mockCoreCrypto.decryptMessageConversationIdPayload_MockMethod = { _, _ in
            return DecryptedMessage(
                message: messageData,
                proposals: [],
                isActive: false,
                commitDelay: nil,
                senderClientId: sender.rawValue.data(using: .utf8)!,
                hasEpochChanged: hasEpochChanged,
                identity: nil,
                bufferedMessages: nil
            )
        }

        // When
        do {
            _ = try await sut.decrypt(
                message: messageData.base64EncodedString(),
                for: groupID,
                subconversationType: nil
            )
        } catch {
            XCTFail("Unexpected error: \(String(describing: error))")
        }

        // Then
        XCTAssert(waitForCustomExpectations(withTimeout: 0.5))
        cancellable.cancel()
        XCTAssertEqual(receivedGroupIDs, [groupID])
    }

}

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

@testable import WireDataModel
@testable import WireDataModelSupport

final class MLSDecryptionServiceTests: ZMConversationTestsBase {

    var sut: MLSDecryptionService!
    var mockCoreCrypto: MockCoreCrypto!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var mockSubconversationGroupIDRepository: MockSubconversationGroupIDRepositoryInterface!

    // MARK: - Setup

    override func setUp() {
        super.setUp()
        mockCoreCrypto = MockCoreCrypto()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)
        mockSubconversationGroupIDRepository = MockSubconversationGroupIDRepositoryInterface()

        sut = MLSDecryptionService(
            context: syncMOC,
            coreCrypto: mockSafeCoreCrypto,
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

    func test_Decrypt_ThrowsFailedToConvertMessageToBytes() {
        syncMOC.performAndWait {
            // Given
            let groupID = MLSGroupID.random()
            let invalidBase64String = "%"

            // Then
            assertItThrows(error: DecryptionError.failedToConvertMessageToBytes) {
                // When
                try _ = sut.decrypt(
                    message: invalidBase64String,
                    for: groupID,
                    subconversationType: nil
                )
            }
        }
    }

    func test_Decrypt_ThrowsFailedToDecryptMessage() {
        syncMOC.performAndWait {
            // Given
            let groupID = MLSGroupID.random()
            let message = Data.random().base64EncodedString()
            self.mockCoreCrypto.mockDecryptMessage = { _, _ in
                throw CryptoError.ConversationNotFound(message: "conversation not found")
            }

            // Then
            assertItThrows(error: DecryptionError.failedToDecryptMessage) {
                // When
                try _ = sut.decrypt(
                    message: message,
                    for: groupID,
                    subconversationType: nil
                )
            }
        }
    }

    func test_Decrypt_ReturnsNil_WhenCoreCryptoReturnsNil() {
        syncMOC.performAndWait {
            // Given
            let groupID = MLSGroupID.random()
            let messageBytes = Data.random().bytes
            self.mockCoreCrypto.mockDecryptMessage = { _, _ in
                DecryptedMessage(
                    message: nil,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil,
                    senderClientId: nil,
                    hasEpochChanged: false,
                    identity: nil
                )
            }

            // When
            var result: MLSDecryptResult?
            do {
                result = try sut.decrypt(
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
    }

    func test_Decrypt_IsSuccessful() {
        syncMOC.performAndWait {
            // Given
            let groupID = MLSGroupID.random()
            let messageBytes = Data.random().bytes
            let sender = MLSClientID(
                userID: UUID.create().transportString(),
                clientID: "client",
                domain: "example.com"
            )

            var mockDecryptMessageCount = 0
            self.mockCoreCrypto.mockDecryptMessage = {
                mockDecryptMessageCount += 1

                XCTAssertEqual($0, groupID.bytes)
                XCTAssertEqual($1, messageBytes)

                return DecryptedMessage(
                    message: messageBytes,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil,
                    senderClientId: sender.rawValue.data(using: .utf8)!.bytes,
                    hasEpochChanged: false,
                    identity: nil
                )
            }

            // When
            var result: MLSDecryptResult?
            do {
                result = try sut.decrypt(
                    message: messageBytes.data.base64EncodedString(),
                    for: groupID,
                    subconversationType: nil
                )
            } catch {
                XCTFail("Unexpected error: \(String(describing: error))")
            }

            // Then
            XCTAssertEqual(mockDecryptMessageCount, 1)
            XCTAssertEqual(result, MLSDecryptResult.message(messageBytes.data, sender.clientID))
        }
    }

    func test_Decrypt_ForSubconversation_IsSuccessful() {
        syncMOC.performAndWait {
            // Given
            let parentGroupID = MLSGroupID.random()
            let subconversationGroupID = MLSGroupID.random()
            let messageBytes = Data.random().bytes
            let sender = MLSClientID.random()

            mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_MockValue = subconversationGroupID

            var mockDecryptMessageCount = 0
            self.mockCoreCrypto.mockDecryptMessage = {
                mockDecryptMessageCount += 1

                XCTAssertEqual($0, subconversationGroupID.bytes)
                XCTAssertEqual($1, messageBytes)

                return DecryptedMessage(
                    message: messageBytes,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil,
                    senderClientId: sender.rawValue.data(using: .utf8)!.bytes,
                    hasEpochChanged: false,
                    identity: nil
                )
            }

            // When
            var result: MLSDecryptResult?
            do {
                result = try sut.decrypt(
                    message: messageBytes.data.base64EncodedString(),
                    for: parentGroupID,
                    subconversationType: .conference
                )
            } catch {
                XCTFail("Unexpected error: \(String(describing: error))")
            }

            // Then
            XCTAssertEqual(mockDecryptMessageCount, 1)
            XCTAssertEqual(result, MLSDecryptResult.message(messageBytes.data, sender.clientID))

            XCTAssertEqual(mockSubconversationGroupIDRepository.fetchSubconversationGroupIDForTypeParentGroupID_Invocations.count, 1)
        }
    }

    func test_Decrypt_ReportsEpochChanged() {
        syncMOC.performAndWait {
            // Given
            let groupID = MLSGroupID.random()
            let messageBytes = Data.random().bytes
            let hasEpochChanged = true
            let sender = MLSClientID(
                userID: UUID.create().transportString(),
                clientID: "client",
                domain: "example.com"
            )

            var receivedGroupIDs = [MLSGroupID]()
            let didReceiveGroupIDs = expectation(description: "didReceiveGroupIDs")
            let cancellable = sut.onEpochChanged().collect(1).sink {
                receivedGroupIDs = $0
                didReceiveGroupIDs.fulfill()
            }

            mockCoreCrypto.mockDecryptMessage = { _, _ in
                return DecryptedMessage(
                    message: messageBytes,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil,
                    senderClientId: sender.rawValue.data(using: .utf8)!.bytes,
                    hasEpochChanged: hasEpochChanged,
                    identity: nil
                )
            }

            // When
            do {
                _ = try sut.decrypt(
                    message: messageBytes.data.base64EncodedString(),
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

}

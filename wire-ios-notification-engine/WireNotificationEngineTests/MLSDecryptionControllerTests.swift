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
import WireDataModel
import WireTesting
import CoreCryptoSwift
@testable import WireNotificationEngine

class MLSDecryptionControllerTests: BaseTest {

    var sut: MLSDecryptionController!
    var mockCoreCrypto: MockCoreCrypto!
    var mockSafeCoreCrypto: MockSafeCoreCrypto!
    var syncMOC: NSManagedObjectContext!

    let groupID = MLSGroupID([1, 2, 3])

    override func setUp() {
        super.setUp()

        syncMOC = coreDataStack.syncContext
        mockCoreCrypto = MockCoreCrypto()
        mockSafeCoreCrypto = MockSafeCoreCrypto(coreCrypto: mockCoreCrypto)

        sut = MLSDecryptionController(
            context: syncMOC,
            coreCrypto: mockSafeCoreCrypto
        )
    }

    override func tearDown() {
        sut = nil
        mockCoreCrypto = nil
        mockSafeCoreCrypto = nil
        syncMOC = nil
        super.tearDown()
    }

    // MARK: - Decryption

    typealias DecryptionError = MLSDecryptionController.MLSMessageDecryptionError

    func test_Decrypt_ThrowsFailedToConvertMessageToBytes() {
        syncMOC.performAndWait {
            // Given
            let invalidBase64String = "%"

            // When / Then
            assertItThrows(error: DecryptionError.failedToConvertMessageToBytes) {
                try _ = sut.decrypt(message: invalidBase64String, for: groupID)
            }
        }
    }

    func test_Decrypt_ThrowsFailedToDecryptMessage() {
        syncMOC.performAndWait {
            // Given
            let message = Data([1, 2, 3]).base64EncodedString()
            self.mockCoreCrypto.mockDecryptMessage = { _, _ in
                throw CryptoError.ConversationNotFound(message: "conversation not found")
            }

            // When / Then
            assertItThrows(error: DecryptionError.failedToDecryptMessage) {
                try _ = sut.decrypt(message: message, for: groupID)
            }
        }
    }

    func test_Decrypt_ReturnsNil_WhenCoreCryptoReturnsNil() {
        syncMOC.performAndWait {
            // Given
            let messageBytes: Bytes = [1, 2, 3]
            self.mockCoreCrypto.mockDecryptMessage = { _, _ in
                DecryptedMessage(
                    message: nil,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil,
                    senderClientId: nil,
                    hasEpochChanged: false
                )
            }

            // When
            var result: MLSDecryptResult?
            do {
                result = try sut.decrypt(message: messageBytes.data.base64EncodedString(), for: groupID)
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
            let messageBytes: Bytes = [1, 2, 3]
            let sender = MLSClientID(
                userID: UUID.create().transportString(),
                clientID: "client",
                domain: "example.com"
            )

            var mockDecryptMessageCount = 0
            self.mockCoreCrypto.mockDecryptMessage = {
                mockDecryptMessageCount += 1

                XCTAssertEqual($0, self.groupID.bytes)
                XCTAssertEqual($1, messageBytes)

                return DecryptedMessage(
                    message: messageBytes,
                    proposals: [],
                    isActive: false,
                    commitDelay: nil,
                    senderClientId: sender.string.data(using: .utf8)!.bytes,
                    hasEpochChanged: false
                )
            }

            // When
            var result: MLSDecryptResult?
            do {
                result = try sut.decrypt(message: messageBytes.data.base64EncodedString(), for: groupID)
            } catch {
                XCTFail("Unexpected error: \(String(describing: error))")
            }

            // Then
            XCTAssertEqual(mockDecryptMessageCount, 1)
            XCTAssertEqual(result, MLSDecryptResult.message(messageBytes.data, sender.clientID))
        }
    }

    // MARK: - Pending Proposals

    func test_SchedulePendingProposalCommit() throws {
        // Given
        let conversationID = UUID.create()
        let groupID = MLSGroupID([1, 2, 3])

        let conversation = ZMConversation.insertNewObject(in: syncMOC)
        conversation.conversationType = .group
        conversation.remoteIdentifier = conversationID
        conversation.mlsGroupID = groupID

        let commitDate = Date().addingTimeInterval(2)

        // When
        sut.scheduleCommitPendingProposals(groupID: groupID, at: commitDate)

        // Then
        conversation.commitPendingProposalDate = commitDate
    }

}

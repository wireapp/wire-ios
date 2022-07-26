// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
@testable import WireRequestStrategy

class MLSControllerMock: MLSControllerProtocol {

    var hasWelcomeMessageBeenProcessed = false

    func conversationExists(groupID: MLSGroupID) -> Bool {
        return hasWelcomeMessageBeenProcessed
    }

    var processedWelcomeMessage: String?
    var groupID: MLSGroupID?

    @discardableResult
    func processWelcomeMessage(welcomeMessage: String) throws -> MLSGroupID {
        processedWelcomeMessage = welcomeMessage
        return groupID ?? MLSGroupID(Data())
    }

    func uploadKeyPackagesIfNeeded() {

    }

    var createGroupCalls = [(MLSGroupID, [MLSUser])]()

    @available(iOS 15, *)
    func createGroup(for groupID: MLSGroupID, with users: [MLSUser]) async throws {
        createGroupCalls.append((groupID, users))
    }
}

class MLSEventProcessorTests: MessagingTestBase {

    var mlsControllerMock: MLSControllerMock!
    var conversation: ZMConversation!
    var domain = "example.com"
    let groupIdString = "identifier".data(using: .utf8)!.base64EncodedString()

    override func setUp() {
        super.setUp()
        syncMOC.performGroupedBlockAndWait {
            self.mlsControllerMock = MLSControllerMock()
            self.syncMOC.test_setMockMLSController(self.mlsControllerMock)
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.mlsGroupID = MLSGroupID(self.groupIdString.base64EncodedBytes!)
            self.conversation.domain = self.domain
            self.conversation.messageProtocol = .mls
        }
    }

    override func tearDown() {
        mlsControllerMock = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - Process Welcome Message

    func test_itProcessesMessageAndUpdatesConversation() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let message = "welcome message"
            self.mlsControllerMock.groupID = self.conversation.mlsGroupID

            // When
            MLSEventProcessor.shared.process(welcomeMessage: message, for: self.conversation, in: self.syncMOC)

            // Then
            XCTAssertEqual(message, self.mlsControllerMock.processedWelcomeMessage)
            XCTAssertFalse(self.conversation.isPendingWelcomeMessage)
        }
    }

    // MARK: - Update Conversation

    func test_itUpdates_GroupID() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.conversation.mlsGroupID = nil

            // When
            MLSEventProcessor.shared.updateConversationIfNeeded(
                conversation: self.conversation,
                groupID: self.groupIdString,
                context: self.syncMOC
            )

            // Then
            XCTAssertEqual(self.conversation.mlsGroupID?.bytes, self.groupIdString.base64EncodedBytes)
        }
    }

    func test_itUpdates_IsPendingWelcomeMessage_WhenProtocolIsMLS_AndWelcomeMessageWasProcessed() {
        assert_isPendingWelcomeMessage(
            originalValue: true,
            expectedValue: false,
            hasWelcomeMessageBeenProcessed: true,
            messageProtocol: .mls
        )
    }

    func test_itUpdates_IsPendingWelcomeMessage_WhenProtocolIsMLS_AndWelcomeMessageWasNotProcessed() {
        assert_isPendingWelcomeMessage(
            originalValue: false,
            expectedValue: true,
            hasWelcomeMessageBeenProcessed: false,
            messageProtocol: .mls
        )
    }

    func test_itDoesntUpdate_IsPendingWelcomeMessage_WhenProtocolIsNotMLS() {
        assert_isPendingWelcomeMessage(
            originalValue: true,
            expectedValue: true,
            hasWelcomeMessageBeenProcessed: true,
            messageProtocol: .proteus
        )
    }

    // MARK: - Helpers

    func assert_isPendingWelcomeMessage(
        originalValue: Bool,
        expectedValue: Bool,
        hasWelcomeMessageBeenProcessed: Bool,
        messageProtocol: MessageProtocol
    ) {
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.conversation.isPendingWelcomeMessage = originalValue
            self.conversation.messageProtocol = messageProtocol
            self.mlsControllerMock.hasWelcomeMessageBeenProcessed = hasWelcomeMessageBeenProcessed

            // When
            MLSEventProcessor.shared.updateConversationIfNeeded(
                conversation: self.conversation,
                groupID: self.groupIdString,
                context: self.syncMOC
            )

            // Then
            XCTAssertEqual(self.conversation.isPendingWelcomeMessage, expectedValue)
        }
    }
}

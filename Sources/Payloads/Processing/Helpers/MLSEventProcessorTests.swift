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

class MLSEventProcessorTests: MessagingTestBase {

    var mlsControllerMock: MockMLSController!
    var conversation: ZMConversation!
    var domain = "example.com"
    let groupIdString = "identifier".data(using: .utf8)!.base64EncodedString()

    override func setUp() {
        super.setUp()
        syncMOC.performGroupedBlockAndWait {
            self.mlsControllerMock = MockMLSController()
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
            self.conversation.mlsStatus = .pendingJoin
            XCTAssertEqual(self.conversation.mlsStatus, .pendingJoin)

            // When
            MLSEventProcessor.shared.process(welcomeMessage: message, in: self.syncMOC)

            // Then
            XCTAssertEqual(message, self.mlsControllerMock.processedWelcomeMessage)
            XCTAssertEqual(self.conversation.mlsStatus, .ready)
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

    func test_itUpdates_MlsStatus_WhenProtocolIsMLS_AndWelcomeMessageWasProcessed() {
        assert_mlsStatus(
            originalValue: .pendingJoin,
            expectedValue: .ready,
            mockMessageProtocol: .mls,
            mockHasWelcomeMessageBeenProcessed: true
        )
    }

    func test_itUpdates_MlsStatus_WhenProtocolIsMLS_AndWelcomeMessageWasNotProcessed() {
        assert_mlsStatus(
            originalValue: .ready,
            expectedValue: .pendingJoin,
            mockMessageProtocol: .mls,
            mockHasWelcomeMessageBeenProcessed: false
        )
    }

    func test_itDoesntUpdate_MlsStatus_WhenProtocolIsNotMLS() {
        assert_mlsStatus(
            originalValue: .pendingJoin,
            expectedValue: .pendingJoin,
            mockMessageProtocol: .proteus
        )
    }

    // MARK: - Joining new conversations

    func test_itAddsPendingGroupToGroupsPendingJoin() {
        syncMOC.performAndWait {
            // Given
            self.conversation.mlsStatus = .pendingJoin

            // When
            MLSEventProcessor.shared.joinMLSGroupWhenReady(
                forConversation: self.conversation,
                context: self.syncMOC
            )

            // Then
            XCTAssertEqual(self.mlsControllerMock.groupsPendingJoin.count, 1)
            XCTAssertEqual(self.mlsControllerMock.groupsPendingJoin.first, self.conversation.mlsGroupID)
        }
    }

    func test_itDoesntAddNotPendingGroupsToGroupsPendingJoin() {
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .ready)
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .pendingLeave)
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .outOfSync)
    }

    // MARK: - Helpers

    func test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus status: MLSGroupStatus) {
        syncMOC.performAndWait {
            // Given
            self.conversation.mlsStatus = status

            // When
            MLSEventProcessor.shared.joinMLSGroupWhenReady(
                forConversation: self.conversation,
                context: self.syncMOC
            )

            // Then
            XCTAssertTrue(self.mlsControllerMock.groupsPendingJoin.isEmpty)
        }
    }

    func assert_mlsStatus(
        originalValue: MLSGroupStatus,
        expectedValue: MLSGroupStatus,
        mockMessageProtocol: MessageProtocol,
        mockHasWelcomeMessageBeenProcessed: Bool = true
    ) {
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.conversation.mlsStatus = originalValue
            self.conversation.messageProtocol = mockMessageProtocol
            self.mlsControllerMock.hasWelcomeMessageBeenProcessed = mockHasWelcomeMessageBeenProcessed

            // When
            MLSEventProcessor.shared.updateConversationIfNeeded(
                conversation: self.conversation,
                groupID: self.groupIdString,
                context: self.syncMOC
            )

            // Then
            XCTAssertEqual(self.conversation.mlsStatus, expectedValue)
        }
    }
}

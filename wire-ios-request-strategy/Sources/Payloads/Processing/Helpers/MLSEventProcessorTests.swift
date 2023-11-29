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

    var mlsServiceMock: MockMLSService!
    var conversation: ZMConversation!
    var domain = "example.com"
    let groupIdString = "identifier".data(using: .utf8)!.base64EncodedString()

    override func setUp() {
        super.setUp()
        syncMOC.performGroupedBlockAndWait {
            self.mlsServiceMock = MockMLSService()
            self.syncMOC.mlsService = self.mlsServiceMock
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.mlsGroupID = MLSGroupID(self.groupIdString.base64DecodedBytes!)
            self.conversation.domain = self.domain
            self.conversation.messageProtocol = .mls
        }
    }

    override func tearDown() {
        mlsServiceMock = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - Process Welcome Message

    func test_itProcessesMessageAndUpdatesConversation() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let message = "welcome message"
            self.mlsServiceMock.groupID = self.conversation.mlsGroupID
            self.conversation.mlsStatus = .pendingJoin
            XCTAssertEqual(self.conversation.mlsStatus, .pendingJoin)

            // When
            MLSEventProcessor.shared.process(welcomeMessage: message, in: self.syncMOC)

            // Then
            XCTAssertEqual(message, self.mlsServiceMock.processedWelcomeMessage)
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
            XCTAssertEqual(self.conversation.mlsGroupID?.bytes, self.groupIdString.base64DecodedBytes)
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

    func test_itUpdates_MlsStatus_WhenProtocolIsMixed_AndWelcomeMessageWasProcessed() {
        assert_mlsStatus(
            originalValue: .pendingJoin,
            expectedValue: .ready,
            mockMessageProtocol: .mixed,
            mockHasWelcomeMessageBeenProcessed: true
        )
    }

    func test_itUpdates_MlsStatus_WhenProtocolIsMixed_AndWelcomeMessageWasNotProcessed() {
        assert_mlsStatus(
            originalValue: .ready,
            expectedValue: .pendingJoin,
            mockMessageProtocol: .mixed,
            mockHasWelcomeMessageBeenProcessed: false
        )
    }

    func test_itDoesntUpdate_MlsStatus_WhenProtocolIsProteus() {
        assert_mlsStatus(
            originalValue: .pendingJoin,
            expectedValue: .pendingJoin,
            mockMessageProtocol: .proteus
        )
    }

    // MARK: - Joining new conversations

    func test_itAddsPendingGroupToGroupsPendingJoin_WhenProtocolIsMixed() {
        internalTest_itAddsPendingGroupToGroupsPendingJoinWhenProtocol(.mixed)
    }

    func test_itAddsPendingGroupToGroupsPendingJoinWhenProtocolIsMLS() {
        internalTest_itAddsPendingGroupToGroupsPendingJoinWhenProtocol(.mls)
    }

    func internalTest_itAddsPendingGroupToGroupsPendingJoinWhenProtocol(_ messagingProtocol: MessageProtocol) {
        syncMOC.performAndWait {
            // Given
            self.conversation.messageProtocol = messagingProtocol
            self.conversation.mlsStatus = .pendingJoin

            // When
            MLSEventProcessor.shared.joinMLSGroupWhenReady(
                forConversation: self.conversation,
                context: self.syncMOC
            )

            // Then
            XCTAssertEqual(self.mlsServiceMock.groupsPendingJoin.count, 1)
            XCTAssertEqual(self.mlsServiceMock.groupsPendingJoin.first, self.conversation.mlsGroupID)
        }
    }

    func test_itDoesntAddNotPendingGroupsToGroupsPendingJoin() {
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .ready)
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .pendingLeave)
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .outOfSync)
    }

    // MARK: - Wiping group

    func test_itWipesGroupWithProtocolMLS() {
        internalTest_itWipesGroupWithProtocol(messageProtocol: .mls, shouldWipe: true)
    }

    func test_itWipesGroupWithProtocolMixed() {
        internalTest_itWipesGroupWithProtocol(messageProtocol: .mixed, shouldWipe: true)
    }

    func test_itDoesntWipeGroup_WhenProtocolIsProteus() {
        internalTest_itWipesGroupWithProtocol(messageProtocol: .proteus, shouldWipe: false)
    }

    func internalTest_itWipesGroupWithProtocol(messageProtocol: MessageProtocol, shouldWipe: Bool) {
        syncMOC.performAndWait {
            // Given
            let groupID = MLSGroupID(Data.random())
            conversation.messageProtocol = messageProtocol
            conversation.mlsGroupID = groupID

            // When
            MLSEventProcessor.shared.wipeMLSGroup(
                forConversation: conversation,
                context: syncMOC
            )

            // Then
            XCTAssertEqual(mlsServiceMock.calls.wipeGroup.count, shouldWipe ? 1 : 0)
            if shouldWipe {
                XCTAssertEqual(mlsServiceMock.calls.wipeGroup.first, groupID)
            }
        }
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
            XCTAssertTrue(self.mlsServiceMock.groupsPendingJoin.isEmpty)
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
            self.mlsServiceMock.hasWelcomeMessageBeenProcessed = mockHasWelcomeMessageBeenProcessed

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

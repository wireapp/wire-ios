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

    var sut: MLSEventProcessor!
    var mlsServiceMock: MockMLSService!
    var conversationServiceMock: MockConversationService!

    var conversation: ZMConversation!
    var qualifiedID: QualifiedID!
    let groupIdString = "identifier".data(using: .utf8)!.base64EncodedString()

    override func setUp() {
        super.setUp()

        qualifiedID = QualifiedID(uuid: .create(), domain: "example.com")

        syncMOC.performGroupedBlockAndWait {
            self.mlsServiceMock = MockMLSService()
            self.syncMOC.mlsService = self.mlsServiceMock
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.remoteIdentifier = self.qualifiedID.uuid
            self.conversation.mlsGroupID = MLSGroupID(self.groupIdString.base64DecodedBytes!)
            self.conversation.domain = self.qualifiedID.domain
            self.conversation.messageProtocol = .mls
        }

        conversationServiceMock = MockConversationService()
        sut = MLSEventProcessor(conversationService: conversationServiceMock)
    }

    override func tearDown() {
        mlsServiceMock = nil
        conversationServiceMock = nil
        conversation = nil
        qualifiedID = nil
        sut = nil
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
            self.sut.process(
                welcomeMessage: message,
                conversationID: self.qualifiedID,
                in: self.syncMOC
            )

            // Then
            XCTAssertEqual(message, self.mlsServiceMock.processedWelcomeMessage)
            XCTAssertEqual(self.conversation.mlsStatus, .ready)
            XCTAssertTrue(self.mlsServiceMock.uploadKeyPackesIfNeededCalled)
        }
    }

    func test_itProcessesMessage_ConversationDoesNotExist() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            let message = "welcome message"
            let mlsGroupID = MLSGroupID.random()
            let qualifiedID = QualifiedID.random()
            self.mlsServiceMock.groupID = mlsGroupID

            // When
            self.sut.process(
                welcomeMessage: message,
                conversationID: qualifiedID,
                in: self.syncMOC
            )

            // Then
            XCTAssertEqual(message, self.mlsServiceMock.processedWelcomeMessage)
            XCTAssertEqual(self.conversationServiceMock.syncConversationInvocations, [qualifiedID])
            XCTAssertTrue(self.mlsServiceMock.uploadKeyPackesIfNeededCalled)
        }
    }

    // MARK: - Update Conversation

    func test_itUpdates_GroupID() {
        syncMOC.performGroupedBlockAndWait {
            // Given
            self.conversation.mlsGroupID = nil

            // When
            self.sut.updateConversationIfNeeded(
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
            self.sut.joinMLSGroupWhenReady(
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

    func test_itWipesGroup() {
        syncMOC.performAndWait {
            // Given
            let groupID = MLSGroupID(Data.random())
            conversation.messageProtocol = .mls
            conversation.mlsGroupID = groupID

            // When
            self.sut.wipeMLSGroup(
                forConversation: conversation,
                context: syncMOC
            )

            // Then
            XCTAssertEqual(mlsServiceMock.calls.wipeGroup.count, 1)
            XCTAssertEqual(mlsServiceMock.calls.wipeGroup.first, groupID)
        }
    }

    func test_itDoesntWipeGroup_WhenProtocolIsNotMLS() {
        syncMOC.performAndWait {
            // Given
            conversation.messageProtocol = .proteus
            conversation.mlsGroupID = MLSGroupID(Data.random())

            // When
            self.sut.wipeMLSGroup(
                forConversation: conversation,
                context: syncMOC
            )

            // Then
            XCTAssertEqual(mlsServiceMock.calls.wipeGroup.count, 0)
        }
    }

    // MARK: - Helpers

    func test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus status: MLSGroupStatus) {
        syncMOC.performAndWait {
            // Given
            self.conversation.mlsStatus = status

            // When
            self.sut.joinMLSGroupWhenReady(
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
            self.sut.updateConversationIfNeeded(
                conversation: self.conversation,
                groupID: self.groupIdString,
                context: self.syncMOC
            )

            // Then
            XCTAssertEqual(self.conversation.mlsStatus, expectedValue)
        }
    }
}

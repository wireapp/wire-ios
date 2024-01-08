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
import WireDataModelSupport
import XCTest
@testable import WireRequestStrategy

class MLSEventProcessorTests: MessagingTestBase {

    var sut: MLSEventProcessor!
    var mlsServiceMock: MockMLSServiceInterface!
    var conversationServiceMock: MockConversationServiceInterface!
    var conversation: ZMConversation!
    var qualifiedID: QualifiedID!
    let groupIdString = "identifier".data(using: .utf8)!.base64EncodedString()

    override func setUp() {
        super.setUp()

        qualifiedID = QualifiedID(uuid: .create(), domain: "example.com")
       
        mlsServiceMock = .init()
        mlsServiceMock.registerPendingJoin_MockMethod = { _ in }
        mlsServiceMock.wipeGroup_MockMethod = { _ in }
        mlsServiceMock.processWelcomeMessageWelcomeMessage_MockValue = nil
        mlsServiceMock.uploadKeyPackagesIfNeeded_MockMethod = { }

        syncMOC.performGroupedBlockAndWait {
            self.syncMOC.mlsService = self.mlsServiceMock
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.remoteIdentifier = self.qualifiedID.uuid
            self.conversation.mlsGroupID = MLSGroupID(self.groupIdString.base64DecodedBytes!)
            self.conversation.domain = self.qualifiedID.domain
            self.conversation.messageProtocol = .mls
        }

        conversationServiceMock = MockConversationServiceInterface()
        sut = MLSEventProcessor(conversationService: conversationServiceMock)
    }

    override func tearDown() {
        sut = nil
        mlsServiceMock = nil
        conversationServiceMock = nil
        conversation = nil
        qualifiedID = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Process Welcome Message

    func test_itProcessesMessageAndUpdatesConversation() async {
        // Given
        let message = "welcome message"

        await syncMOC.perform { [self] in
            conversation.mlsStatus = .pendingJoin
        }

        // When
        await sut.process(
            welcomeMessage: message,
            conversationID: qualifiedID,
            in: syncMOC
        )

        // Then
        XCTAssertEqual(mlsServiceMock.processWelcomeMessageWelcomeMessage_Invocations, [message])
        XCTAssertEqual(mlsServiceMock.uploadKeyPackagesIfNeeded_Invocations.count, 1)

        let mlsStatus = await syncMOC.perform { self.conversation.mlsStatus }
        XCTAssertEqual(mlsStatus, .ready)
    }

    func test_itProcessesMessage_ConversationDoesNotExist() async {
        // Given
        let message = "welcome message"
        let mlsGroupID = MLSGroupID.random()
        let qualifiedID = QualifiedID.random()

        mlsServiceMock.processWelcomeMessageWelcomeMessage_MockValue = mlsGroupID

        // When
        await sut.process(
            welcomeMessage: message,
            conversationID: qualifiedID,
            in: syncMOC
        )

        // Then
        XCTAssertEqual(mlsServiceMock.processWelcomeMessageWelcomeMessage_Invocations, [message])
        XCTAssertEqual(mlsServiceMock.uploadKeyPackagesIfNeeded_Invocations.count, 1)
        XCTAssertEqual(conversationServiceMock.syncConversationQualifiedID_Invocations, [qualifiedID])
    }

    // MARK: - Update Conversation

    func test_itUpdates_GroupID() async {
        await syncMOC.perform {
            // Given
            self.conversation.mlsGroupID = nil
            self.mlsServiceMock.conversationExistsGroupID_MockMethod = { _ in false }
        }

        // When
        await sut.updateConversationIfNeeded(
            conversation: self.conversation,
            groupID: self.groupIdString,
            context: self.syncMOC
        )

        await syncMOC.perform {
            // Then
            XCTAssertEqual(self.conversation.mlsGroupID?.bytes, self.groupIdString.base64DecodedBytes)
        }
    }

    func test_itUpdates_MlsStatus_WhenProtocolIsMLS_AndWelcomeMessageWasProcessed() async {
        await assert_mlsStatus(
            originalValue: .pendingJoin,
            expectedValue: .ready,
            mockMessageProtocol: .mls,
            mockHasWelcomeMessageBeenProcessed: true
        )
    }

    func test_itUpdates_MlsStatus_WhenProtocolIsMLS_AndWelcomeMessageWasNotProcessed() async {
        await assert_mlsStatus(
            originalValue: .ready,
            expectedValue: .pendingJoin,
            mockMessageProtocol: .mls,
            mockHasWelcomeMessageBeenProcessed: false
        )
    }

    func test_itDoesntUpdate_MlsStatus_WhenProtocolIsNotMLS() async {
        await assert_mlsStatus(
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
            XCTAssertEqual(self.mlsServiceMock.registerPendingJoin_Invocations.count, 1)
            XCTAssertEqual(self.mlsServiceMock.registerPendingJoin_Invocations.first, self.conversation.mlsGroupID)
        }
    }

    func test_itDoesntAddNotPendingGroupsToGroupsPendingJoin() {
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .ready)
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .pendingLeave)
        test_thatGroupIsNotAddedToGroupsPendingJoin(forStatus: .outOfSync)
    }

    // MARK: - Wiping group

    func test_itWipesGroup() async {
        // Given
        let groupID = MLSGroupID.random()

        await syncMOC.perform { [self] in
            conversation.messageProtocol = .mls
            conversation.mlsGroupID = groupID
        }

        // When
        await sut.wipeMLSGroup(
            forConversation: conversation,
            context: syncMOC
        )

        // Then
        XCTAssertEqual(mlsServiceMock.wipeGroup_Invocations.count, 1)
        XCTAssertEqual(mlsServiceMock.wipeGroup_Invocations.first, groupID)
    }

    func test_itDoesntWipeGroup_WhenProtocolIsNotMLS() async {
        // Given
        await syncMOC.perform { [self] in
            conversation.messageProtocol = .proteus
            conversation.mlsGroupID = MLSGroupID.random()
        }

        // When
        await sut.wipeMLSGroup(
            forConversation: conversation,
            context: syncMOC
        )

        // Then
        XCTAssertTrue(mlsServiceMock.wipeGroup_Invocations.isEmpty)
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
            XCTAssertTrue(self.mlsServiceMock.registerPendingJoin_Invocations.isEmpty)
        }
    }

    func assert_mlsStatus(
        originalValue: MLSGroupStatus,
        expectedValue: MLSGroupStatus,
        mockMessageProtocol: MessageProtocol,
        mockHasWelcomeMessageBeenProcessed: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await syncMOC.perform {
            // Given
            self.conversation.mlsStatus = originalValue
            self.conversation.messageProtocol = mockMessageProtocol
            self.mlsServiceMock.conversationExistsGroupID_MockValue = mockHasWelcomeMessageBeenProcessed
        }

        // When
        await sut.updateConversationIfNeeded(
            conversation: self.conversation,
            groupID: self.groupIdString,
            context: self.syncMOC
        )

        await syncMOC.perform {
            // Then
            XCTAssertEqual(self.conversation.mlsStatus, expectedValue, file: file, line: line)
        }
    }
}

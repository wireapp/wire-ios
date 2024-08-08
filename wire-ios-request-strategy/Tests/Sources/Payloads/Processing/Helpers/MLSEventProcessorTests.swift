//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
@testable import WireRequestStrategySupport

final class MLSEventProcessorTests: MessagingTestBase {

    var sut: MLSEventProcessor!
    var mlsServiceMock: MockMLSServiceInterface!
    var conversationServiceMock: MockConversationServiceInterface!
    var oneOnOneResolverMock: MockOneOnOneResolverInterface!
    var staleKeyMaterialDetectorMock: MockStaleMLSKeyDetectorProtocol!

    var conversation: ZMConversation!
    var qualifiedID: QualifiedID!
    let groupIdString = Data("identifier".utf8).base64EncodedString()

    override func setUp() {
        super.setUp()

        qualifiedID = QualifiedID(uuid: .create(), domain: "example.com")

        mlsServiceMock = .init()
        mlsServiceMock.wipeGroup_MockMethod = { _ in }
        mlsServiceMock.processWelcomeMessageWelcomeMessage_MockValue = .random()
        mlsServiceMock.uploadKeyPackagesIfNeeded_MockMethod = { }

        oneOnOneResolverMock = .init()
        oneOnOneResolverMock.resolveOneOnOneConversationWithIn_MockMethod = { _, _ in .noAction }

        conversationServiceMock = .init()
        conversationServiceMock.syncConversationQualifiedID_MockMethod = { _ in }
        conversationServiceMock.syncConversationIfMissingQualifiedID_MockMethod = { _ in }

        staleKeyMaterialDetectorMock = .init()
        staleKeyMaterialDetectorMock.keyingMaterialUpdatedFor_MockMethod = { _ in }

        syncMOC.performGroupedAndWait {
            self.syncMOC.mlsService = self.mlsServiceMock
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.remoteIdentifier = self.qualifiedID.uuid
            self.conversation.mlsGroupID = .init(base64Encoded: self.groupIdString)
            self.conversation.domain = self.qualifiedID.domain
            self.conversation.messageProtocol = .mls
        }

        sut = MLSEventProcessor(
            conversationService: conversationServiceMock,
            staleKeyMaterialDetector: staleKeyMaterialDetectorMock
        )
    }

    override func tearDown() {
        sut = nil
        mlsServiceMock = nil
        conversationServiceMock = nil
        oneOnOneResolverMock = nil
        conversation = nil
        qualifiedID = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Process Welcome Message

    func test_itProcessesMessageAndUpdatesConversation_GroupConversation() async {
        // Given
        let message = "welcome message"

        await syncMOC.perform {
            self.conversation.mlsStatus = .ready
            self.conversation.conversationType = .group
        }

        // When
        await sut.process(
            welcomeMessage: message,
            conversationID: qualifiedID,
            in: syncMOC,
            mlsService: mlsServiceMock,
            oneOnOneResolver: oneOnOneResolverMock
        )

        // Then
        XCTAssertEqual(staleKeyMaterialDetectorMock.keyingMaterialUpdatedFor_Invocations.count, 1)
        XCTAssertEqual(mlsServiceMock.uploadKeyPackagesIfNeeded_Invocations.count, 1)
        XCTAssertEqual(conversationServiceMock.syncConversationIfMissingQualifiedID_Invocations, [qualifiedID])
        XCTAssertTrue(oneOnOneResolverMock.resolveOneOnOneConversationWithIn_Invocations.isEmpty)
    }

    func test_itProcessesMessageAndUpdatesConversation_OneOnOneConversation() async throws {
        // Given
        let message = "welcome message"

        let otherUserID = QualifiedID(
            uuid: .create(),
            domain: qualifiedID.domain
        )

        await syncMOC.perform {
            self.conversation.mlsStatus = .ready
            self.conversation.conversationType = .oneOnOne

            let otherUser = self.createUser()
            otherUser.remoteIdentifier = otherUserID.uuid
            otherUser.domain = otherUserID.domain

            self.conversation.addParticipantAndUpdateConversationState(
                user: otherUser,
                role: nil
            )
        }

        // Mock
        oneOnOneResolverMock.resolveOneOnOneConversationWithIn_MockMethod = { _, _ in .noAction }

        // When
        await sut.process(
            welcomeMessage: message,
            conversationID: qualifiedID,
            in: syncMOC,
            mlsService: mlsServiceMock,
            oneOnOneResolver: oneOnOneResolverMock
        )

        // Then
        XCTAssertEqual(staleKeyMaterialDetectorMock.keyingMaterialUpdatedFor_Invocations.count, 1)
        XCTAssertEqual(mlsServiceMock.uploadKeyPackagesIfNeeded_Invocations.count, 1)
        XCTAssertEqual(conversationServiceMock.syncConversationIfMissingQualifiedID_Invocations, [qualifiedID])
        XCTAssertEqual(oneOnOneResolverMock.resolveOneOnOneConversationWithIn_Invocations.count, 1)
        XCTAssertEqual(oneOnOneResolverMock.resolveOneOnOneConversationWithIn_Invocations.first?.userID, otherUserID)
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
            conversation: conversation,
            fallbackGroupID: .init(base64Encoded: groupIdString),
            context: syncMOC
        )

        await syncMOC.perform {
            // Then
            XCTAssertEqual(self.conversation.mlsGroupID?.data, self.groupIdString.base64DecodedData)
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

    func test_itUpdates_MlsStatus_WhenProtocolIsMixed_AndWelcomeMessageWasProcessed() async {
        await assert_mlsStatus(
            originalValue: .pendingJoin,
            expectedValue: .ready,
            mockMessageProtocol: .mixed,
            mockHasWelcomeMessageBeenProcessed: true
        )
    }

    func test_itUpdates_MlsStatus_WhenProtocolIsMixed_AndWelcomeMessageWasNotProcessed() async {
        await assert_mlsStatus(
            originalValue: .ready,
            expectedValue: .pendingJoin,
            mockMessageProtocol: .mixed,
            mockHasWelcomeMessageBeenProcessed: false
        )
    }

    func test_itDoesntUpdate_MlsStatus_WhenProtocolIsProteus() async {
        await assert_mlsStatus(
            originalValue: .pendingJoin,
            expectedValue: .pendingJoin,
            mockMessageProtocol: .proteus
        )
    }

    // MARK: - Wiping group

    func test_itWipesGroup_WhenProtocolIsMLS() async {
        await internalTest_wipeMLSGroupWithProtocol(.mls, shouldWipe: true)
    }

    func test_itWipesGroup_WhenProtocolIsMixed() async {
        await internalTest_wipeMLSGroupWithProtocol(.mixed, shouldWipe: true)
    }

    func test_itDoesntWipeGroup_WhenProtocolIsProteus() async {
        await internalTest_wipeMLSGroupWithProtocol(.proteus, shouldWipe: false)
    }

    func internalTest_wipeMLSGroupWithProtocol(
        _ messageProtocol: MessageProtocol,
        shouldWipe: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Given
        let groupID = MLSGroupID.random()

        await syncMOC.perform { [self] in
            conversation.messageProtocol = messageProtocol
            conversation.mlsGroupID = groupID
        }

        // When
        await sut.wipeMLSGroup(
            forConversation: conversation,
            context: syncMOC
        )

        // Then
        if shouldWipe {
            XCTAssertEqual(mlsServiceMock.wipeGroup_Invocations.count, 1, file: file, line: line)
            XCTAssertEqual(mlsServiceMock.wipeGroup_Invocations.first, groupID, file: file, line: line)
        } else {
            XCTAssertTrue(mlsServiceMock.wipeGroup_Invocations.isEmpty, file: file, line: line)
        }
    }

    // MARK: - Helpers

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
            fallbackGroupID: .init(base64Encoded: groupIdString),
            context: self.syncMOC
        )

        await syncMOC.perform {
            // Then
            XCTAssertEqual(self.conversation.mlsStatus, expectedValue, file: file, line: line)
        }
    }
}

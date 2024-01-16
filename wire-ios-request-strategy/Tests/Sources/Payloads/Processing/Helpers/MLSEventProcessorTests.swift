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

    var mlsServiceMock: MockMLSServiceInterface!
    var sut: MLSEventProcessor!
    var conversation: ZMConversation!
    var domain = "example.com"
    let groupIdString = "identifier".data(using: .utf8)!.base64EncodedString()

    override func setUp() {
        super.setUp()
        sut = MLSEventProcessor()
        syncMOC.performGroupedBlockAndWait {
            self.mlsServiceMock = .init()
            self.mlsServiceMock.wipeGroup_MockMethod = { _ in }
            self.syncMOC.mlsService = self.mlsServiceMock
            self.conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation.mlsGroupID = MLSGroupID(self.groupIdString.base64DecodedBytes!)
            self.conversation.domain = self.domain
            self.conversation.messageProtocol = .mls
        }
    }

    override func tearDown() {
        sut = nil
        mlsServiceMock = nil
        conversation = nil
        super.tearDown()
    }

    // MARK: - Process Welcome Message

    func test_itProcessesMessageAndUpdatesConversation() async {
        // Given
        let message = "welcome message"
        syncMOC.performGroupedBlockAndWait {
            self.mlsServiceMock.processWelcomeMessageWelcomeMessage_MockValue = self.conversation.mlsGroupID ?? MLSGroupID(Data())
            self.conversation.mlsStatus = .pendingJoin
            XCTAssertEqual(self.conversation.mlsStatus, .pendingJoin)
        }
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

    // MARK: - Wiping group

    func test_itWipesGroup() async {
        // Given
        let groupID = MLSGroupID(Data.random())
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
        await syncMOC.perform { [self] in
            // Given
            conversation.messageProtocol = .proteus
            conversation.mlsGroupID = MLSGroupID(Data.random())
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

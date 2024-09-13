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

import XCTest

import WireDataModelSupport
@testable import WireSyncEngine

final class DeepLinkURLActionProcessorTests: DatabaseTest {
    var presentationDelegate: MockPresentationDelegate!
    var sut: WireSyncEngine.DeepLinkURLActionProcessor!
    var mockTransportSession: MockTransportSession!
    var mockEventProcessor: MockConversationEventProcessorProtocol!

    override func setUp() {
        super.setUp()

        mockTransportSession = MockTransportSession(dispatchGroup: dispatchGroup)
        mockEventProcessor = MockConversationEventProcessorProtocol()
        mockEventProcessor.processConversationEvents_MockMethod = { _ in }
        presentationDelegate = MockPresentationDelegate()

        sut = WireSyncEngine.DeepLinkURLActionProcessor(
            contextProvider: coreDataStack!,
            transportSession: mockTransportSession,
            eventProcessor: mockEventProcessor
        )
    }

    override func tearDown() {
        sut = nil

        presentationDelegate = nil
        mockTransportSession = nil
        mockEventProcessor = nil

        super.tearDown()
    }

    // MARK: Tests

    func testThatItAsksForConversationToBeShown() {
        // GIVEN
        let conversationId = UUID()
        let action: URLAction = .openConversation(id: conversationId)
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = conversationId

        // WHEN
        sut.process(urlAction: action, delegate: presentationDelegate)

        // THEN
        XCTAssertEqual(presentationDelegate.showConversationCalls.count, 1)
        XCTAssertEqual(presentationDelegate.showConversationCalls.first, conversation)
    }

    func testThatItReportsTheActionAsFailed_WhenTheConversationDoesntExist() {
        // GIVEN
        let conversationId = UUID()
        let action: URLAction = .openConversation(id: conversationId)

        // WHEN
        sut.process(urlAction: action, delegate: presentationDelegate)

        // THEN
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.0, action)
        XCTAssertEqual(
            presentationDelegate.failedToPerformActionCalls.first?.1 as? DeepLinkRequestError,
            .invalidConversationLink
        )
    }

    func testThatItAsksToShowUserProfile_WhenUserIsKnown() {
        // GIVEN
        let userId = UUID()
        let action: URLAction = .openUserProfile(id: userId)
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.remoteIdentifier = userId

        // WHEN
        sut.process(urlAction: action, delegate: presentationDelegate)

        // THEN
        XCTAssertEqual(presentationDelegate.showUserProfileCalls.count, 1)
        XCTAssertEqual(presentationDelegate.showUserProfileCalls.first as? ZMUser, user)
    }

    func testThatItAsksToShowConnectionRequest_WhenUserIsUnknown() {
        // GIVEN
        let userId = UUID()
        let action: URLAction = .openUserProfile(id: userId)

        // WHEN
        sut.process(urlAction: action, delegate: presentationDelegate)

        // THEN
        XCTAssertEqual(presentationDelegate.showConnectionRequestCalls.count, 1)
        XCTAssertEqual(presentationDelegate.showConnectionRequestCalls.first, userId)
    }

    func testThatItCompletesTheJoinConversationAction_WhenCodeIsValid() {
        // GIVEN
        let action: URLAction = .joinConversation(key: "test-key", code: "test-code")

        let expectation = XCTestExpectation(description: "wait for completedURLAction")
        presentationDelegate.completedURLActionCallsCompletion = {
            expectation.fulfill()
        }

        // WHEN
        sut.process(urlAction: action, delegate: presentationDelegate)

        wait(for: [expectation], timeout: 5)

        // THEN
        XCTAssertEqual(mockEventProcessor.processConversationEvents_Invocations.count, 1)
        XCTAssertEqual(
            mockEventProcessor.processConversationEvents_Invocations.first?.first?.type,
            .conversationMemberJoin
        )
        XCTAssertEqual(presentationDelegate.completedURLActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.completedURLActionCalls.first, action)
    }

    func testThatItReportsTheJoinConversationActionAsFailed_WhenCodeIsInvalid() {
        // GIVEN
        let action: URLAction = .joinConversation(key: "test-key", code: "wrong-code")

        // WHEN
        sut.process(urlAction: action, delegate: presentationDelegate)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.count, 1)
        XCTAssertEqual(presentationDelegate.failedToPerformActionCalls.first?.0, action)
        XCTAssertEqual(
            presentationDelegate.failedToPerformActionCalls.first?.1 as? ConversationFetchError,
            ConversationFetchError.invalidCode
        )
    }
}

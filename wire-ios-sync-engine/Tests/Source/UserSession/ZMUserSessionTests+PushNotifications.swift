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

import WireDataModelSupport
import XCTest
@testable import WireRequestStrategy
@testable import WireSyncEngine

final class ZMUserSessionTests_PushNotifications: ZMUserSessionTestsBase {
    typealias Category = WireSyncEngine.PushNotificationCategory
    typealias ConversationAction = WireSyncEngine.ConversationNotificationAction
    typealias CallAction = WireSyncEngine.CallNotificationAction

    // The mock in this place is a workaround, because the test funcs call
    // `func handle(...)` and this calls `sut.didFinishQuickSync()` and this calls `PushSupportedProtocolsAction`.
    // A proper solution and mocking requires a further refactoring.
    private var mockPushSupportedProtocolsActionHandler: MockActionHandler<PushSupportedProtocolsAction>!

    // MARK: Setup

    override func setUp() {
        super.setUp()
        mockPushSupportedProtocolsActionHandler = .init(
            result: .success(()),
            context: syncMOC.notificationContext
        )
    }

    override func tearDown() {
        mockPushSupportedProtocolsActionHandler = nil

        super.tearDown()
    }

    // MARK: Tests

    func testThatItCallsShowConversationList_ForPushNotificationCategoryConversationWithoutConversation() {
        // when
        handle(conversationAction: nil, category: .conversation, userInfo: NotificationUserInfo())

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversationsList, sut)
    }

    func testThatItCallsShowConversationList_ForPushNotificationCategoryConnect() {
        // given
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID()
        let userInfo = userInfoWithConnectionRequest(from: sender)

        // when
        handle(conversationAction: nil, category: .connect, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
        XCTAssertFalse(sender.isConnected)
    }

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: jacob this can only be tested in an integration test or with better mocks
    func skip_testThatItCallsShowConversationListAndConnects_ForPushNotificationCategoryConnectWithAcceptAction() {
        // given
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID()

        let userInfo = userInfoWithConnectionRequest(from: sender)

        // when
        handle(conversationAction: .connect, category: .connect, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
    }

    func testThatItMutesAndDoesNotShowConversation_ForPushNotificationCategoryConversationWithMuteAction() {
        // given
        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!
        simulateLoggedInUser()

        // when
        handle(conversationAction: .mute, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertNil(mockSessionManager.lastRequestToShowConversation)
        XCTAssertNil(mockSessionManager.lastRequestToShowConversationsList)
        XCTAssertEqual(conversation.mutedMessageTypes, .all)
    }

    func testThatItAddsLike_ForPushNotificationCategoryConversationWithLikeAction() {
        // given
        let userInfo = userInfoWithConversation(hasMessage: true)
        let conversation = userInfo.conversation(in: uiMOC)!

        simulateLoggedInUser()
        sut.applicationStatusDirectory.operationStatus.isInBackground = true

        // when
        handle(conversationAction: .like, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual((conversation.lastMessage as? ZMMessage)?.reactions.count, 1)
    }

    func testThatItCallsShowConversation_ForPushNotificationCategoryConversation() {
        // given
        let userInfo = userInfoWithConversation()

        // when
        handle(conversationAction: nil, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
    }

    func testThatItCallsShowConversationAtMessage_ForPushNotificationCategoryConversation() {
        // given
        let userInfo = userInfoWithConversation(hasMessage: true)

        // when
        handle(conversationAction: nil, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowMessage?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowMessage?.1.remoteIdentifier, userInfo.conversationID!)
        XCTAssertEqual(mockSessionManager.lastRequestToShowMessage?.2.nonce, userInfo.messageNonce!)
    }

    func testThatItCallsShowConversationAndAcceptsCall_ForPushNotificationCategoryIncomingCallWithAcceptAction() {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            self.createSelfClient()
        }

        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!

        let callCenter = syncMOC.performAndWait { self.createCallCenter() }
        simulateIncomingCall(fromUser: conversation.connectedUser!, conversation: conversation)

        // when
        handle(callAction: .accept, category: .incomingCall, userInfo: userInfo)

        // then
        XCTAssertTrue(callCenter.didCallAnswerCall)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID)
    }

    func testThatItDoesNotCallsShowConversationAndRejectsCall_ForPushNotificationCategoryIncomingCallWithIgnoreAction() {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            self.createSelfClient()
        }

        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!

        let callCenter = syncMOC.performAndWait { self.createCallCenter() }
        simulateIncomingCall(fromUser: conversation.connectedUser!, conversation: conversation)

        // when
        handle(callAction: .ignore, category: .incomingCall, userInfo: userInfo)

        // then
        XCTAssertTrue(callCenter.didCallRejectCall)
        XCTAssertNil(mockSessionManager.lastRequestToShowConversation)
    }

    func testThatItCallsShowConversationButDoesNotCallBack_ForPushNotificationCategoryMissedCallWithCallBackAction() {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
            self.createSelfClient()
        }

        let userInfo = userInfoWithConversation()
        let callCenter = syncMOC.performAndWait { self.createCallCenter() }

        // when
        handle(callAction: .callBack, category: .missedCall, userInfo: userInfo)

        // then
        XCTAssertFalse(callCenter.didCallStartCall)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
    }

    func testThatItDoesNotCallShowConversationAndAppendsAMessage_ForPushNotificationCategoryConversationWithDirectReplyAction(
    ) {
        // given
        syncMOC.performAndWait {
            simulateLoggedInUser()
        }
        sut.applicationStatusDirectory.operationStatus.isInBackground = true
        let userInfo = userInfoWithConversation()
        let conversation = userInfo.conversation(in: uiMOC)!

        // when
        handle(conversationAction: .reply, category: .conversation, userInfo: userInfo, userText: "Hello World")

        // then
        XCTAssertEqual(conversation.allMessages.count, 1)
        XCTAssertNil(mockSessionManager.lastRequestToShowConversation)
    }

    func testThatItAppendsReadReceipt_ForPushNotificationCategoryConversationWithDirectReplyAction() async throws {
        // given
        await syncMOC.perform {
            self.simulateLoggedInUser()
        }
        sut.applicationStatusDirectory.operationStatus.isInBackground = true

        let userInfo = userInfoWithConversation(hasMessage: true)

        guard let conversation = await uiMOC.perform({ userInfo.conversation(in: self.uiMOC) }) else {
            XCTFail("no conversation")
            return
        }

        let (originalMessage, originaMessageNonce) = try await uiMOC.perform {
            let originalMessage = try XCTUnwrap(conversation.lastMessages().last as? ZMClientMessage)
            let originaMessageNonce = try XCTUnwrap(originalMessage.nonce)
            return (originalMessage, originaMessageNonce)
        }

        await uiMOC.perform {
            ZMUser.selfUser(in: self.uiMOC).readReceiptsEnabled = true
        }

        try await uiMOC.perform {
            var genericMessage = try XCTUnwrap(originalMessage.underlyingMessage)
            genericMessage.setExpectsReadConfirmation(true)
            try originalMessage.setUnderlyingMessage(genericMessage)
        }

        // when
        handle(conversationAction: .reply, category: .conversation, userInfo: userInfo, userText: "Hello World")
        await uiMOC.perform {
            // then
            self.assertHasReadConfirmationForMessage(nonce: originaMessageNonce, conversation: conversation)
        }
    }

    func testThatItAppendsReadReceipt_ForPushNotificationCategoryConversationWithLikeAction() throws {
        // given
        syncMOC.performAndWait {
            self.simulateLoggedInUser()
        }
        sut.applicationStatusDirectory.operationStatus.isInBackground = true

        let userInfo = userInfoWithConversation(hasMessage: true)
        let conversation = userInfo.conversation(in: uiMOC)!

        let originalMessage = try XCTUnwrap(conversation.lastMessages().last as? ZMClientMessage)
        let originaMessageNonce = try XCTUnwrap(originalMessage.nonce)

        ZMUser.selfUser(in: uiMOC).readReceiptsEnabled = true
        var genericMessage = originalMessage.underlyingMessage!
        genericMessage.setExpectsReadConfirmation(true)
        try originalMessage.setUnderlyingMessage(genericMessage)

        // when
        handle(conversationAction: .like, category: .conversation, userInfo: userInfo)

        // then
        assertHasReadConfirmationForMessage(nonce: originaMessageNonce, conversation: conversation)
    }

    func testThatOnLaunchItCallsShowConversationList_ForPushNotificationCategoryConversationWithoutConversation() {
        // given
        syncMOC.performAndWait {
            self.simulateLoggedInUser()
        }
        // when
        handle(conversationAction: nil, category: .conversation, userInfo: NotificationUserInfo())

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversationsList, sut)
    }

    func testThatOnLaunchItCallsShowConversationConversation_ForPushNotificationCategoryConversation() {
        // given
        syncMOC.performAndWait {
            self.simulateLoggedInUser()
        }

        let userInfo = userInfoWithConversation()

        // when
        handle(conversationAction: nil, category: .conversation, userInfo: userInfo)

        // then
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.0, sut)
        XCTAssertEqual(mockSessionManager.lastRequestToShowConversation?.1.remoteIdentifier, userInfo.conversationID!)
    }
}

extension ZMUserSessionTests_PushNotifications {
    func assertHasReadConfirmationForMessage(
        nonce: UUID,
        conversation: ZMConversation,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let containsReadConfirmation = conversation.lastMessages().contains { message in
            if let clientMessage = message as? ZMClientMessage,
               clientMessage.underlyingMessage?.hasConfirmation == true {
                clientMessage.underlyingMessage?.confirmation.firstMessageID == nonce.transportString()
            } else {
                false
            }
        }

        XCTAssertTrue(
            containsReadConfirmation,
            "expected read confirmation for message with nonce = \(nonce)",
            file: file,
            line: line
        )
    }

    func handle(
        conversationAction: ConversationAction?,
        category: Category,
        userInfo: NotificationUserInfo,
        userText: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        handle(
            action: conversationAction?.rawValue ?? "",
            category: category.rawValue,
            userInfo: userInfo,
            userText: userText,
            file: file,
            line: line
        )
    }

    func handle(
        callAction: CallAction,
        category: Category,
        userInfo: NotificationUserInfo,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        handle(action: callAction.rawValue, category: category.rawValue, userInfo: userInfo, file: file, line: line)
    }

    func handle(
        action: String,
        category: String,
        userInfo: NotificationUserInfo,
        userText: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        uiMOC.performAndWait {
            sut.handleNotificationResponse(
                actionIdentifier: action,
                categoryIdentifier: category,
                userInfo: userInfo,
                userText: userText
            ) {}
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
        syncMOC.performAndWait {
            sut.didFinishQuickSync()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)
    }

    func userInfoWithConversation(hasMessage: Bool = false) -> NotificationUserInfo {
        let conversationId = UUID()
        var messageNonce: UUID?
        syncMOC.performGroupedAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .oneOnOne
            conversation.remoteIdentifier = conversationId

            let sender = ZMUser.insertNewObject(in: self.syncMOC)
            sender.remoteIdentifier = UUID()
            sender.oneOnOneConversation = conversation

            let connection = ZMConnection.insertNewObject(in: self.syncMOC)
            connection.to = sender
            connection.status = .accepted

            if hasMessage {
                let message = try! conversation.appendText(content: "123") as? ZMClientMessage
                message?.markAsSent()
                messageNonce = message?.nonce
            }

            self.syncMOC.saveOrRollback()
        }

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = conversationId

        if hasMessage {
            userInfo.messageNonce = messageNonce
        }

        return userInfo
    }

    func userInfoWithConnectionRequest(from sender: ZMUser) -> NotificationUserInfo {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .connection
        conversation.remoteIdentifier = UUID()
        conversation.oneOnOneUser = sender

        let connection = ZMConnection.insertNewObject(in: uiMOC)
        connection.to = sender
        connection.status = .pending

        uiMOC.saveOrRollback()

        let userInfo = NotificationUserInfo()
        userInfo.conversationID = conversation.remoteIdentifier
        userInfo.senderID = sender.remoteIdentifier

        return userInfo
    }
}

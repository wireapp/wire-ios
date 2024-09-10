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
import Wire_Notification_Service_Extension
import WireNotificationEngine
import XCTest

final class LegacyNotificationServiceTests: XCTestCase {

    private var sut: LegacyNotificationService!
    private var request: UNNotificationRequest!
    private var notificationContent: UNNotificationContent!
    private var contentResult: UNNotificationContent?

    private var coreDataFixture: CoreDataFixture!
    private var mockConversation: ZMConversation!
    private var currentUserIdentifier: UUID!

    private var callEventHandlerMock: CallEventHandlerMock!

    private var otherUser: ZMUser {
        return coreDataFixture.otherUser
    }

    private var selfUser: ZMUser {
        return coreDataFixture.selfUser
    }

    private var client: UserClient {
        coreDataFixture.mockUserClient()
    }

    override func setUp() {
        super.setUp()

        sut = LegacyNotificationService()
        callEventHandlerMock = CallEventHandlerMock()
        currentUserIdentifier = UUID.create()
        notificationContent = createNotificationContent()
        request = UNNotificationRequest(identifier: currentUserIdentifier.uuidString,
                                        content: notificationContent,
                                        trigger: nil)

        coreDataFixture = CoreDataFixture()
        mockConversation = createTeamGroupConversation()
        client.user = otherUser
        createAccount(with: currentUserIdentifier)

        sut.didReceive(request, withContentHandler: contentHandlerMock)
        sut.callEventHandler = callEventHandlerMock
    }

    override func tearDown() {
        callEventHandlerMock = nil
        sut = nil
        notificationContent = nil
        request = nil
        contentResult = nil

        coreDataFixture = nil
        currentUserIdentifier = nil
        mockConversation = nil

        super.tearDown()
    }

    // MARK: - Tests

    func disable_testThatItHandlesGeneratedNotification() {
        // GIVEN
        let unreadConversationCount = 5
        let note = textNotification(mockConversation, sender: otherUser)

        // WHEN
        XCTAssertNotEqual(note?.content, contentResult)
        sut.notificationSessionDidGenerateNotification(note, unreadConversationCount: unreadConversationCount)

        // THEN
        let content = try? XCTUnwrap(note?.content)
        XCTAssertEqual(content, contentResult)
        XCTAssertEqual(content?.badge?.intValue, unreadConversationCount)
    }

    func disable_testThatItReportsCallEvent() {
        // GIVEN
        let event = CallEventPayload(
            accountID: UUID.create().uuidString,
            conversationID: UUID.create().uuidString,
            shouldRing: true,
            callerName: "Alice",
            hasVideo: false
        )

        // WHEN
        XCTAssertFalse(callEventHandlerMock.reportIncomingVoIPCallCalled)
        sut.reportCallEvent(event, currentTimestamp: Date().timeIntervalSince1970)

        // THEN
        XCTAssertTrue(callEventHandlerMock.reportIncomingVoIPCallCalled)
    }

    // MARK: - Helpers

    private func createAccount(with id: UUID) {
        guard let sharedContainer = Bundle.main.appGroupIdentifier.map(FileManager.sharedContainerDirectory) else {
            XCTFail("There's no sharedContainer")
            fatalError()
        }

        let manager = AccountManager(sharedDirectory: sharedContainer)
        let account = Account(userName: "Test Account", userIdentifier: id)
        manager.addOrUpdate(account)
    }

    private func createNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.body = "body"
        content.title = "title"

        let storage = ["data": ["user": currentUserIdentifier.uuidString]]
        let userInfo = NotificationUserInfo(storage: storage)

        content.userInfo = userInfo.storage

        return content
    }

    private func textNotification(_ conversation: ZMConversation, sender: ZMUser) -> ZMLocalNotification? {
        guard let event = createEvent() else {
            return nil
        }
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: coreDataFixture.uiMOC)
    }

    private func createEvent() -> ZMUpdateEvent? {
        let genericMessage = GenericMessage(
            content: Text(
                content: "Hello Hello!",
                linkPreviews: []
            ),
            nonce: UUID.create()
        )

        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": mockConversation.remoteIdentifier!.transportString(),
            "from": otherUser.remoteIdentifier.transportString(),
            "time": Date().transportString(),
            "data": [
                "text": try? genericMessage.serializedData().base64String(),
                "sender": otherUser.clients.first?.remoteIdentifier
            ],
            "type": "conversation.otr-message-add"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())
    }

    private func createTeamGroupConversation() -> ZMConversation {
        ZMConversation.createTeamGroupConversation(
            moc: coreDataFixture.uiMOC,
            otherUser: otherUser,
            selfUser: selfUser
        )
    }

    private func contentHandlerMock(_ content: UNNotificationContent) {
        contentResult = content
    }
}

// MARK: - CallEventHandlerMock

private final class CallEventHandlerMock: CallEventHandlerProtocol {

    var reportIncomingVoIPCallCalled: Bool = false

    func reportIncomingVoIPCall(_ payload: [String: Any]) {
        reportIncomingVoIPCallCalled = true
    }
}

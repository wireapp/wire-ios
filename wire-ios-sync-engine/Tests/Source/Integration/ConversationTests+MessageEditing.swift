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

class ConversationTests_MessageEditing_Swift: ConversationTestsBase {
    // MARK: - Receiving

    func testThatItProcessesEditingMessages() {
        // GIVEN
        XCTAssert(login())

        let conversation = conversation(for: selfToUser1Conversation)
        let messageCount = conversation?.allMessages.count ?? 0

        let textMessage = GenericMessage(content: Text(content: "Foo"), nonce: .create())

        guard
            let fromClient = user1.clients.anyObject() as? MockUserClient,
            let toClient = selfUser.clients.anyObject() as? MockUserClient,
            let data = try? textMessage.serializedData() else {
            return XCTFail()
        }

        mockTransportSession.performRemoteChanges { _ in
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: data)
        }

        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        XCTAssertEqual(conversation?.allMessages.count, messageCount + 1)
        let receivedMessage = conversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(receivedMessage?.textMessageData?.messageText, "Foo")
        guard let messageNonce = receivedMessage?.nonce else {
            XCTFail("missing expected nonce")
            return
        }

        // WHEN
        let editMessage = GenericMessage(
            content: MessageEdit(replacingMessageID: messageNonce, text: Text(content: "Bar")),
            nonce: .create()
        )
        guard let editedData = try? editMessage.serializedData() else {
            return XCTFail()
        }
        mockTransportSession.performRemoteChanges { _ in
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: editedData)
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        XCTAssertEqual(conversation?.allMessages.count, messageCount + 1)
        let editedMessage = conversation?.lastMessage as? ZMClientMessage
        XCTAssertEqual(editedMessage?.textMessageData?.messageText, "Bar")
    }

    func testThatItSendsOutNotificationAboutUpdatedMessages() {
        // GIVEN
        XCTAssert(login())

        let conversation = conversation(for: selfToUser1Conversation)
        let textMessage = GenericMessage(content: Text(content: "Foo"), nonce: .create())

        guard
            let fromClient = user1.clients.anyObject() as? MockUserClient,
            let toClient = selfUser.clients.anyObject() as? MockUserClient,
            let data = try? textMessage.serializedData() else {
            return XCTFail()
        }

        mockTransportSession.performRemoteChanges { _ in
            self.selfToUser1Conversation.encryptAndInsertData(from: fromClient, to: toClient, data: data)
        }

        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        let receivedMessage = conversation?.lastMessage as? ZMClientMessage
        let messageNonce = receivedMessage?.nonce

        let observer = MessageChangeObserver(message: receivedMessage)

        receivedMessage?.managedObjectContext?.processPendingChanges()
        let lastModifiedDate = conversation?.lastModifiedDate

        // WHEN
        let editMessage = GenericMessage(
            content: MessageEdit(replacingMessageID: messageNonce!, text: Text(content: "Bar")),
            nonce: .create()
        )
        guard let editedData = try? editMessage.serializedData() else {
            return XCTFail()
        }
        var editEvent: MockEvent?

        mockTransportSession.performRemoteChanges { _ in
            editEvent = self.selfToUser1Conversation.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: editedData
            )
        }
        _ = waitForAllGroupsToBeEmpty(withTimeout: 0.5)

        // THEN
        XCTAssertEqual(conversation?.lastModifiedDate, lastModifiedDate)
        XCTAssertNotEqual(conversation?.lastModifiedDate, editEvent?.time)

        XCTAssertEqual(observer?.notifications.count, 1)

        guard let messageInfo = observer?.notifications.firstObject as? MessageChangeInfo else {
            return XCTFail()
        }
        XCTAssertTrue(messageInfo.underlyingMessageChanged)
    }
}

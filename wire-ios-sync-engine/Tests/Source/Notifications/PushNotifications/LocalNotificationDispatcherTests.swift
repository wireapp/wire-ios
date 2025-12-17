//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

import GenericMessageProtocol
import UserNotifications
import WireUtilitiesSupport
import XCTest

@testable import WireSyncEngine

final class LocalNotificationDispatcherTests: DatabaseTest {

    typealias ZMLocalNotification = WireSyncEngine.ZMLocalNotification

    var sut: LocalNotificationDispatcher!
    var conversation1: ZMConversation!
    var conversation2: ZMConversation!

    var notificationCenter: UserNotificationCenterMock!

    var scheduledRequests: [UNNotificationRequest] {
        notificationCenter.scheduledRequests
    }

    var user1: ZMUser!
    var user2: ZMUser!

    var selfUser: ZMUser {
        ZMUser.selfUser(in: syncMOC)
    }

    override func setUp() {
        super.setUp()

        notificationCenter = .init()
        syncMOC.performAndWait {
            self.sut = LocalNotificationDispatcher(in: self.syncMOC)
        }
        sut.notificationCenter = notificationCenter

        [
            sut.eventNotifications,
            sut.failedMessageNotifications,
            sut.callingNotifications
        ].forEach { $0.notificationCenter = notificationCenter }

        syncMOC.performGroupedAndWait {
            self.user1 = ZMUser.insertNewObject(in: self.syncMOC)
            self.user2 = ZMUser.insertNewObject(in: self.syncMOC)
            self.user1.remoteIdentifier = UUID.create()
            self.user1.name = "User 1"
            self.user2.remoteIdentifier = UUID.create()
            self.user2.name = "User 2"
            self.conversation1 = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation1.userDefinedName = "Conversation 1"
            self.conversation2 = ZMConversation.insertNewObject(in: self.syncMOC)
            self.conversation2.userDefinedName = "Conversation 2"
            [self.conversation1!, self.conversation2!].forEach {
                $0.conversationType = .group
                $0.remoteIdentifier = UUID.create()
                $0.addParticipantAndUpdateConversationState(user: self.user1, role: nil)
            }
            self.conversation2.addParticipantAndUpdateConversationState(user: self.user2, role: nil)

            self.selfUser.remoteIdentifier = UUID.create()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

    }

    override func tearDown() {
        notificationCenter = nil
        user1 = nil
        user2 = nil
        conversation1 = nil
        conversation2 = nil
        sut = nil
        super.tearDown()
    }
}

extension LocalNotificationDispatcherTests {
   
    func testThatWhenFailingAMessageItSchedulesANotification() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let message = try! self.conversation1.appendText(content: "bar") as! ZMClientMessage
            message.sender = self.user1

            // WHEN
            self.sut.didFailToSend(message)

            // THEN
            XCTAssertEqual(self.scheduledRequests.count, 1)
        }
    }

    func testThatItCancelsAllNotificationsForFailingMessagesWhenCancelingAllNotifications() {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            let note1 = ZMLocalNotification(expiredMessageIn: conversation1, moc: syncMOC)!
            let note2 = ZMLocalNotification(expiredMessageIn: conversation1, moc: syncMOC)!
            sut.eventNotifications.addObject(note1)
            sut.failedMessageNotifications.addObject(note2)

            // WHEN
            sut.cancelAllNotifications()

            // THEN
            XCTAssertEqual(notificationCenter.removedNotifications, Set([note1.id.uuidString, note2.id.uuidString]))
        }
    }

    func testThatItCancelsNotificationsForFailingMessagesWhenCancelingNotificationsForASpecificConversation() {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            let note1 = ZMLocalNotification(expiredMessageIn: conversation1, moc: syncMOC)!
            let note2 = ZMLocalNotification(expiredMessageIn: conversation2, moc: syncMOC)!
            let note3 = ZMLocalNotification(expiredMessageIn: conversation1, moc: syncMOC)!
            let note4 = ZMLocalNotification(expiredMessageIn: conversation2, moc: syncMOC)!
            sut.eventNotifications.addObject(note1)
            sut.eventNotifications.addObject(note2)
            sut.failedMessageNotifications.addObject(note3)
            sut.failedMessageNotifications.addObject(note4)

            // WHEN
            sut.cancelNotification(for: conversation1)

            // THEN
            XCTAssertEqual(notificationCenter.removedNotifications, Set([note1.id.uuidString, note3.id.uuidString]))
        }
    }

    func testThatItCancelsReadNotificationsIfTheLastReadChanges() {
        var note1: ZMLocalNotification!
        var note2: ZMLocalNotification!

        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            let message = try! conversation1.appendText(content: "foo") as! ZMClientMessage
            message.sender = user1
            note1 = ZMLocalNotification(expiredMessage: message, moc: syncMOC)!
            note2 = ZMLocalNotification(expiredMessageIn: conversation1, moc: syncMOC)!
            sut.eventNotifications.addObject(note1)
            sut.eventNotifications.addObject(note2)
            conversation1.lastServerTimeStamp = Date.distantFuture
            syncMOC.saveOrRollback()

            // WHEN
            let conversationOnUI = uiMOC.object(with: conversation1.objectID) as? ZMConversation
            conversationOnUI?.markAsRead()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        syncMOC.performGroupedAndWait { [self] in
            // THEN
            XCTAssertEqual(notificationCenter.removedNotifications, Set([note1.id.uuidString, note2.id.uuidString]))
        }
    }
}

// MARK: - Helpers

extension LocalNotificationDispatcherTests {

    func payloadForEncryptedOTRMessage(text: String, nonce: UUID) -> [String: Any] {
        let message = GenericMessage(content: Text(content: text), nonce: nonce)
        return payloadForOTRAsset(with: message)
    }

    func payloadForOTRAsset(with message: GenericMessage) -> [String: Any] {
        [
            "data": [
                "info": try? message.serializedData().base64String()
            ],
            "conversation": conversation1.remoteIdentifier!.transportString(),
            "type": EventConversationAddOTRAsset,
            "time": Date().transportString()
        ]
    }

    func payloadForOTRMessage(with message: GenericMessage) -> [String: Any] {
        [
            "data": [
                "text": try? message.serializedData().base64String()
            ],
            "conversation": conversation1.remoteIdentifier!.transportString(),
            "type": EventConversationAddOTRAsset,
            "time": Date().transportString()
        ]
    }

    func createUpdateEvent(
        _ nonce: UUID,
        conversationID: UUID,
        genericMessage: GenericMessage,
        senderID: UUID = UUID.create()
    ) -> ZMUpdateEvent {
        let payload: [String: Any] = [
            "id": UUID.create().transportString(),
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": Date().transportString(),
            "data": ["text": try? genericMessage.serializedData().base64String()],
            "type": "conversation.otr-message-add"
        ]

        return ZMUpdateEvent(
            uuid: nonce,
            payload: payload,
            transient: false,
            decrypted: true,
            source: .pushNotification
        )!
    }
}

// Helper function inserted by Swift 4.2 migrator.
private func convertToUNNotificationSoundName(_ input: String) -> UNNotificationSoundName {
    UNNotificationSoundName(rawValue: input)
}

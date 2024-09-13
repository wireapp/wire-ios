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
            sut.callingNotifications,
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
            for item in [self.conversation1!, self.conversation2!] {
                item.conversationType = .group
                item.remoteIdentifier = UUID.create()
                item.addParticipantAndUpdateConversationState(user: self.user1, role: nil)
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
    func testThatItCreatesNotificationFromMessagesIfNotActive() {
        // GIVEN
        let text = UUID.create().transportString()
        syncMOC.performGroupedAndWait {
            let event = self.createUpdateEvent(
                UUID.create(),
                conversationID: self.conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(content: text)),
                senderID: self.user1.remoteIdentifier
            )

            // WHEN
            self.sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sut.eventNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)

        guard
            let note = sut.eventNotifications.notifications.first,
            let request = scheduledRequests.first
        else { return XCTFail() }

        XCTAssertTrue(note.body.contains(text))
        XCTAssertEqual(note.body, request.content.body)
        XCTAssertEqual(note.id.uuidString, request.identifier)
    }

    func testThatItCreatesNotificationFromSystemMessagesIfNotActive() {
        syncMOC.performGroupedAndWait {
            // GIVEN
            let messageTimer = MessageDestructionTimeoutValue.fiveMinutes
            let payload: [String: Any] = [
                "id": UUID.create().transportString(),
                "from": self.user1.remoteIdentifier.transportString(),
                "conversation": self.conversation1.remoteIdentifier!.transportString(),
                "time": Date().transportString(),
                "data": ["message_timer": messageTimer.rawValue * 1000],
                "type": "conversation.message-timer-update",
            ]
            let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID.create())!
            event.source = .pushNotification

            // WHEN
            self.sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sut.eventNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)

        guard
            let note = sut.eventNotifications.notifications.first,
            let request = scheduledRequests.first
        else { return XCTFail() }

        XCTAssertTrue(note.body.contains("User 1 set the message timer to"))
        XCTAssertEqual(note.body, request.content.body)
        XCTAssertEqual(note.id.uuidString, request.identifier)
    }

    func testThatItAddsNotificationOfDifferentConversationsToTheList() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let event1 = self.createUpdateEvent(
                UUID.create(),
                conversationID: self.conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(content: "foo1")),
                senderID: self.user1.remoteIdentifier
            )
            let event2 = self.createUpdateEvent(
                UUID.create(),
                conversationID: self.conversation2.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(content: "boo2")),
                senderID: self.user2.remoteIdentifier
            )

            // WHEN
            self.sut.processEventsWhileInBackground([event1, event2])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        syncMOC.performAndWait { [self] in
            // THEN
            XCTAssertEqual(scheduledRequests.count, 2)
            let userInfos = scheduledRequests.map { NotificationUserInfo(storage: $0.content.userInfo) }
            XCTAssertEqual(userInfos[0].conversation(in: syncMOC), conversation1)
            XCTAssertEqual(userInfos[1].conversation(in: syncMOC), conversation2)
        }
    }

    func testThatItDoesNotCreateANotificationForAnUnsupportedEventType() {
        syncMOC.performAndWait {
            // GIVEN
            let event = self.event(
                withPayload: nil,
                type: .conversationTyping,
                in: self.conversation1,
                user: self.user1
            )

            // WHEN
            self.sut.didReceive(events: [event], conversationMap: [:])

            // THEN
            XCTAssertEqual(self.scheduledRequests.count, 0)
        }
    }

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
            XCTAssertEqual(
                notificationCenter.removedNotifications,
                Set([note1.id.uuidString, note2.id.uuidString])
            )
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
            XCTAssertEqual(
                notificationCenter.removedNotifications,
                Set([note1.id.uuidString, note3.id.uuidString])
            )
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
            XCTAssertEqual(
                notificationCenter.removedNotifications,
                Set([note1.id.uuidString, note2.id.uuidString])
            )
        }
    }

    func testThatItSchedulesADefaultNotificationIfContentShouldNotBeVisible() {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            syncMOC.setPersistentStoreMetadata(
                NSNumber(value: true),
                key: LocalNotificationDispatcher.ZMShouldHideNotificationContentKey
            )
            syncMOC.saveOrRollback()

            let event = createUpdateEvent(
                UUID.create(),
                conversationID: conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(content: "foo")),
                senderID: user1.remoteIdentifier
            )

            // WHEN
            sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(scheduledRequests.count, 1)
        XCTAssertEqual(scheduledRequests[0].content.body, "New message")
        XCTAssertEqual(
            scheduledRequests[0].content.sound,
            UNNotificationSound(named: convertToUNNotificationSoundName("default"))
        )
    }

    func testThatItDoesNotCreateNotificationForTwoMessageEventsWithTheSameNonce() {
        var event: ZMUpdateEvent!
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            event = createUpdateEvent(
                UUID.create(),
                conversationID: conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(content: "foobar")),
                senderID: user1.remoteIdentifier
            )

            // WHEN
            sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sut.eventNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)

        // WHEN
        syncMOC.performGroupedAndWait { [self] in
            sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sut.eventNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)
    }

    func testThatItDoesNotCreateNotificationForFileUploadEventsWithTheSameNonce() {
        var event: ZMUpdateEvent!
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            let url = Bundle(for: LocalNotificationDispatcherTests.self).url(forResource: "video", withExtension: "mp4")
            let audioMetadata = ZMAudioMetadata(fileURL: url!, duration: 100)
            event = createUpdateEvent(
                UUID.create(),
                conversationID: conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: WireProtos.Asset(audioMetadata)),
                senderID: user1.remoteIdentifier
            )

            // WHEN
            sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sut.eventNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)

        syncMOC.performGroupedAndWait { [self] in
            // WHEN
            sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(sut.eventNotifications.notifications.count, 1)
        XCTAssertEqual(scheduledRequests.count, 1)
    }

    func testThatItCreatesNotificationForSelfGroupParticipation() {
        // GIVEN
        var payload: [String: Any]!
        var text = ""
        syncMOC.performAndWait {
            // notification content
            text = "\(self.user1.name!) added you"
            payload = [
                "from": self.user1.remoteIdentifier.transportString(),
                "conversation": self.conversation1.remoteIdentifier!.transportString(),
                "time": Date().transportString(),
                "data": [
                    "user_ids": [self.selfUser.remoteIdentifier.transportString()],
                    "users": ["id": self.selfUser.remoteIdentifier.transportString(),
                              "conversation_role": "wire_admin"],
                ],
                "type": "conversation.member-join",
            ]
        }
        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
        event.source = .pushNotification

        // WHEN
        syncMOC.performGroupedBlock {
            self.sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(scheduledRequests.count, 1)
        XCTAssertTrue(scheduledRequests.first!.content.body.contains(text))
    }

    func testThatItDoesNotCreateNotificationForOtherGroupParticipation() {
        var event: ZMUpdateEvent!
        syncMOC.performAndWait {
            // GIVEN
            let payload: [String: Any] = [
                "from": self.user1.remoteIdentifier.transportString(),
                "conversation": self.conversation1.remoteIdentifier!.transportString(),
                "time": Date().transportString(),
                "data": [
                    "user_ids": [self.user2.remoteIdentifier.transportString()],
                    "users": ["id": self.user2.remoteIdentifier.transportString(),
                              "conversation_role": "wire_admin"],
                ],
                "type": "conversation.member-join",
            ]
            event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: UUID())!
            event.source = .pushNotification
        }
        // WHEN
        syncMOC.performGroupedBlock {
            self.sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(scheduledRequests.count, 0)
    }

    func testThatNotifyAvailabilityBehaviourChangedIfNeededSchedulesNotification_WhenNeedsToNotifyAvailabilityBehaviourChangeIsSet(
    ) {
        syncMOC.performAndWait {
            // given
            selfUser.availability = .away
            selfUser.needsToNotifyAvailabilityBehaviourChange = [.notification]

            // when
            sut.notifyAvailabilityBehaviourChangedIfNeeded()

            // then
            XCTAssertEqual(self.notificationCenter.scheduledRequests.count, 1)
            XCTAssertEqual(selfUser.needsToNotifyAvailabilityBehaviourChange, [])
        }
    }

    func testThatNotifyAvailabilityBehaviourChangedIfNeededDoesNotScheduleNotification_WhenneedsToNotifyAvailabilityBehaviourChangeIsNotSet(
    ) {
        syncMOC.performAndWait {
            // given
            selfUser.needsToNotifyAvailabilityBehaviourChange = []

            // when
            sut.notifyAvailabilityBehaviourChangedIfNeeded()

            // then
            XCTAssertEqual(self.notificationCenter.scheduledRequests.count, 0)
        }
    }

    // MARK: Updating unread count

    func testThatEstimatedUnreadCountIsIncreased_WhenProcessingTextMessage() {
        syncMOC.performGroupedBlock {
            // GIVEN
            let text = UUID.create().transportString()
            let event = self.createUpdateEvent(
                UUID.create(),
                conversationID: self.conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(content: text)),
                senderID: self.user1.remoteIdentifier
            )

            // WHEN
            self.sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performAndWait {
            XCTAssertEqual(self.conversation1.estimatedUnreadCount, 1)
            XCTAssertEqual(self.conversation1.estimatedUnreadSelfMentionCount, 0)
            XCTAssertEqual(self.conversation1.estimatedUnreadSelfReplyCount, 0)
        }
    }

    func testThatEstimatedUnreadMentionCountIsIncreased_WhenProcessingTextMessageWhichMentionsSelfUser() {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            let text = UUID.create().transportString()
            let selfUserMention = Mention(range: NSRange(), user: selfUser)
            let event = createUpdateEvent(
                UUID.create(),
                conversationID: conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(
                    content: text,
                    mentions: [selfUserMention]
                )),
                senderID: user1.remoteIdentifier
            )

            // WHEN
            sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performAndWait {
            XCTAssertEqual(self.conversation1.estimatedUnreadCount, 1)
            XCTAssertEqual(self.conversation1.estimatedUnreadSelfMentionCount, 1)
            XCTAssertEqual(self.conversation1.estimatedUnreadSelfReplyCount, 0)
        }
    }

    func testThatEstimatedUnreadMentionCountIsIncreased_WhenProcessingTextMessageWhichRepliesToSelfUser() {
        syncMOC.performGroupedAndWait { [self] in
            // GIVEN
            let message = try! conversation1.appendText(content: "Hello") as! ZMOTRMessage
            let text = UUID.create().transportString()
            let event = createUpdateEvent(
                UUID.create(),
                conversationID: conversation1.remoteIdentifier!,
                genericMessage: GenericMessage(content: Text(
                    content: text,
                    replyingTo: message
                )),
                senderID: user1.remoteIdentifier
            )

            // WHEN
            sut.processEventsWhileInBackground([event])
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        syncMOC.performAndWait {
            XCTAssertEqual(self.conversation1.estimatedUnreadCount, 1)
            XCTAssertEqual(self.conversation1.estimatedUnreadSelfMentionCount, 0)
            XCTAssertEqual(self.conversation1.estimatedUnreadSelfReplyCount, 1)
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
                "info": try? message.serializedData().base64String(),
            ],
            "conversation": conversation1.remoteIdentifier!.transportString(),
            "type": EventConversationAddOTRAsset,
            "time": Date().transportString(),
        ]
    }

    func payloadForOTRMessage(with message: GenericMessage) -> [String: Any] {
        [
            "data": [
                "text": try? message.serializedData().base64String(),
            ],
            "conversation": conversation1.remoteIdentifier!.transportString(),
            "type": EventConversationAddOTRAsset,
            "time": Date().transportString(),
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
            "type": "conversation.otr-message-add",
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

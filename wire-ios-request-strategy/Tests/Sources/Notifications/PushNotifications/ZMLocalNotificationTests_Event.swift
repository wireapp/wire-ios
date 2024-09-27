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
@testable import WireRequestStrategy

final class ZMLocalNotificationTests_Event: ZMLocalNotificationTests {
    let EventConversationDelete = "conversation.delete"
    let EventConversationCreate = "conversation.create"
    let EventNewConnection = "user.contact-join"
    let EventaAddOTRMessage = "conversation.otr-message-add"

    // MARK: Helpers

    func payloadForConnectionRequest(to remoteID: UUID, status: String) -> [AnyHashable: Any] {
        [
            "connection": [
                "conversation": oneOnOneConversation.remoteIdentifier!.transportString(),
                "message": "Please add me",
                "from": UUID.create().transportString(),
                "status": status,
                "to": remoteID.transportString(),
            ],
            "type": "user.connection",
            "user": ["name": "Special User"],
        ]
    }

    func noteForConnectionRequestEvent(to user: ZMUser?, status: String) -> ZMLocalNotification? {
        let remoteID = user?.remoteIdentifier ?? UUID.create()
        var note: ZMLocalNotification?
        let payload = payloadForConnectionRequest(to: remoteID, status: status)

        if let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil) {
            note = ZMLocalNotification(
                event: event,
                conversation: oneOnOneConversation,
                managedObjectContext: syncMOC
            )
        }
        return note
    }

    func reactionEventInOneOnOneConversation() -> ZMUpdateEvent {
        let message = try! oneOnOneConversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(
            emojis: ["❤️"],
            messageID: message.nonce!
        ))
        return createUpdateEvent(
            UUID.create(),
            conversationID: oneOnOneConversation.remoteIdentifier!,
            genericMessage: reaction,
            senderID: sender.remoteIdentifier!
        )
    }

    func alertBody(_ conversation: ZMConversation, aSender: ZMUser) -> String? {
        // given
        let message = try! conversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(
            emojis: ["❤️"],
            messageID: message.nonce!
        ))
        let event = createUpdateEvent(
            UUID.create(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: reaction,
            senderID: aSender.remoteIdentifier!
        )

        // when
        let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)

        // then
        XCTAssertNotNil(note)
        return note!.body
    }

    func note(_ conversation: ZMConversation, aSender: ZMUser) -> ZMLocalNotification? {
        // given
        let message = try! conversation.appendText(content: "text") as! ZMClientMessage
        let reaction = GenericMessage(content: ProtosReactionFactory.createReaction(
            emojis: ["❤️"],
            messageID: message.nonce!
        ))
        let event = createUpdateEvent(
            UUID.create(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: reaction,
            senderID: aSender.remoteIdentifier!
        )

        // when
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    // MARK: - Group Conversation Created

    func testThatItCreatesConversationCreateNotification() {
        syncMOC.performGroupedAndWait {
            // "push.notification.conversation.create" = "%1$@ created a group conversation with you"

            // when
            let note = self.noteWithPayload(
                nil,
                from: self.sender,
                in: self.groupConversation,
                type: self.EventConversationCreate
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Super User created a conversation")
        }
    }

    func testThatItCreatesConversationCreateNotification_NoUsername() {
        syncMOC.performGroupedAndWait {
            // "push.notification.conversation.create.nousername" = "Someone created a group conversation with you"

            // when
            let note = self.noteWithPayload(
                nil,
                fromUserID: nil,
                in: self.groupConversation,
                type: self.EventConversationCreate
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Someone created a conversation")
        }
    }

    func testThatItDoesntCreateConversationCreateNotification_OneToOne() {
        syncMOC.performGroupedAndWait {
            // We don't want to create a notification for fake team one-to-one conversations

            // when
            let note = self.noteWithPayload(
                nil,
                fromUserID: nil,
                in: self.oneOnOneConversation,
                type: self.EventConversationCreate
            )

            // then
            XCTAssertNil(note)
        }
    }

    // MARK: - Group conversation deleted

    func testThatItCreatesConversationDeletedNotification() {
        syncMOC.performGroupedAndWait {
            // "push.notification.conversation.delete" = "%1$@ deleted the group"

            // when
            let note = self.noteWithPayload(
                nil,
                from: self.sender,
                in: self.groupConversation,
                type: self.EventConversationDelete
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Super User deleted the group")
        }
    }

    func testThatItCreatesConversationDeletedNotification_NoUsername() {
        syncMOC.performGroupedAndWait {
            // "push.notification.conversation.delete.nousername" = "Someone deleted the group"

            // when
            let note = self.noteWithPayload(
                nil,
                fromUserID: nil,
                in: self.groupConversation,
                type: self.EventConversationDelete
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Someone deleted the group")
        }
    }

    // MARK: - User Connections

    func testThatItCreatesNewConnectionNotification() {
        // given
        syncMOC.performGroupedAndWait {
            let senderID = UUID.create()
            let payload = [
                "user": ["id": senderID.transportString(), "name": "Stimpy"],
                "type": self.EventNewConnection,
                "time": Date().transportString(),
            ] as ZMTransportData

            let event = ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nil)
            var note: ZMLocalNotification?

            // when
            if let event {
                note = ZMLocalNotification(
                    event: event,
                    conversation: self.oneOnOneConversation,
                    managedObjectContext: self.uiMOC
                )
            }

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Stimpy just joined Wire")
            XCTAssertEqual(note!.senderID, senderID)
        }
    }

    func testThatItCreatesConnectionRequestNotificationsCorrectly() {
        //    "push.notification.connection.request" = "%@ wants to connect"
        //    "push.notification.connection.request.nousername" = "Someone wants to connect"
        //
        //    "push.notification.connection.accepted" = "%@ accepted your connection request"
        //    "push.notification.connection.accepted.nousername" = "Your connection request was accepted"

        // given
        syncMOC.performGroupedAndWait {
            let accepted = "accepted"
            let pending = "pending"

            let cases = [
                "You and Super User are now connected": [self.sender!, accepted],
                "You and Special User are now connected": [accepted],
                "Super User wants to connect": [self.sender!, pending],
                "Special User wants to connect": [pending],
            ]

            for (expectedBody, arguments) in cases {
                // when
                var note: ZMLocalNotification? = if arguments.count == 2 {
                    self.noteForConnectionRequestEvent(to: arguments[0] as? ZMUser, status: arguments[1] as! String)
                } else {
                    self.noteForConnectionRequestEvent(to: nil, status: arguments[0] as! String)
                }

                // then
                XCTAssertNotNil(note)
                XCTAssertEqual(note!.body, expectedBody)
            }
        }
    }

    func testThatItDoesNotCreateAConnectionAcceptedNotificationForAWrongStatus() {
        // given
        syncMOC.performGroupedAndWait {
            let status = "blablabla"

            // when
            let note = self.noteForConnectionRequestEvent(to: nil, status: status)

            // then
            XCTAssertNil(note)
        }
    }

    // MARK: - Message Timer System Message

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversation.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 86_400_000,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 set the message timer to 1 day")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName() {
        // given
        syncMOC.performGroupedAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversation.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 2_419_200_000,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone set the message timer to 4 weeks")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoConversationName() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversationWithoutName.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 10000,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversationWithoutName,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 set the message timer to 10 seconds in a conversation")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_NoConversationName() {
        // given
        syncMOC.performGroupedAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversationWithoutName.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 300_000,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversationWithoutName,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone set the message timer to 5 minutes in a conversation")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_Off() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversation.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 0,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 turned off the message timer")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_Off() {
        // given
        syncMOC.performGroupedAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversation.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 0,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone turned off the message timer")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoConversationName_Off() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversationWithoutName.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 0,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversationWithoutName,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Other User1 turned off the message timer in a conversation")
        }
    }

    func testThatItCreatesANotificationForMessageTimerUpdateSystemMessages_NoUserName_NoConversationName_Off() {
        // given
        syncMOC.performGroupedAndWait {
            self.otherUser1.name = nil
            let event = self.createMessageTimerUpdateEvent(
                self.otherUser1.remoteIdentifier,
                conversationID: self.groupConversationWithoutName.remoteIdentifier!,
                senderID: self.otherUser1.remoteIdentifier!,
                timer: 0,
                timestamp: Date()
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversationWithoutName,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone turned off the message timer in a conversation")
        }
    }

    // MARK: - Create text local notifications from update events

    func testThatItCreatesATextNotification() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createUpdateEvent(
                UUID.create(),
                conversationID: UUID.create(),
                genericMessage: GenericMessage(content: Text(content: "Stimpy just joined Wire"))
            )
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(
                event: event,
                conversation: self.oneOnOneConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.title, "Super User")
            XCTAssertEqual(note!.body, "New message: Stimpy just joined Wire")
        }
    }

    func testThatItDoesNotCreateANotificationWhenConversationIsForceReadonly() {
        // given
        syncMOC.performGroupedAndWait {
            self.oneOnOneConversation.isForcedReadOnly = true
            let event = self.createUpdateEvent(
                UUID.create(),
                conversationID: UUID.create(),
                genericMessage: GenericMessage(content: Text(content: "Stimpy just joined Wire"))
            )
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(
                event: event,
                conversation: self.oneOnOneConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItDoesNotCreateANotificationForConfirmationEvents() {
        // given
        syncMOC.performGroupedAndWait {
            let confirmation = GenericMessage(content: Confirmation(messageId: .create()))
            let event = self.createUpdateEvent(
                .create(),
                conversationID: self.oneOnOneConversation.remoteIdentifier!,
                genericMessage: confirmation
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.oneOnOneConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItCreatesATextNotification_NoConversation() {
        // given
        syncMOC.performGroupedAndWait {
            let genericMessage = GenericMessage(content: Text(content: "123"))

            // when
            let text = try! genericMessage.serializedData().base64EncodedString()
            let note = self.noteWithPayload(
                ["text": text],
                from: self.sender,
                in: nil,
                type: self.EventaAddOTRMessage
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note!.body, "Super User in a conversation: 123")
        }
    }

    // MARK: - Create system local notifications from update events

    func testThatItCreatesASystemLocalNotificationForRemovingTheSelfUserEvent() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMemberLeaveUpdateEvent(
                UUID.create(),
                conversationID: self.oneOnOneConversation.remoteIdentifier!,
                users: [self.selfUser]
            )
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(
                event: event,
                conversation: self.oneOnOneConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.title, "Super User")
            XCTAssertEqual(note?.body, "%1$@ removed you")
        }
    }

    func testThatItCreatesASystemLocalNotificationForAddingTheSelfUserEvent() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMemberJoinUpdateEvent(
                UUID.create(),
                conversationID: self.oneOnOneConversation.remoteIdentifier!,
                users: [self.selfUser]
            )
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(
                event: event,
                conversation: self.oneOnOneConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.title, "Super User")
            XCTAssertEqual(note?.body, "%1$@ added you")
        }
    }

    func testThatItCreatesASystemLocalNotificationForMessageTimerUpdateEvent() {
        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMessageTimerUpdateEvent(
                UUID.create(),
                conversationID: self.oneOnOneConversation.remoteIdentifier!
            )
            var note: ZMLocalNotification?

            // when
            note = ZMLocalNotification(
                event: event,
                conversation: self.oneOnOneConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNotNil(note)
            XCTAssertEqual(note?.body, "Someone set the message timer to 1 year")
        }
    }
}

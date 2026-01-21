//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireTesting
@testable import WireRequestStrategy

class ZMLocalNotificationTests_SystemMessage: ZMLocalNotificationTests {

    // MARK: - Helpers

    func noteForParticipantAdded(
        _ conversation: ZMConversation,
        aSender: ZMUser,
        otherUsers: Set<ZMUser>
    ) -> ZMLocalNotification? {
        let event = createMemberJoinUpdateEvent(
            UUID.create(),
            conversationID: conversation.remoteIdentifier!,
            users: Array(otherUsers),
            senderID: aSender.remoteIdentifier
        )

        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    func noteForParticipantsRemoved(
        _ conversation: ZMConversation,
        aSender: ZMUser,
        otherUsers: Set<ZMUser>
    ) -> ZMLocalNotification? {
        let event = createMemberLeaveUpdateEvent(
            UUID.create(),
            conversationID: conversation.remoteIdentifier!,
            users: Array(otherUsers),
            senderID: aSender.remoteIdentifier
        )

        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    // MARK: - Tests

    func testThatItDoesNotCreateANotificationForConversationRename() {

        // given
        syncMOC.performGroupedAndWait {
            let payload = [
                "from": self.sender.remoteIdentifier!.transportString(),
                "conversation": self.groupConversation.remoteIdentifier!.transportString(),
                "time": Date().transportString(),
                "data": [
                    "name": "New Name"
                ],
                "type": "conversation.rename"
            ] as [String: Any]
            let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItCreatesANotificationForParticipantAdd_Self() throws {

        //    "push.notification.member.join.self" = "%1$@ added you";
        //    "push.notification.member.join.self.noconversationname" = "%1$@ added you to a conversation";

        // given, when
        try syncMOC.performGroupedAndWait {

            // Remove self user from participants to simulate not being a member yet
            self.groupConversation.removeParticipantAndUpdateConversationState(user: self.selfUser)
            self.groupConversationWithoutName.removeParticipantAndUpdateConversationState(user: self.selfUser)
            XCTAssertFalse(self.groupConversation.localParticipants.contains(self.selfUser))
            XCTAssertFalse(self.groupConversationWithoutName.localParticipants.contains(self.selfUser))

            let note1 = try XCTUnwrap(self.noteForParticipantAdded(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.selfUser]
            ))
            let note2 = try XCTUnwrap(self.noteForParticipantAdded(
                self.groupConversationWithoutName,
                aSender: self.sender,
                otherUsers: [self.selfUser]
            ))
            let note3 = try XCTUnwrap(self.noteForParticipantAdded(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.selfUser, self.otherUser1]
            ))

            // then
            XCTAssertEqual(note1.body, "Super User added you")
            XCTAssertEqual(note2.body, "Super User added you to a conversation")
            XCTAssertEqual(note3.body, "Super User added you")
        }
    }

    func testThatItDoesNotCreateANotificationForParticipantAdd_SelfAlreadyParticipant() {

        syncMOC.performGroupedAndWait {
            // given: self user is already in the conversation
            XCTAssertTrue(self.groupConversation.localParticipants.contains(self.selfUser))

            // when: receiving a memberJoin event that includes self user
            let note = self.noteForParticipantAdded(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.selfUser]
            )

            // then: no notification should be created
            XCTAssertNil(note, "Should not create notification when self user is already a participant")
        }
    }

    func testThatItDoesNotCreateANotificationForParticipantAdd_Other() {
        syncMOC.performGroupedAndWait {
            XCTAssertNil(self.noteForParticipantAdded(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.otherUser1]
            ))
            XCTAssertNil(self.noteForParticipantAdded(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.otherUser1, self.otherUser2]
            ))
            XCTAssertNil(self.noteForParticipantAdded(
                self.groupConversationWithoutName,
                aSender: self.sender,
                otherUsers: [self.otherUser1]
            ))
            XCTAssertNil(self.noteForParticipantAdded(
                self.groupConversationWithoutName,
                aSender: self.sender,
                otherUsers: [self.otherUser1, self.otherUser2]
            ))
        }
    }

    func testThatItDoesNotCreateANotificationWhenTheUserLeaves() {

        // given
        syncMOC.performGroupedAndWait {
            let event = self.createMemberLeaveUpdateEvent(
                UUID.create(),
                conversationID: self.groupConversation.remoteIdentifier!,
                users: [self.otherUser1],
                senderID: self.otherUser1.remoteIdentifier
            )

            // when
            let note = ZMLocalNotification(
                event: event,
                conversation: self.groupConversation,
                managedObjectContext: self.syncMOC
            )

            // then
            XCTAssertNil(note)
        }
    }

    func testThatItCreatesANotificationForParticipantRemove_Self() {

        //    "push.notification.member.leave.self" = "%1$@ removed you from %2$@";
        //    "push.notification.member.leave.self.noconversationname" = "%1$@ removed you from a conversation";

        // given, when
        syncMOC.performGroupedAndWait {
            let note1 = self.noteForParticipantsRemoved(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.selfUser]
            )
            let note2 = self.noteForParticipantsRemoved(
                self.groupConversationWithoutName,
                aSender: self.sender,
                otherUsers: [self.selfUser]
            )

            // then
            XCTAssertNotNil(note1)
            XCTAssertNotNil(note2)
            XCTAssertEqual(note1!.body, "Super User removed you")
            XCTAssertEqual(note2!.body, "Super User removed you from a conversation")
        }
    }

    func testThatItDoesNotCreateNotificationsForParticipantRemoved_Other() {
        syncMOC.performGroupedAndWait {
            XCTAssertNil(self.noteForParticipantsRemoved(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.otherUser1]
            ))
            XCTAssertNil(self.noteForParticipantsRemoved(
                self.groupConversation,
                aSender: self.sender,
                otherUsers: [self.otherUser1, self.otherUser2]
            ))
            XCTAssertNil(self.noteForParticipantsRemoved(
                self.groupConversationWithoutName,
                aSender: self.sender,
                otherUsers: [self.otherUser1]
            ))
            XCTAssertNil(self.noteForParticipantsRemoved(
                self.groupConversationWithoutName,
                aSender: self.sender,
                otherUsers: [self.otherUser1, self.otherUser2]
            ))
        }
    }

}

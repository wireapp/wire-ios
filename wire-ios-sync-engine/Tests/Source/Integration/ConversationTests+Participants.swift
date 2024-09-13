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

class ConversationTests_Participants: ConversationTestsBase {
    func testThatAddingAndRemovingAParticipantToAConversationSendsOutChangeNotifications() async throws {
        // given
        XCTAssert(login())

        let conversation = try XCTUnwrap(conversation(for: emptyGroupConversation))
        let conversationParticipantsService = ConversationParticipantsService(
            context: userSession!
                .managedObjectContext
        )
        let connectedUser = await userSession!.managedObjectContext.perform { self.user(for: self.user2)! }

        let observer = ConversationChangeObserver(conversation: conversation)
        observer?.clearNotifications()

        // when
        try await conversationParticipantsService.addParticipants([connectedUser], to: conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then - Participants changes and messages changes (System message for the added user)

        XCTAssertEqual(observer?.notifications.count, 1)
        guard let note1 = observer?.notifications.firstObject as? ConversationChangeInfo else {
            return XCTFail()
        }
        XCTAssertEqual(note1.conversation, conversation)
        XCTAssertTrue(note1.participantsChanged)
        XCTAssertTrue(note1.messagesChanged)
        observer?.notifications.removeAllObjects()

        // when
        try await conversationParticipantsService.removeParticipant(connectedUser, from: conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then - Participants changes and messages changes (System message for the removed user)
        XCTAssertEqual(observer?.notifications.count, 1)
        let note2 = observer?.notifications.firstObject as! ConversationChangeInfo
        XCTAssertEqual(note2.conversation, conversation)
        XCTAssertTrue(note2.participantsChanged)
        XCTAssertTrue(note2.messagesChanged)

        observer?.notifications.removeAllObjects()
    }

    func testThatAddingParticipantsToAConversationIsSynchronizedWithBackend() async throws {
        // given
        XCTAssert(login())

        let conversation = try XCTUnwrap(conversation(for: emptyGroupConversation))
        let conversationParticipantsService = ConversationParticipantsService(
            context: userSession!
                .managedObjectContext
        )
        let connectedUser = await userSession!.managedObjectContext.perform { self.user(for: self.user2)! }

        await userSession!.managedObjectContext.perform {
            XCTAssertFalse(conversation.localParticipants.contains(connectedUser))
        }
        // when
        try await conversationParticipantsService.addParticipants([connectedUser], to: conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        await userSession!.managedObjectContext.perform {
            XCTAssertTrue(conversation.localParticipants.contains(connectedUser))
        }
        // Tear down & recreate contexts
        recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(login())

        // then
        await userSession!.managedObjectContext.perform { [self] in
            XCTAssertTrue(
                self.conversation(for: emptyGroupConversation)!.localParticipants
                    .contains(user(for: user2)!)
            )
        }
    }

    func testThatRemovingParticipantsFromAConversationIsSynchronizedWithBackend() async throws {
        // given
        XCTAssert(login())

        let conversation = try XCTUnwrap(conversation(for: groupConversation))
        let conversationParticipantsService = ConversationParticipantsService(
            context: userSession!
                .managedObjectContext
        )
        let connectedUser = await userSession!.managedObjectContext.perform { self.user(for: self.user2)! }

        await userSession!.managedObjectContext.perform {
            XCTAssertTrue(conversation.localParticipants.contains(connectedUser))
        }

        // when
        try await conversationParticipantsService.removeParticipant(connectedUser, from: conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        await userSession!.managedObjectContext.perform {
            // then
            XCTAssertFalse(conversation.localParticipants.contains(connectedUser))
        }

        // Tear down & recreate contexts
        recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(login())

        // then
        await userSession!.managedObjectContext.perform { [self] in
            XCTAssertFalse(
                self.conversation(for: groupConversation)!.localParticipants
                    .contains(user(for: user2)!)
            )
        }
    }

    func testThatNotificationsAreReceivedWhenConversationsAreFaulted() throws {
        // given
        XCTAssertTrue(login())

        // I am faulting conversation, will maintain the "message" relations as faulted
        let conversationList: ConversationList = .conversations(inUserSession: userSession!)
        let conversation1 = try XCTUnwrap(conversation(for: selfToUser1Conversation))
        let previousIndex = try XCTUnwrap(conversationList.items.firstIndex(of: conversation1))

        XCTAssertEqual(conversationList.items.count, 5)

        let observer = ConversationListChangeObserver(conversationList: conversationList)

        // when
        mockTransportSession.performRemoteChanges { _ in
            let message =
                GenericMessage(
                    content: Text(content: "some message", mentions: [], linkPreviews: [], replyingTo: nil),
                    nonce: UUID.create()
                )
            self.selfToUser1Conversation.encryptAndInsertData(
                from: self.user1.clients.anyObject() as! MockUserClient,
                to: self.selfUser.clients.anyObject() as! MockUserClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let note1 = observer?.notifications.lastObject as! ConversationListChangeInfo
        XCTAssertEqual(note1.zm_movedIndexPairs.first, ZMMovedIndex(from: UInt(previousIndex), to: 0))
    }
}

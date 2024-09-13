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

class ConversationTests_ClearingHistory: ConversationTestsBase {
    func loginAndFillConversationWithMessages(mockConversation: MockConversation, messagesCount: UInt) {
        XCTAssertTrue(login())

        var conversation = conversation(for: mockConversation)
        let otherUser = mockConversation.activeUsers.first { ($0 as? MockUser) != self.selfUser } as! MockUser

        // given
        let fromClient = otherUser.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        mockTransportSession.performRemoteChanges { _ in
            // If the client is not registered yet we need to account for the added System Message
            for i in 0 ..< (Int(messagesCount) - conversation!.allMessages.count) {
                let message =
                    GenericMessage(
                        content: Text(
                            content: "foo" + String(i),
                            mentions: [],
                            linkPreviews: [],
                            replyingTo: nil
                        ),
                        nonce: UUID.create()
                    )
                mockConversation.encryptAndInsertData(
                    from: fromClient,
                    to: toClient,
                    data: try! message.serializedData()
                )
            }
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        conversation = self.conversation(for: mockConversation)
        conversation?.markAsRead()

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation!.allMessages.count, Int(messagesCount))
    }

    func testThatItRemovesMessagesAfterReceivingAPushEventToClearHistory() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        var conversation = conversation(for: groupConversation!)

        let conversationDirectory = userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        // when removing messages remotely

        remotelyAppendSelfConversationWithZMCleared(
            for: groupConversation,
            at: conversation!.lastServerTimeStamp!
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when adding new messages
        userSession?.perform {
            self
                .spinMainQueue(withTimeout: 1) // if the message is sent within the same second of clearing the window,
            // it will not be added when resyncing
            let message = try! conversation?.appendText(content: "lalala")
            conversation?.markMessagesAsRead(until: message!)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation?.allMessages.count, 1)

        recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Wait for sync to be done
        XCTAssertTrue(login())

        // then
        conversation = self.conversation(for: groupConversation!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let objectIDs = conversationDirectory?.conversationsIncludingArchived.items.map(\.objectID)
        XCTAssertTrue(objectIDs!.contains(conversationID!))
    }

    func testThatDeletedConversationsStayDeletedAfterResyncing() throws {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)

        var conversation = try conversation(for: XCTUnwrap(groupConversation))
        XCTAssertEqual(conversation!.allMessages.count, 5)

        let conversationDirectory = userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        // when deleting the conversation remotely

        mockTransportSession.performRemoteChanges { _ in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        remotelyAppendSelfConversationWithZMCleared(
            for: groupConversation,
            at: conversation!.lastServerTimeStamp!
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversation!.allMessages.count, 0)
        XCTAssertFalse(conversationDirectory!.conversationsIncludingArchived.items.contains(conversation!))

        conversation = nil
        recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // Wait for sync to be done
        XCTAssertTrue(login())

        // then
        conversation = self.conversation(for: groupConversation!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let conversationsIncludingArchivedObjectIDs = conversationDirectory?.conversationsIncludingArchived.items
            .map(\.objectID)
        let archivedConversationsObjectIDs = conversationDirectory?.archivedConversations.items.map(\.objectID)
        let clearedConversationsObjectIDs = conversationDirectory?.clearedConversations.items.map(\.objectID)
        XCTAssertFalse(conversationsIncludingArchivedObjectIDs!.contains(conversationID!))
        XCTAssertFalse(archivedConversationsObjectIDs!.contains(conversationID!))
        XCTAssertTrue(clearedConversationsObjectIDs!.contains(conversationID!))
    }

    func testFirstArchivingThenClearingRemotelyShouldDeleteConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        let conversation = conversation(for: groupConversation!)

        let conversationDirectory = userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        mockTransportSession.performRemoteChanges { _ in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        remotelyAppendSelfConversationWithZMCleared(
            for: groupConversation,
            at: conversation!.lastServerTimeStamp!
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let objectIDs = conversationDirectory?.conversationsIncludingArchived.items.map(\.objectID)
        XCTAssertFalse(objectIDs!.contains(conversationID!))
    }

    func testFirstClearingThenArchivingRemotelyShouldDeleteConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        let conversation = conversation(for: groupConversation!)

        let conversationDirectory = userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        remotelyAppendSelfConversationWithZMCleared(
            for: groupConversation,
            at: conversation!.lastServerTimeStamp!
        )
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        mockTransportSession.performRemoteChanges { _ in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let objectIDs = conversationDirectory?.conversationsIncludingArchived.items.map(\.objectID)
        XCTAssertFalse(objectIDs!.contains(conversationID!))
    }

    func testThatRemotelyArchivedConversationIsIncludedInTheCorrectConversationLists() throws {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        let conversation = try XCTUnwrap(conversation(for: groupConversation!))

        let conversationDirectory = userSession?.managedObjectContext.conversationListDirectory()

        // when archiving the conversation remotely
        mockTransportSession.performRemoteChanges { _ in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(conversationDirectory!.conversationsIncludingArchived.items.contains(conversation))
        XCTAssertTrue(conversationDirectory!.archivedConversations.items.contains(conversation))
        XCTAssertFalse(conversationDirectory!.clearedConversations.items.contains(conversation))
    }

    func testThatRemotelyArchivedConversationIsIncludedInTheCorrectConversationListsAfterResyncing() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        var conversation = conversation(for: groupConversation!)

        let conversationDirectory = userSession?.managedObjectContext.conversationListDirectory()
        let conversationID = conversation?.objectID

        // when deleting the conversation remotely, whiping the cache and resyncing
        mockTransportSession.performRemoteChanges { _ in
            self.groupConversation.remotelyArchive(from: self.selfUser, referenceDate: Date())
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        recreateSessionManagerAndDeleteLocalData()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(login())

        // then
        conversation = self.conversation(for: groupConversation!)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        let conversationsIncludingArchivedObjectIDs = conversationDirectory?.conversationsIncludingArchived.items
            .map(\.objectID)
        let archivedConversationsObjectIDs = conversationDirectory?.archivedConversations.items.map(\.objectID)
        let clearedConversationsObjectIDs = conversationDirectory?.clearedConversations.items.map(\.objectID)
        XCTAssertTrue(conversationsIncludingArchivedObjectIDs!.contains(conversationID!))
        XCTAssertTrue(archivedConversationsObjectIDs!.contains(conversationID!))
        XCTAssertFalse(clearedConversationsObjectIDs!.contains(conversationID!))
    }

    func testThatReceivingRemoteTextMessageRevealsClearedConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        var conversation = conversation(for: groupConversation!)

        userSession?.perform {
            conversation?.clearMessageHistory()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when
        mockTransportSession.performRemoteChanges { _ in
            self
                .spinMainQueue(withTimeout: 1) // if the action happens within the same second the user clears the
            // history, the event is not added
            let message = GenericMessage(
                content: Text(content: "foo", mentions: [], linkPreviews: [], replyingTo: nil),
                nonce: UUID.create()
            )
            self.groupConversation.encryptAndInsertData(
                from: self.user2.clients.anyObject() as! MockUserClient,
                to: self.selfUser.clients.anyObject() as! MockUserClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        conversation = self.conversation(for: groupConversation!)
        XCTAssertEqual(conversation!.allMessages.count, 1)
        XCTAssertFalse(conversation!.isArchived)
    }

    func testThatReceivingRemoteSystemMessageRevealsClearedConversation() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        var conversation = conversation(for: groupConversation!)

        userSession?.perform {
            conversation?.clearMessageHistory()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when
        mockTransportSession.performRemoteChanges { _ in
            self
                .spinMainQueue(withTimeout: 1) // if the action happens within the same second the user clears the
            // history, the event is not added
            self.groupConversation.removeUsers(by: self.user2, removedUser: self.user3)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        conversation = self.conversation(for: groupConversation!)

        XCTAssertEqual(conversation!.allMessages.count, 1)
        XCTAssertTrue(conversation!.isArchived)
    }

    func testThatOpeningClearedConversationRevealsIt() {
        // given
        let messagesCount: UInt = 5
        loginAndFillConversationWithMessages(mockConversation: groupConversation, messagesCount: messagesCount)
        var conversation = conversation(for: groupConversation!)

        userSession?.perform {
            conversation?.clearMessageHistory()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversation!.allMessages.count, 0)

        // when
        userSession?.perform {
            conversation?.revealClearedConversation()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        conversation = self.conversation(for: groupConversation!)
        XCTAssertEqual(conversation!.allMessages.count, 0)
        XCTAssertFalse(conversation!.isArchived)
    }
}

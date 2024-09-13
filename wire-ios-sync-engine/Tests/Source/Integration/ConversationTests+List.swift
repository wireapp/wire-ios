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

class ConversationTests_List: ConversationTestsBase {
    func testThatTheConversationListOrderIsUpdatedAsWeReceiveMessages() throws {
        XCTAssertTrue(login())

        // given
        var mockExtraConversation: MockConversation?

        let user1 = try XCTUnwrap(user1)
        let user2 = try XCTUnwrap(user2)
        mockTransportSession.performRemoteChanges { session in
            mockExtraConversation = session.insertGroupConversation(
                withSelfUser: self.selfUser,
                otherUsers: [user1, user2]
            )
            mockExtraConversation?.changeName(by: self.selfUser, name: "Extra conversation")
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // when
        let extraConversation = conversation(for: mockExtraConversation!)
        let groupConversation = conversation(for: groupConversation)

        // then
        let conversations: ConversationList = .conversations(inUserSession: userSession!)
        XCTAssertEqual(conversations.items.first, extraConversation)

        let observer = ConversationListChangeObserver(conversationList: conversations)

        // when
        mockTransportSession.performRemoteChanges { _ in
            let message =
                GenericMessage(
                    content: Text(content: "Bla bla bla", mentions: [], linkPreviews: [], replyingTo: nil),
                    nonce: UUID.create()
                )
            let fromUser = self.groupConversation.activeUsers.lastObject as! MockUser
            self.groupConversation.encryptAndInsertData(
                from: fromUser.clients.anyObject() as! MockUserClient,
                to: self.selfUser.clients.anyObject() as! MockUserClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversations.items.first, groupConversation)

        XCTAssertGreaterThanOrEqual(observer!.notifications.count, 1)

        var updatesCount = 0
        var moves: [ZMMovedIndex] = []
        for note in observer!.notifications {
            guard let note = note as? ConversationListChangeInfo else {
                return
            }
            updatesCount += note.updatedIndexes.count
            // should be no deletions
            XCTAssertEqual(note.deletedIndexes.count, 0)
            moves.append(contentsOf: note.zm_movedIndexPairs)
        }
        XCTAssertEqual(moves.count, 1)
        XCTAssertEqual(moves.first?.to, 0)
    }

    func testThatLatestConversationIsAlwaysOnTop() throws {
        // given
        XCTAssertTrue(login())

        let conversationList: ConversationList = .conversations(inUserSession: userSession!)
        let conversation1 = try XCTUnwrap(conversation(for: selfToUser1Conversation))
        _ = conversation1.allMessages // Make sure we've faulted in the messages
        let conversation2 = try XCTUnwrap(conversation(for: selfToUser2Conversation))
        _ = conversation2.allMessages // Make sure we've faulted in the messages

        let toClient = selfUser.clients.anyObject() as! MockUserClient

        let messageText1 = "some message"
        let messageText2 = "some other message"
        let messageText3 = "some third message"

        let nonce1 = UUID.create()
        let nonce2 = UUID.create()
        let nonce3 = UUID.create()

        // when
        let observer = ConversationListChangeObserver(conversationList: conversationList)
        observer?.clearNotifications()
        let previousIndex1 = try XCTUnwrap(conversationList.items.firstIndex(of: conversation1))

        mockTransportSession.performRemoteChanges { _ in
            let message =
                GenericMessage(
                    content: Text(content: messageText1, mentions: [], linkPreviews: [], replyingTo: nil),
                    nonce: nonce1
                )
            self.selfToUser1Conversation.encryptAndInsertData(
                from: self.user1.clients.anyObject() as! MockUserClient,
                to: toClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversationList.items[0], conversation1)
        XCTAssertGreaterThanOrEqual(observer!.notifications.count, 1)
        let note1 = observer?.notifications.lastObject as! ConversationListChangeInfo
        XCTAssertEqual(note1.zm_movedIndexPairs.first, ZMMovedIndex(from: UInt(previousIndex1), to: 0))

        let receivedMessage1 = conversation1.lastMessage
        XCTAssertEqual(receivedMessage1?.textMessageData?.messageText, messageText1)
        let previousIndex2 = try XCTUnwrap(conversationList.items.firstIndex(of: conversation2))

        // send second message
        mockTransportSession.performRemoteChanges { _ in
            let message =
                GenericMessage(
                    content: Text(content: messageText2, mentions: [], linkPreviews: [], replyingTo: nil),
                    nonce: nonce2
                )
            self.selfToUser2Conversation.encryptAndInsertData(
                from: self.user2.clients.anyObject() as! MockUserClient,
                to: toClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversationList.items[0], conversation2)
        XCTAssertGreaterThanOrEqual(observer!.notifications.count, 2)
        let note2 = observer?.notifications[1] as! ConversationListChangeInfo
        XCTAssertEqual(note2.zm_movedIndexPairs.first, ZMMovedIndex(from: UInt(previousIndex2), to: 0))

        let receivedMessage2 = conversation2.lastMessage
        XCTAssertEqual(receivedMessage2?.textMessageData?.messageText, messageText2)
        let previousIndex3 = try XCTUnwrap(conversationList.items.firstIndex(of: conversation1))

        // send first message again

        mockTransportSession.performRemoteChanges { _ in
            let message =
                GenericMessage(
                    content: Text(content: messageText3, mentions: [], linkPreviews: [], replyingTo: nil),
                    nonce: nonce3
                )
            self.selfToUser1Conversation.encryptAndInsertData(
                from: self.user1.clients.anyObject() as! MockUserClient,
                to: toClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversationList.items[0], conversation1)
        XCTAssertGreaterThanOrEqual(observer!.notifications.count, 3)
        let note3 = observer?.notifications.lastObject as! ConversationListChangeInfo
        XCTAssertEqual(note3.zm_movedIndexPairs.first, ZMMovedIndex(from: UInt(previousIndex3), to: 0))

        let receivedMessage3 = conversation1.lastMessage
        XCTAssertEqual(receivedMessage3?.textMessageData?.messageText, messageText3)
    }

    func testThatReceivingAPingInAConversationThatIsNotAtTheTopBringsItToTheTop() throws {
        // given
        XCTAssertTrue(login())

        let conversationList: ConversationList = .conversations(inUserSession: userSession!)
        let conversationListChangeObserver = ConversationListChangeObserver(conversationList: conversationList)

        let oneToOneConversation = conversation(for: selfToUser1Conversation)

        // make sure oneToOneConversation is not on top
        mockTransportSession.performRemoteChanges { _ in
            let knock = GenericMessage(content: Knock.with { $0.hotKnock = false }, nonce: UUID.create())
            self.selfToUser2Conversation.encryptAndInsertData(
                from: self.user2.clients.anyObject() as! MockUserClient,
                to: self.selfUser.clients.anyObject() as! MockUserClient,
                data: try! knock.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        conversationListChangeObserver?.clearNotifications()
        XCTAssertNotEqual(oneToOneConversation, conversationList.items[0]) // make sure conversation is not on top

        let oneToOneIndex = try XCTUnwrap(conversationList.items.firstIndex(of: oneToOneConversation!))

        // when
        mockTransportSession.performRemoteChanges { _ in
            let knock = GenericMessage(content: Knock.with { $0.hotKnock = false }, nonce: UUID.create())
            self.selfToUser1Conversation.encryptAndInsertData(
                from: self.user1.clients.anyObject() as! MockUserClient,
                to: self.selfUser.clients.anyObject() as! MockUserClient,
                data: try! knock.serializedData()
            )
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(oneToOneConversation, conversationList.items[0]) // make sure conversation is not on top
        let note = conversationListChangeObserver?.notifications.lastObject as! ConversationListChangeInfo
        XCTAssertNotNil(note)

        var moves: [Int: Int] = [:]
        note.enumerateMovedIndexes { from, to in
            moves[from] = to
        }
        let expectedArray = [oneToOneIndex: 0]

        XCTAssertEqual(moves, expectedArray)
    }

    func testThatConversationGoesOnTopAfterARemoteUserAcceptsOurConnectionRequest() {
        // given
        XCTAssertTrue(login())

        let oneToOneConversation = conversation(for: selfToUser1Conversation)
        let mockUser = createSentConnection(fromUserWithName: "Hans", uuid: UUID.create())
        let newConnectionConversation = user(for: mockUser)?.oneToOneConversation

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let conversationList: ConversationList = .conversations(inUserSession: userSession!)

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

        XCTAssertEqual(oneToOneConversation, conversationList.items[0])
        let conversationListChangeObserver = ConversationListChangeObserver(conversationList: conversationList)

        // when
        mockTransportSession.performRemoteChanges { session in
            session.remotelyAcceptConnection(to: mockUser)
        }

        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertGreaterThanOrEqual(conversationListChangeObserver!.notifications.count, 1)

        var updatesCount = 0
        var moves: [ZMMovedIndex] = []
        for note in conversationListChangeObserver!.notifications {
            guard let note = note as? ConversationListChangeInfo else {
                return
            }
            updatesCount += note.updatedIndexes.count
            moves.append(contentsOf: note.zm_movedIndexPairs)
            XCTAssertTrue(note.updatedIndexes.contains(0))
            // should be no deletions
            XCTAssertEqual(note.deletedIndexes.count, 0)
            XCTAssertEqual(note.insertedIndexes.count, 0)
        }
        XCTAssertGreaterThanOrEqual(updatesCount, 1)
        XCTAssertEqual(moves.count, 1)
        XCTAssertEqual(moves.first?.to, 0)

        XCTAssertEqual(newConnectionConversation, conversationList.items[0])
        XCTAssertEqual(oneToOneConversation, conversationList.items[1])
    }
}

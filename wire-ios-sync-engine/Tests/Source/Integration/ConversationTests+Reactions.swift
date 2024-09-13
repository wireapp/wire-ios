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

class ConversationTests_Reactions: ConversationTestsBase {
    func testThatAppendingAReactionWithReceivingAMessageWithReaction() {
        XCTAssert(login())

        // given
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        var message: ZMMessage?
        userSession?.perform {
            message = try! conversation?.appendText(content: "Je t'aime JCVD") as? ZMMessage
        }
        let nonce = message?.nonce
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let reactionEmoji = "❤️"
        let reactionMessage = GenericMessage(
            content: ProtosReactionFactory
                .createReaction(emojis: [reactionEmoji], messageID: nonce!) as MessageCapable,
            nonce: UUID.create()
        )
        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        // when
        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! reactionMessage.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message!.usersReaction.count, 1)
        XCTAssertNotNil(message?.usersReaction[reactionEmoji])
        XCTAssertEqual(message!.usersReaction[reactionEmoji]!.count, 1)
        XCTAssert(message!.usersReaction[reactionEmoji]?.first === user(for: user1))
        XCTAssertEqual(conversation!.hiddenMessages.count, 0)
    }

    func testThatAppendingAReactionNotifiesObserverOfChangesInReactionsWhenExternalUserReact() {
        // given
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        var message: ZMMessage?
        userSession?.perform {
            message = try! conversation?.appendText(content: "Je t'aime JCVD") as? ZMMessage
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let reactionEmoji = "❤️"
        userSession?.perform {
            ZMMessage.addReaction(reactionEmoji, to: message!)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let observer = MessageChangeObserver(message: message)
        let reactionMessage = GenericMessage(
            content: ProtosReactionFactory
                .createReaction(emojis: [reactionEmoji], messageID: message!.nonce!) as MessageCapable,
            nonce: UUID.create()
        )

        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        // when
        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! reactionMessage.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertGreaterThanOrEqual(observer!.notifications.count, 1)
        let changes = observer?.notifications.lastObject as! MessageChangeInfo
        XCTAssertTrue(changes.reactionsChanged)
    }

    func testThatReceivingAReactionThatIsNotHandledDoesntSaveIt() {
        // given
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        var message: ZMMessage?
        userSession?.perform {
            message = try! conversation?.appendText(content: "Je t'aime JCVD") as? ZMMessage
        }
        let nonce = message?.nonce
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let reactionEmoji = "Jean Robert, j'ai mal aux pieds"
        let reactionMessage = GenericMessage(
            content: ProtosReactionFactory
                .createReaction(emojis: [reactionEmoji], messageID: nonce!) as MessageCapable,
            nonce: UUID.create()
        )
        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        // when
        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! reactionMessage.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message!.usersReaction.count, 0)
        XCTAssertEqual(message!.reactions.count, 0)
    }

    func testThatReceivingALikeInAClearedConversationDoesNotUnarchiveTheConversation() {
        // given
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        var message: ZMMessage?
        userSession?.perform {
            message = try! conversation?.appendText(content: "Je t'aime JCVD") as? ZMMessage
        }
        let nonce = message?.nonce
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let reactionEmoji = "❤️"
        let reactionMessage = GenericMessage(
            content: ProtosReactionFactory
                .createReaction(emojis: [reactionEmoji], messageID: nonce!) as MessageCapable,
            nonce: UUID.create()
        )
        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        // when
        userSession?.perform {
            conversation?.clearMessageHistory()
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(conversation!.isArchived)

        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! reactionMessage.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(conversation!.isArchived)
    }

    func testThatReceivingALikeInAnArchivedConversationDoesNotUnarchiveTheConversation() {
        // given
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        var message: ZMMessage?
        userSession?.perform {
            message = try! conversation?.appendText(content: "Je t'aime JCVD") as? ZMMessage
        }
        let nonce = message?.nonce
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let reactionEmoji = "❤️"
        let reactionMessage = GenericMessage(
            content: ProtosReactionFactory
                .createReaction(emojis: [reactionEmoji], messageID: nonce!) as MessageCapable,
            nonce: UUID.create()
        )
        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        // when
        userSession?.perform {
            conversation?.isArchived = true
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertTrue(conversation!.isArchived)

        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! reactionMessage.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(conversation!.isArchived)
    }

    func testThatMessageDeletedForMyselfDoesNotAppearWhenLikedBySomeoneElse() {
        // given
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        var message: ZMMessage?
        userSession?.perform {
            message = try! conversation?.appendText(content: "Je t'aime JCVD") as? ZMMessage
        }
        let nonce = message?.nonce
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        userSession?.perform {
            ZMMessage.hideMessage(message!)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertNil(ZMMessage.fetch(withNonce: nonce, for: conversation!, in: userSession!.managedObjectContext))

        let reactionEmoji = "❤️"
        let reactionMessage = GenericMessage(
            content: ProtosReactionFactory
                .createReaction(emojis: [reactionEmoji], messageID: nonce!) as MessageCapable,
            nonce: UUID.create()
        )
        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        // when
        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! reactionMessage.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertNil(ZMMessage.fetch(withNonce: nonce, for: conversation!, in: userSession!.managedObjectContext))
    }

    func testThatWeCanLikeAMessageAfterItWasEditedByItsUser() {
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        let nonce = UUID.create()
        var message =
            GenericMessage(
                content: Text(
                    content: "JCVD is the best actor known",
                    mentions: [],
                    linkPreviews: [],
                    replyingTo: nil
                ),
                nonce: nonce
            )

        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        message =
            GenericMessage(
                content: Text(
                    content: "JCVD is the best actor known in the galaxy!",
                    mentions: [],
                    linkPreviews: [],
                    replyingTo: nil
                ),
                nonce: UUID.create()
            )

        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! message.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let editedMessage = ZMMessage.fetch(
            withNonce: nonce,
            for: conversation!,
            in: userSession!.managedObjectContext
        )

        // when
        userSession?.perform {
            ZMMessage.addReaction("🥰", to: editedMessage!)
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(editedMessage!.usersReaction.count, 1)
    }

    func testThatWeSeeLikeFromBlockedUserInGroupConversation() {
        XCTAssertTrue(login())

        prefetchClientByInsertingMessage(in: selfToUser1Conversation)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let mockConversation = selfToUser1Conversation
        let conversation = conversation(for: mockConversation!)

        let blockedUser = user(for: user1)
        blockedUser?.block(completion: { _ in })
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        var message: ZMMessage?
        userSession?.perform {
            message = try! conversation?.appendText(content: "Je t'aime JCVD") as? ZMMessage
        }
        let nonce = message?.nonce
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let reactionEmoji = "❤️"
        let reactionMessage = GenericMessage(
            content: ProtosReactionFactory
                .createReaction(emojis: [reactionEmoji], messageID: nonce!) as MessageCapable,
            nonce: UUID.create()
        )
        let fromClient = user1.clients.anyObject() as! MockUserClient
        let toClient = selfUser.clients.anyObject() as! MockUserClient

        // when
        mockTransportSession.performRemoteChanges { _ in
            mockConversation!.encryptAndInsertData(
                from: fromClient,
                to: toClient,
                data: try! reactionMessage.serializedData()
            )
        }
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message!.usersReaction.count, 1)
    }
}

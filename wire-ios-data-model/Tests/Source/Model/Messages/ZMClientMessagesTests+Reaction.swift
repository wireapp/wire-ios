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

import WireTesting

class ZMClientMessageTests_Reaction: BaseZMClientMessageTests {}

extension ZMClientMessageTests_Reaction {
    // MARK: Helper Methods

    func insertMessage() -> ZMMessage {
        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = .create()

        let message = try! conversation.appendText(content: "JCVD, full split please") as! ZMMessage
        message.sender = sender
        uiMOC.saveOrRollback()

        return message
    }

    func updateEventForAddingReaction(to message: ZMMessage, sender: ZMUser? = nil) -> ZMUpdateEvent {
        let sender = sender ?? message.sender!
        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: ["❤️"],
            messageID: message.nonce!
        ))
        let event = createUpdateEvent(
            UUID(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage,
            senderID: sender.remoteIdentifier!
        )
        return event
    }

    func updateEventForRemovingReaction(to message: ZMMessage, sender: ZMUser? = nil) -> ZMUpdateEvent {
        let sender = sender ?? message.sender!
        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: [],
            messageID: message.nonce!
        ))
        let event = createUpdateEvent(
            UUID(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage,
            senderID: sender.remoteIdentifier!
        )
        return event
    }

    // MARK: - Tests

    func testThatItAppendsAllOfTheReactionsWhenReceivingUpdateEventWithReactions() {
        // GIVEN
        let message = insertMessage()
        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: ["🥰", "😃", "❤️", "😍"],
            messageID: message.nonce!
        ))
        let event = createUpdateEvent(
            UUID(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage,
            senderID: message.sender!.remoteIdentifier!
        )

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(message.otherUsersReactions(), ["🥰", "😃", "❤️", "😍"])
    }

    func testThatItAppendsAReactionWhenReceivingUpdateEventWithValidReaction() {
        let message = insertMessage()
        let event = updateEventForAddingReaction(to: message)

        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(message.otherUsersReactions(), ["❤️"])
    }

    func testThatItUpdatesTheCategoryWhenAddingAReaction() {
        let message = insertMessage()
        message.markAsSent()
        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertFalse(message.cachedCategory.contains(.reacted))

        let event = updateEventForAddingReaction(to: message, sender: ZMUser.selfUser(in: uiMOC))

        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertTrue(message.cachedCategory.contains(.reacted))
    }

    func testThatItDoesNOTAppendsAReactionWhenReceivingUpdateEventWithInvalidReaction() {
        let message = insertMessage()
        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: ["TROP BIEN"],
            messageID: message.nonce!
        ))
        let event = createUpdateEvent(
            UUID(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage,
            senderID: message.sender!.remoteIdentifier!
        )

        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        XCTAssertEqual(message.reactions.count, 0)
        XCTAssertEqual(message.usersReaction.count, 0)
    }

    func testThatItDoesNOTAppendsAnInvalidReactionWhenReceivingUpdateEventWithMultipleReactions() {
        // GIVEN
        let message = insertMessage()
        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: ["TROP BIEN", "😃", "❤️", "😍"],
            messageID: message.nonce!
        ))
        let event = createUpdateEvent(
            UUID(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage,
            senderID: message.sender!.remoteIdentifier!
        )

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(message.otherUsersReactions(), ["😃", "❤️", "😍"])
    }

    func testThatItRemovesAReactionWhenReceivingUpdateEventWithValidReaction() {
        let message = insertMessage()
        ZMMessage.addReaction("❤️", to: message)
        uiMOC.saveOrRollback()

        let event = updateEventForRemovingReaction(to: message)

        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(message.usersReaction.count, 0)
    }

    func testThatItUpdatesTheCategoryWhenRemovingAReaction() {
        // given
        let message = insertMessage()
        message.markAsSent()

        ZMMessage.addReaction("❤️", to: message)
        uiMOC.saveOrRollback()
        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertTrue(message.cachedCategory.contains(.reacted))

        let event = updateEventForRemovingReaction(to: message, sender: ZMUser.selfUser(in: uiMOC))

        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertTrue(message.cachedCategory.contains(.text))
        XCTAssertFalse(message.cachedCategory.contains(.reacted))
    }

    func testThatAMessageWithReactionsWhenReceivingUpdateEventWithNoReactionsRemovesAllReactions() {
        // GIVEN
        let message = insertMessage()
        ZMMessage.addReaction("❤️", to: message)
        ZMMessage.addReaction("😍", to: message)
        uiMOC.saveOrRollback()

        let event = updateEventForRemovingReaction(to: message)

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(message.usersReaction.count, 0)
    }

    func testThatAMessageWithReactionsWhenReceivingUpdateEventWithNewReactionsUpdatesReactions() {
        // GIVEN
        let message = insertMessage()
        ZMMessage.addReaction("❤️", to: message)
        ZMMessage.addReaction("😍", to: message)
        uiMOC.saveOrRollback()

        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: ["🥰", "😃", "❤️", "😍"],
            messageID: message.nonce!
        ))

        let event = createUpdateEvent(
            UUID(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage,
            senderID: message.sender!.remoteIdentifier!
        )

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(message.otherUsersReactions(), ["🥰", "😃", "❤️", "😍"])
    }

    func testThatAMessageWithAReactionWhenReceivingUpdateEventWithANewReactionItOnlyContainsTheNewReaction() {
        // GIVEN
        let message = insertMessage()
        ZMMessage.addReaction("❤️", to: message)
        uiMOC.saveOrRollback()

        let genericMessage = GenericMessage(content: WireProtos.Reaction.createReaction(
            emojis: ["🥰"],
            messageID: message.nonce!
        ))

        let event = createUpdateEvent(
            UUID(),
            conversationID: conversation.remoteIdentifier!,
            genericMessage: genericMessage,
            senderID: message.sender!.remoteIdentifier!
        )

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.createOrUpdate(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // THEN
        XCTAssertEqual(message.otherUsersReactions(), ["🥰"])
    }
}

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
@testable import WireDataModel

class ZMMessageTests_Removal: BaseZMClientMessageTests {
    func testThatAMessageIsRemovedWhenAskForDeletionWithMessageHide() {
        // GIVEN

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let nonce = UUID.create()
        var textMessage: TextMessage? = TextMessage(nonce: nonce, managedObjectContext: uiMOC)
        textMessage?.visibleInConversation = conversation

        let hidden = MessageHide.with {
            $0.conversationID = conversation.remoteIdentifier!.transportString()
            $0.messageID = nonce.transportString()
        }

        // sanity check
        XCTAssertNotNil(textMessage)
        uiMOC.saveOrRollback()

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMMessage.remove(remotelyHiddenMessage: hidden, inContext: self.uiMOC)
        }
        uiMOC.saveOrRollback()

        // THEN
        textMessage = TextMessage.fetch(withNonce: nonce, for: conversation, in: uiMOC)
        XCTAssertNil(textMessage)
        XCTAssertEqual(conversation.allMessages.count, 0)
    }

    func testThatItDeletesTheMessageWithDelete() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let nonce = UUID.create()
        var textMessage: TextMessage? = TextMessage(nonce: nonce, managedObjectContext: uiMOC)
        textMessage?.sender = sender
        textMessage?.visibleInConversation = conversation

        let deleted = MessageDelete.with {
            $0.messageID = nonce.transportString()
        }

        // sanity check
        XCTAssertNotNil(textMessage)
        uiMOC.saveOrRollback()

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMMessage.remove(
                remotelyDeletedMessage: deleted,
                inConversation: conversation,
                senderID: textMessage!.sender!.remoteIdentifier,
                inContext: self.uiMOC
            )
        }
        uiMOC.saveOrRollback()

        // THEN
        textMessage = TextMessage.fetch(withNonce: nonce, for: conversation, in: uiMOC)
        XCTAssertTrue(textMessage?.hasBeenDeleted ?? false)
    }

    func testThatItIgnoresDeleteWhenFromOtherUser() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let nonce = UUID.create()
        var textMessage: TextMessage? = TextMessage(nonce: nonce, managedObjectContext: uiMOC)
        textMessage?.sender = sender
        textMessage?.visibleInConversation = conversation

        let deleted = MessageDelete.with {
            $0.messageID = nonce.transportString()
        }

        // sanity check
        XCTAssertNotNil(textMessage)
        uiMOC.saveOrRollback()

        // WHEN
        performPretendingUiMocIsSyncMoc {
            ZMMessage.remove(
                remotelyDeletedMessage: deleted,
                inConversation: conversation,
                senderID: UUID.create(),
                inContext: self.uiMOC
            )
        }
        uiMOC.saveOrRollback()

        // THEN
        textMessage = TextMessage.fetch(withNonce: nonce, for: conversation, in: uiMOC)
        XCTAssertFalse(textMessage?.hasBeenDeleted ?? true)
    }

    func testThatItDoesNotDeleteTheDeletedMessageWithDelete() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let sender = ZMUser.insertNewObject(in: uiMOC)
        sender.remoteIdentifier = UUID.create()

        let nonce = UUID.create()
        var textMessage: TextMessage? = TextMessage(nonce: nonce, managedObjectContext: uiMOC)
        textMessage?.sender = sender
        textMessage?.hiddenInConversation = conversation

        XCTAssertTrue(textMessage!.hasBeenDeleted)

        let deleted = MessageDelete.with {
            $0.messageID = nonce.transportString()
        }

        // sanity check
        XCTAssertNotNil(textMessage)
        uiMOC.saveOrRollback()

        // WHEN
        performPretendingUiMocIsSyncMoc {
            self.performIgnoringZMLogError {
                ZMMessage.remove(
                    remotelyDeletedMessage: deleted,
                    inConversation: conversation,
                    senderID: textMessage!.sender!.remoteIdentifier,
                    inContext: self.uiMOC
                )
            }
        }
        uiMOC.saveOrRollback()

        // THEN
        textMessage = TextMessage.fetch(withNonce: nonce, for: conversation, in: uiMOC)
        XCTAssertTrue(textMessage?.hasBeenDeleted ?? false)
    }

    func testThatAClientMessageIsRemovedWhenAskForDeletion() throws {
        // when
        let removed = try checkThatAMessageIsRemoved { () -> ZMMessage in
            ZMClientMessage(nonce: UUID.create(), managedObjectContext: self.uiMOC)
        }
        // then
        XCTAssertTrue(removed)
    }

    // Returns whether the message was deleted
    private func checkThatAMessageIsRemoved(messageCreationBlock: () -> ZMMessage) throws -> Bool {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let testMessage = messageCreationBlock()
        testMessage.visibleInConversation = conversation

        // sanity check
        XCTAssertNotNil(conversation)
        XCTAssertNotNil(testMessage)
        uiMOC.saveOrRollback()

        // when
        performPretendingUiMocIsSyncMoc {
            testMessage.removeClearingSender(true)
        }
        uiMOC.saveOrRollback()

        // then
        let fetchedMessage = try XCTUnwrap(ZMMessage.fetch(
            withNonce: testMessage.nonce,
            for: conversation,
            in: uiMOC
        ))
        var removed = fetchedMessage.visibleInConversation == nil && fetchedMessage
            .hiddenInConversation == conversation && fetchedMessage.sender == nil

        if fetchedMessage.isKind(of: ZMClientMessage.self) {
            let clientMessage = fetchedMessage as! ZMClientMessage
            removed = clientMessage.dataSet.count == 0 && clientMessage.underlyingMessage == nil
        }

        return removed
    }

    func testThatATextMessageIsRemovedWhenAskForDeletion() throws {
        // when
        let removed = try checkThatAMessageIsRemoved { () -> ZMMessage in
            TextMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        }
        // then
        XCTAssertTrue(removed)
    }

    func testThatAnAssetClientMessageIsRemovedWhenAskForDeletion() throws {
        // when
        let removed = try checkThatAMessageIsRemoved { () -> ZMMessage in
            ZMAssetClientMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        }

        // then
        XCTAssertTrue(removed)
    }

    func testThatAnPreE2EETextMessageIsRemovedWhenAskedForDeletion() throws {
        // when
        let removed = try checkThatAMessageIsRemoved { () -> ZMMessage in
            TextMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        }
        // then
        XCTAssertTrue(removed)
    }

    func testThatAnPreE2EEImageMessageIsRemovedWhenAskedForDeletion() throws {
        // when
        let removed = try checkThatAMessageIsRemoved { () -> ZMMessage in
            ZMImageMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        }

        // then
        XCTAssertTrue(removed)
    }

    func testThatAnPreE2EEKnockMessageIsRemovedWhenAskedForDeletion() throws {
        // when
        let removed = try checkThatAMessageIsRemoved { () -> ZMMessage in
            ZMKnockMessage(nonce: UUID.create(), managedObjectContext: uiMOC)
        }

        // then
        XCTAssertTrue(removed)
    }
}

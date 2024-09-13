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
@testable import WireDataModel

class ZMMessage_Reaction: BaseZMClientMessageTests {
    func testThatAddingAReactionAddsAReactionGenericMessage_fromUI() {
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let message = try! conversation.appendText(content: name) as! ZMMessage
        message.markAsSent()
        uiMOC.saveOrRollback()

        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)

        // when
        // this is the UI facing call to add reaction
        ZMMessage.addReaction("❤️", to: message)
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(conversation.hiddenMessages.count, 1)
        let reactionMessage = conversation.hiddenMessages.first as! ZMClientMessage
        XCTAssertNotNil(reactionMessage)
        switch reactionMessage.underlyingMessage?.content {
        case let .reaction(data)?:
            XCTAssertNotNil(data)
        default:
            XCTFail()
        }
        XCTAssertEqual(reactionMessage.underlyingMessage!.reaction.emoji, "❤️")
    }

    func testThatSelfUserIsAbleToAddNewReactionToAMessageTheyAlreadyReactedTo() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let message = try! conversation.appendText(content: name) as! ZMMessage
        message.markAsSent()
        uiMOC.saveOrRollback()

        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)

        message.setReactions(["😋", "😍"], forUser: selfUser)
        XCTAssertEqual(message.selfUserReactions(), ["😋", "😍"])

        // WHEN
        ZMMessage.addReaction("😎", to: message)
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(message.selfUserReactions(), ["😋", "😍", "😎"])
    }

    func testThatSelfUserIsAbleToRemoveReactionFromMessageAndStillHaveAnotherReactionThere() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let message = try! conversation.appendText(content: name) as! ZMMessage
        message.markAsSent()
        uiMOC.saveOrRollback()

        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)

        message.setReactions(["😋", "😍"], forUser: selfUser)
        XCTAssertEqual(message.selfUserReactions(), ["😋", "😍"])

        // WHEN
        ZMMessage.removeReaction("😋", from: message)
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(message.selfUserReactions(), ["😍"])
    }

    func testThatEmptyReactionIsNotAddedToTheMessage() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()

        let message = try! conversation.appendText(content: name) as! ZMMessage
        message.markAsSent()
        uiMOC.saveOrRollback()

        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)

        message.setReactions(["😋", "😍"], forUser: selfUser)
        XCTAssertEqual(message.selfUserReactions(), ["😋", "😍"])

        // WHEN
        ZMMessage.addReaction("", to: message)
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(message.selfUserReactions(), ["😋", "😍"])
    }

    func testThatRemovingAReactionThatTheSelfUserDidNotReactDoesNothing() {
        // GIVEN
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.remoteIdentifier = UUID.create()
        let otherUser = ZMUser.insertNewObject(in: uiMOC)
        otherUser.remoteIdentifier = UUID.create()

        let message = try! conversation.appendText(content: name) as! ZMMessage
        message.markAsSent()
        uiMOC.saveOrRollback()

        XCTAssertEqual(message.deliveryState, ZMDeliveryState.sent)

        message.setReactions(["😋", "😍"], forUser: selfUser)
        message.setReactions(["😙"], forUser: otherUser)
        XCTAssertEqual(message.selfUserReactions(), ["😋", "😍"])

        // WHEN
        ZMMessage.removeReaction("😙", from: message)
        uiMOC.saveOrRollback()

        // THEN
        XCTAssertEqual(message.selfUserReactions(), ["😋", "😍"])
    }
}

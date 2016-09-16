//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

import ZMTesting

class ZMClientMessageTests_Reaction: BaseZMClientMessageTests {
    
    
}

extension ZMClientMessageTests_Reaction {
    
    func testThatItAppendsAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        
        let sender = ZMUser.insertNewObject(in:uiMOC)
        sender.remoteIdentifier = .create()
        
        let message = conversation.appendMessage(withText: "JCVD, full split please") as! ZMMessage
        message.sender = sender
        
        uiMOC.saveOrRollback()
        
        let genericMessage = ZMGenericMessage(emojiString: "❤️", messageID: message.nonce.transportString(), nonce: UUID.create().transportString())
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.messageUpdateResult(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        
        XCTAssertEqual(message.reactions.count, 1)
        XCTAssertEqual(message.usersReaction.count, 1)
    }
    
    func testThatItDoesNOTAppendsAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        
        let sender = ZMUser.insertNewObject(in:uiMOC)
        sender.remoteIdentifier = .create()
        
        let message = conversation.appendMessage(withText: "JCVD, full split please") as! ZMMessage
        message.sender = sender
        
        uiMOC.saveOrRollback()
        
        let genericMessage = ZMGenericMessage(emojiString: "TROP BIEN", messageID: message.nonce.transportString(), nonce: UUID.create().transportString())
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.messageUpdateResult(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        
        XCTAssertEqual(message.reactions.count, 0)
        XCTAssertEqual(message.usersReaction.count, 0)
    }
    
    func testThatItRemovesAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        conversation.remoteIdentifier = .create()
        conversation.conversationType = .oneOnOne
        
        let sender = ZMUser.insertNewObject(in:uiMOC)
        sender.remoteIdentifier = .create()
        
        let message = conversation.appendMessage(withText: "JCVD, full split please") as! ZMMessage
        message.sender = sender
        message.addReaction("❤️", forUser: sender)
        
        uiMOC.saveOrRollback()
        
        let genericMessage = ZMGenericMessage(emojiString: "", messageID: message.nonce.transportString(), nonce: UUID.create().transportString())
        let event = createUpdateEvent(UUID(), conversationID: conversation.remoteIdentifier!, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.messageUpdateResult(from: event, in: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        

        XCTAssertEqual(message.usersReaction.count, 0)
    }

}

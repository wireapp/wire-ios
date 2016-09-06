//
//  ZMClientMessagesTests+Reaction.swift
//  ZMCDataModel
//
//  Created by Florian Morel on 9/6/16.
//  Copyright © 2016 Wire Swiss GmbH. All rights reserved.
//

import ZMTesting

class ZMClientMessageTests_Reaction: BaseZMClientMessageTests {
    
    
}

extension ZMClientMessageTests_Reaction {
    
    func testThatItAppendsAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        conversation.conversationType = .OneOnOne
        
        let sender = ZMUser.insertNewObjectInManagedObjectContext(uiMOC)
        sender.remoteIdentifier = .createUUID()
        
        let message = conversation.appendMessageWithText("JCVD, full split please") as! ZMMessage
        message.sender = sender
        
        uiMOC.saveOrRollback()
        
        let genericMessage = ZMGenericMessage(emojiString: "❤️", messageID: message.nonce.transportString(), nonce: NSUUID.createUUID().transportString())
        let event = createUpdateEvent(NSUUID(), conversationID: conversation.remoteIdentifier, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.messageUpdateResultFromUpdateEvent(event, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        
        XCTAssertEqual(message.reactions.count, 1)
        XCTAssertEqual(message.usersReaction.count, 1)
    }
    
    func testThatItDoesNOTAppendsAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        conversation.conversationType = .OneOnOne
        
        let sender = ZMUser.insertNewObjectInManagedObjectContext(uiMOC)
        sender.remoteIdentifier = .createUUID()
        
        let message = conversation.appendMessageWithText("JCVD, full split please") as! ZMMessage
        message.sender = sender
        
        uiMOC.saveOrRollback()
        
        let genericMessage = ZMGenericMessage(emojiString: "TROP BIEN", messageID: message.nonce.transportString(), nonce: NSUUID.createUUID().transportString())
        let event = createUpdateEvent(NSUUID(), conversationID: conversation.remoteIdentifier, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.messageUpdateResultFromUpdateEvent(event, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        
        XCTAssertEqual(message.reactions.count, 0)
        XCTAssertEqual(message.usersReaction.count, 0)
    }
    
    func testThatItRemovesAReactionWhenReceivingUpdateEventWithValidReaction() {
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        conversation.conversationType = .OneOnOne
        
        let sender = ZMUser.insertNewObjectInManagedObjectContext(uiMOC)
        sender.remoteIdentifier = .createUUID()
        
        let message = conversation.appendMessageWithText("JCVD, full split please") as! ZMMessage
        message.sender = sender
        message.addReaction("❤️", forUser: sender)
        
        uiMOC.saveOrRollback()
        
        let genericMessage = ZMGenericMessage(emojiString: "", messageID: message.nonce.transportString(), nonce: NSUUID.createUUID().transportString())
        let event = createUpdateEvent(NSUUID(), conversationID: conversation.remoteIdentifier, genericMessage: genericMessage, senderID: sender.remoteIdentifier!)
        
        // when
        performPretendingUiMocIsSyncMoc {
            ZMClientMessage.messageUpdateResultFromUpdateEvent(event, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        

        XCTAssertEqual(message.usersReaction.count, 0)
    }

}

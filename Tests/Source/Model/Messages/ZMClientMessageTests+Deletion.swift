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


import XCTest
@testable import ZMCDataModel

// MARK: - Sending

class ZMClientMessageTests_Deletion: BaseZMMessageTests {
    
    func testThatItDeletesAMessageFromTheManagedObjectContext() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        guard let sut = conversation.appendMessageWithText(name!) as? ZMMessage else { return XCTFail() }
        
        // when
        sut.deleteForEveryone()
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(sut.isZombieObject)
    }
    
    func testThatAMessageSentByAnotherUserCanotBeDeleted() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(uiMOC)
        guard let sut = conversation.appendMessageWithText(name!) as? ZMMessage else { return XCTFail() }
        sut.sender = otherUser
        
        // when
        sut.deleteForEveryone()
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(sut.isZombieObject)
    }
    
    func testThatTheInsertedDeleteMessageDoesNotHaveAnExpirationDate() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        let nonce = NSUUID.createUUID()
        let deletedMessage = ZMGenericMessage(deleteMessage: nonce.transportString(), nonce: NSUUID().transportString())
        
        // when
        let sut = conversation.appendNonExpiringGenericMessage(deletedMessage, hidden: true)
        
        // then
        XCTAssertNil(sut.expirationDate)
        XCTAssertEqual(sut.hiddenInConversation, conversation)
        XCTAssertNil(sut.visibleInConversation)
    }
}

// MARK: - System Messages

extension ZMClientMessageTests_Deletion {
    
    func testThatItDoesNotInsertASystemMessageIfTheMessageDoesNotExist() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.lastModifiedDate = NSDate(timeIntervalSince1970: 123456789)
        conversation.remoteIdentifier = .createUUID()
        
        // when
        let updateEvent = createMessageDeletedUpdateEvent(.createUUID(), conversationID: conversation.remoteIdentifier, senderID: selfUser.remoteIdentifier!)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        XCTAssertEqual(conversation.messages.count, 0)
    }
    
    func testThatItDoesNotInsertASystemMessageWhenAMessageIsDeletedForEveryoneLocally() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        guard let sut = conversation.appendMessageWithText(name!) else { return XCTFail() }
        
        // when
        ZMMessage.deleteForEveryone(sut)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(conversation.messages.count, 0)
    }
}

// MARK: - Receiving

extension ZMClientMessageTests_Deletion {

    func testThatAMessageCanNotBeDeletedByAUserThatDidNotInitiallySentIt() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.lastModifiedDate = NSDate(timeIntervalSince1970: 123456789)
        conversation.remoteIdentifier = .createUUID()
        guard let sut = conversation.appendMessageWithText(name!) as? ZMMessage else { return XCTFail() }

        // when
        let updateEvent = createMessageDeletedUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier)
        performPretendingUiMocIsSyncMoc { 
            ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertFalse(sut.isZombieObject)
        XCTAssertEqual(conversation.messages.count, 1)
        if let systemMessage = conversation.messages.lastObject as? ZMSystemMessage where systemMessage.systemMessageType == .MessageDeletedForEveryone {
            return XCTFail()
        }
    }
    
    func testThatAMessageCanBeDeletedByTheUserThatDidInitiallySentIt() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        guard let sut = conversation.appendMessageWithText(name!) as? ZMMessage else { return XCTFail() }

        // when
        let updateEvent = createMessageDeletedUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier, senderID: sut.sender!.remoteIdentifier!)

        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(sut.isZombieObject)
        // No system message as the selfUser was the sender
        XCTAssertEqual(conversation.messages.count, 0)
    }
    
    func testThatAMessageSentByAnotherUserCanBeDeletedAndASystemMessageIsInserted() {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.lastModifiedDate = NSDate(timeIntervalSince1970: 123456789)
        conversation.remoteIdentifier = .createUUID()
        let otherUser = ZMUser.insertNewObjectInManagedObjectContext(uiMOC)
        otherUser.remoteIdentifier = .createUUID()
        let message = ZMMessage.insertNewObjectInManagedObjectContext(uiMOC)
        message.sender = otherUser
        message.visibleInConversation = conversation
        let timestamp = conversation.lastModifiedDate
        message.serverTimestamp = timestamp

        // when
        let updateEvent = createMessageDeletedUpdateEvent(message.nonce, conversationID: conversation.remoteIdentifier, senderID: otherUser.remoteIdentifier!)
        
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertTrue(message.isZombieObject)
        XCTAssertEqual(conversation.messages.count, 1)
        
        guard let systemMessage = conversation.messages.lastObject as? ZMSystemMessage where systemMessage.systemMessageType == .MessageDeletedForEveryone else {
            return XCTFail()
        }
        
        XCTAssertEqual(systemMessage.serverTimestamp, timestamp)
        XCTAssertEqual(systemMessage.sender, otherUser)
    }

}

// MARK: - Helper

extension ZMClientMessageTests_Deletion {

    func createMessageDeletedUpdateEvent(nonce: NSUUID, conversationID: NSUUID, senderID: NSUUID = .createUUID()) -> ZMUpdateEvent {
        let genericMessage = ZMGenericMessage(deleteMessage: nonce.transportString(), nonce: NSUUID.createUUID().transportString())
        
        let payload = [
            "id": NSUUID.createUUID().transportString(),
            "conversation": conversationID.transportString(),
            "from": senderID.transportString(),
            "time": NSDate().transportString(),
            "data": [
                "text": genericMessage.data().base64String()
            ],
            "type": "conversation.otr-message-add"
        ]

        return ZMUpdateEvent(fromEventStreamPayload: payload, uuid: nonce)
    }

}

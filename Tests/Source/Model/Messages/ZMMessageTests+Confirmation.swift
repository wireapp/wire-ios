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

class ZMMessageTests_Confirmation: BaseZMClientMessageTests {

    override func setUp() {
        super.setUp()
        XCTAssertNotNil(self.uiMOC.globalManagedObjectContextObserver)
        NSNotificationCenter.defaultCenter().postNotificationName("ZMApplicationDidEnterEventProcessingStateNotification", object: nil)
        NSNotificationCenter.defaultCenter().postNotificationName(UIApplicationDidBecomeActiveNotification, object: nil)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    override func tearDown() {
        self.uiMOC.globalManagedObjectContextObserver.tearDown()
        super.tearDown()
    }
    // MARK: Sending
    

    func checkThatItInsertsAConfirmationMessageWhenItReceivesAMessage(conversationType: ZMConversationType, shouldSendConfirmation: Bool){
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        conversation.conversationType = conversationType
        
        let lastModified = NSDate(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        // when
        // other user sends confirmation
        let sut = insertMessage(conversation)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.firstObject as? ZMClientMessage, sut)
        
        if shouldSendConfirmation {
            XCTAssertEqual(conversation.hiddenMessages.count, 1)
            
            guard let confirmationMessage = conversation.hiddenMessages.lastObject as? ZMClientMessage,
                let genericMessage = confirmationMessage.genericMessage else { return XCTFail() }
            XCTAssertTrue(genericMessage.hasConfirmation())
            XCTAssertEqual(genericMessage.confirmation.messageId, sut.nonce.transportString())
            XCTAssertEqual(genericMessage.confirmation.type, ZMConfirmationType.DELIVERED)
        }
        else {
            XCTAssertEqual(conversation.hiddenMessages.count, 0)
        }
        
        // A confirmation should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, sut.serverTimestamp)
    }
    
    func testThatIt_Inserts_AConfirmationMessageWhenItReceivesAMessageInA_OneOnOne_Conversation(){
        checkThatItInsertsAConfirmationMessageWhenItReceivesAMessage(.OneOnOne, shouldSendConfirmation:true)
    }
    
    func testThatIt_DoesNotInsert_AConfirmationMessageWhenItReceivesAMessageInA_Group_Conversation(){
        checkThatItInsertsAConfirmationMessageWhenItReceivesAMessage(.Group, shouldSendConfirmation:false)
    }
    
    func testThatItDoesNotSendAConfirmationMessageIfTheMessageWasSentByTheSelfUser(){
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        conversation.conversationType = .OneOnOne
        
        let lastModified = NSDate(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        // when
        // other user sends confirmation
        let sut = insertMessage(conversation, fromSender: selfUser)
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.firstObject as? ZMClientMessage, sut)
        XCTAssertEqual(conversation.hiddenMessages.count, 0)
        
        // A confirmation should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, sut.serverTimestamp)
    }
    
//    func testThatThePayloadOnlyContainsTheSender(){
//        // Future proof - in case we start sending confirmations in groups as well
//        // given
//        createSelfClient()
//
//        let user1 = ZMUser.insertNewObjectInManagedObjectContext(syncMOC)
//        user1.remoteIdentifier = NSUUID()
//        createClientForUser(user1, createSessionWithSelfUser: true)
//
//        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
//        
//        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(syncMOC)
//        conversation.remoteIdentifier = .createUUID()
//        conversation.connection = ZMConnection.insertNewObjectInManagedObjectContext(syncMOC)
//        conversation.connection.to = user1
//        conversation.conversationType = .OneOnOne
//        
//        let message = insertMessage(conversation, fromSender: user1, moc: syncMOC)
//        XCTAssertTrue(syncMOC.saveOrRollback())
//        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
//        
//        let genericMessage = ZMGenericMessage(confirmation: message.nonce.transportString(), type: .DELIVERED, nonce: NSUUID().transportString())
//        
//        // when
//        var otrMessage: ZMNewOtrMessage?
//        syncSelfUser.selfClient()!.keysStore.encryptionContext.perform{ (sessionsDirectory) in
//            otrMessage =  ZMClientMessage.otrMessageForGenericMessage(genericMessage, selfClient:self.syncSelfUser.selfClient()!, conversation: conversation, externalData: nil, sessionsDirectory:sessionsDirectory)
//        }
//        
//        // then
//        XCTAssertNotNil(otrMessage)
//        XCTAssertEqual(otrMessage?.recipients.count, 1)
//        guard let recipient = otrMessage?.recipients.first else {return XCTFail()}
//        XCTAssertTrue(recipient.hasUser())
//        
//        XCTAssertEqual(recipient.user.uuid, user1.remoteIdentifier?.data())
//    }
    
    // MARK: Receiving Confirmation GenericMessage
    
    func testThatItUpdatesTheConfirmationStatusWhenItRecievesAConfirmationMessage(){
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
    
        let sut = conversation.appendMessageWithText("foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        let lastModified = NSDate(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        // when
        // other user sends confirmation
        let updateEvent = createMessageConfirmationUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier)
        var confirmationMessage : ZMOTRMessage?
        performPretendingUiMocIsSyncMoc {
            confirmationMessage = ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(sut.confirmations.count, 1)
        XCTAssertNil(confirmationMessage);
        guard let sender = ZMUser.fetchObjectWithRemoteIdentifier(updateEvent.senderUUID()!, inManagedObjectContext: uiMOC),
              let confirmation = sut.confirmations.first
        else { return XCTFail() }
        
        XCTAssertEqual(confirmation.user, sender)
        XCTAssertNotEqual(confirmation.user, sut.sender)
        XCTAssertEqual(confirmation.message, sut)
        XCTAssertEqual(confirmation.type, MessageConfirmationType.Delivered)

        // A confirmation should not update the lastModified date
        XCTAssertEqual(conversation.lastModifiedDate, lastModified)
    }
    
    func testThatItUpdatesTheDeliveryStatusOfAMessage(){
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        
        let sut = conversation.appendMessageWithText("foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.Sent)

        // when
        // other user sends confirmation
        let updateEvent = createMessageConfirmationUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(sut.deliveryState, ZMDeliveryState.Delivered)
    }
    
     func testThatItDoesNotUpdateTheDeliveryStatusOfAMessageIfTheSenderIsNotTheSelfUser(){
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        
        let sut = insertMessage(conversation)
        
        // when
        // other user sends confirmation
        let updateEvent = createMessageConfirmationUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertNotEqual(sut.deliveryState, ZMDeliveryState.Delivered)
    }
    
    func testThatItSendsOutNotificationsForTheDeliveryStatusChange(){
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)
        conversation.remoteIdentifier = .createUUID()
        let lastModified = NSDate(timeIntervalSince1970: 1234567890)
        conversation.lastModifiedDate = lastModified
        
        let sut = conversation.appendMessageWithText("foo") as! ZMClientMessage
        sut.markAsSent()
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))

        let convObserver = ConversationChangeObserver(conversation: conversation)
        let messageObserver = MessageChangeObserver(message: sut)
        defer {
            convObserver.tearDown()
            messageObserver.tearDown()
        }
        
        // when
        let updateEvent = createMessageConfirmationUpdateEvent(sut.nonce, conversationID: conversation.remoteIdentifier)
        performPretendingUiMocIsSyncMoc {
            ZMOTRMessage.createOrUpdateMessageFromUpdateEvent(updateEvent, inManagedObjectContext: self.uiMOC, prefetchResult: nil)
        }
        XCTAssertTrue(self.uiMOC.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        if convObserver.notifications.count > 0 {
            return XCTFail()
        }
        guard let messageChangeInfo = messageObserver.notifications.firstObject  as? MessageChangeInfo else {
            return XCTFail()
        }
        XCTAssertTrue(messageChangeInfo.deliveryStateChanged)
    }
}


extension ZMMessageTests_Confirmation {
    
    func insertMessage(conversation: ZMConversation, fromSender: ZMUser? = nil, moc: NSManagedObjectContext? = nil) -> ZMClientMessage {
        let nonce = NSUUID.createUUID()
        let genericMessage = ZMGenericMessage(text: "foo", nonce: nonce.transportString())
        let messageEvent = createUpdateEvent(nonce, conversationID: conversation.remoteIdentifier, genericMessage: genericMessage, senderID: fromSender?.remoteIdentifier ?? NSUUID.createUUID())
        
        var message : ZMClientMessage!
        let MOC = moc ?? uiMOC

        if MOC!.zm_isUserInterfaceContext {
            performPretendingUiMocIsSyncMoc {
                message = ZMClientMessage.createOrUpdateMessageFromUpdateEvent(messageEvent, inManagedObjectContext: MOC, prefetchResult: nil)
            }
        }
        else {
            message = ZMClientMessage.createOrUpdateMessageFromUpdateEvent(messageEvent, inManagedObjectContext: MOC, prefetchResult: nil)

        }
        XCTAssertTrue(MOC!.saveOrRollback())
        XCTAssertTrue(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        return message
    }
    
    func createUpdateEvent(nonce: NSUUID, conversationID: NSUUID, genericMessage: ZMGenericMessage, senderID: NSUUID = .createUUID()) -> ZMUpdateEvent {
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
    
    func createMessageConfirmationUpdateEvent(nonce: NSUUID, conversationID: NSUUID, senderID: NSUUID = .createUUID()) -> ZMUpdateEvent {
        let genericMessage = ZMGenericMessage(confirmation: nonce.transportString(), type: .DELIVERED, nonce: NSUUID.createUUID().transportString())
        return createUpdateEvent(nonce, conversationID: conversationID, genericMessage: genericMessage, senderID: senderID)
    }
    
}

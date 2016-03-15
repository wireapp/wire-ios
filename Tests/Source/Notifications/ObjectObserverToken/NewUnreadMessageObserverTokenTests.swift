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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation

@objc class UnreadMessageTestObserver: NSObject, ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver {
    
    var unreadMessageNotes : [NewUnreadMessagesChangeInfo] = []
    var unreadKnockNotes : [NewUnreadKnockMessagesChangeInfo] = []
    
    override init() {
        super.init()
    }
    
    @objc func didReceiveNewUnreadKnockMessages(note: NewUnreadKnockMessagesChangeInfo){
        self.unreadKnockNotes.append(note)
    }
    
    @objc func didReceiveNewUnreadMessages(note: NewUnreadMessagesChangeInfo) {
        self.unreadMessageNotes.append(note)
    }
    
    func clearNotifications() {
        self.unreadKnockNotes = []
        self.unreadMessageNotes = []
    }
}


class NewUnreadMessageObserverTokenTests : MessagingTest {
    
    func processPendingChangesAndClearNotifications() {
        self.uiMOC.saveOrRollback()
        self.testObserver?.clearNotifications()
    }
    
    var testObserver: UnreadMessageTestObserver?
    var newMessageToken : ZMNewUnreadMessageObserverOpaqueToken?
    var newKnocksToken :  ZMNewUnreadKnockMessageObserverOpaqueToken?
    
    
    var syncTestObserver: UnreadMessageTestObserver!
    var syncNewMessageToken : ZMNewUnreadMessageObserverOpaqueToken!
    var syncNewKnocksToken :  ZMNewUnreadKnockMessageObserverOpaqueToken!
    
    override func setUp() {
        super.setUp()
        
        self.testObserver = UnreadMessageTestObserver()
        self.newMessageToken = ZMMessageNotification.addNewMessagesObserver(self.testObserver, managedObjectContext: self.uiMOC)
        self.newKnocksToken = ZMMessageNotification.addNewKnocksObserver(self.testObserver, managedObjectContext: self.uiMOC)
        
        self.syncTestObserver = UnreadMessageTestObserver()
        self.syncNewMessageToken = ZMMessageNotification.addNewMessagesObserver(syncTestObserver, managedObjectContext: self.syncMOC)
        self.syncNewKnocksToken = ZMMessageNotification.addNewKnocksObserver(syncTestObserver, managedObjectContext: self.syncMOC)
    }
    
    override func tearDown() {
        ZMMessageNotification.removeNewKnocksObserverForToken(self.newKnocksToken!, managedObjectContext: self.uiMOC)
        ZMMessageNotification.removeNewMessagesObserverForToken(self.newMessageToken!, managedObjectContext: self.uiMOC)
        ZMMessageNotification.removeNewKnocksObserverForToken(self.syncNewKnocksToken!, managedObjectContext: self.syncMOC)
        ZMMessageNotification.removeNewMessagesObserverForToken(self.syncNewMessageToken!, managedObjectContext: self.syncMOC)
        
        self.newMessageToken = nil
        self.newKnocksToken = nil
        self.syncNewKnocksToken = nil
        self.syncNewMessageToken = nil
        self.testObserver = nil
        self.syncTestObserver = nil
        super.tearDown()
    }
    
    func testThatItNotifiesObserversWhenAMessageMoreRecentThanTheLastReadIsInserted() {
        
        // given
        self.syncMOC.performGroupedBlockAndWait{
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.lastReadServerTimeStamp = NSDate()
            self.processPendingChangesAndClearNotifications()
            
            // when
            let msg1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.syncMOC)
            msg1.serverTimestamp = NSDate()
            conversation.resortMessagesWithUpdatedMessage(msg1)
            
            let msg2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.syncMOC)
            msg2.serverTimestamp = NSDate()
            conversation.resortMessagesWithUpdatedMessage(msg2)
            
            self.syncMOC.processPendingChanges()
            
            // then
            XCTAssertEqual(self.syncTestObserver.unreadMessageNotes.count, 1)
            XCTAssertEqual(self.syncTestObserver.unreadKnockNotes.count, 0)
            
            if let note = self.syncTestObserver.unreadMessageNotes.first {
                let expected = NSSet(objects: msg1, msg2)
                XCTAssertEqual(NSSet(array: note.messages), expected)
            }
        }
    }
    
    func testThatItDoesNotNotifyObserversWhenAMessageOlderThanTheLastReadIsInserted() {
    
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.lastReadEventID = ZMEventID(major: 10, minor: 64578)
        self.processPendingChangesAndClearNotifications()
        
        // when
        let msg1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        msg1.visibleInConversation = conversation
        msg1.eventID = ZMEventID(major: 9, minor: 12345)
        
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
    }
    
    
    func testThatItDoesNotNotifyObserversWhenTheConversationHasNoLastRead() {
        
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        self.processPendingChangesAndClearNotifications()
        
        // when
        let msg1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        msg1.visibleInConversation = conversation
        msg1.eventID = ZMEventID(major: 9, minor: 12345)
        
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
    }
    
    func testThatItDoesNotNotifyObserversWhenItHasNoConversation() {
        
        // when
        let msg1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        msg1.eventID = ZMEventID(major: 9, minor: 12345)
        
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
    }

    
    func testThatItDoesNotNotifyObserversWhenTheMessageHasNoEventID() {
        
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.lastReadEventID = ZMEventID(major: 10, minor: 64578)
        self.processPendingChangesAndClearNotifications()
        
        // when
        let msg1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        msg1.visibleInConversation = conversation
                
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
    }
    
    func testThatItNotifiesObserversWhenANewKnockMessageIsInserted() {
        
        // given
        self.syncMOC.performGroupedBlockAndWait{
            let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.syncMOC)
            conversation.lastReadServerTimeStamp = NSDate()
            self.processPendingChangesAndClearNotifications()
            
            // when
            let msg1 = ZMKnockMessage.insertNewObjectInManagedObjectContext(self.syncMOC)
            msg1.serverTimestamp = NSDate()
            conversation.resortMessagesWithUpdatedMessage(msg1)
            
            self.syncMOC.processPendingChanges()
            
            // then
            XCTAssertEqual(self.syncTestObserver.unreadKnockNotes.count, 1)
            if let note = self.syncTestObserver.unreadKnockNotes.first {
                let expected = NSSet(object: msg1)
                XCTAssertEqual(NSSet(array: note.messages), expected)
            }
        }
    }
    
    func testThatItNotifiesObserversWhenANewOTRKnockMessageIsInserted() {
        
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.lastReadServerTimeStamp = NSDate()
        self.processPendingChangesAndClearNotifications()
        
        // when
        let genMsg = ZMGenericMessage.knockWithNonce("nonce")
        let msg1 = conversation.appendClientMessageWithData(genMsg.data())
        msg1.serverTimestamp = NSDate()
        conversation.resortMessagesWithUpdatedMessage(msg1)
        
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(self.testObserver!.unreadKnockNotes.count, 1)
        XCTAssertEqual(self.testObserver!.unreadMessageNotes.count, 0)
        if let note = self.testObserver?.unreadKnockNotes.first {
            let expected = NSSet(object: msg1)
            XCTAssertEqual(NSSet(array: note.messages), expected)
        }
    }
}




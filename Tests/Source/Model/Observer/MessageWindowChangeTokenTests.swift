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


import Foundation
import XCTest
@testable import ZMCDataModel




class MessageWindowChangeTokenTests : ZMBaseManagedObjectTest
{
    override func setUp() {
        super.setUp()
        self.setUpCaches()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func createMessagesWithCount(_ messageCount: UInt) -> [ZMTextMessage] {
        
        var messages = [ZMTextMessage]()
        
        (0..<messageCount).forEach {_ in
            let message = ZMTextMessage.insertNewObject(in: self.uiMOC)
            messages.append(message)
        }
        return messages
    }

    func createConversationWindowWithMessages(_ messages: [ZMMessage], uiMoc : NSManagedObjectContext) -> ZMConversationMessageWindow {
        
        let conversation = ZMConversation.insertNewObject(in:uiMoc)
        for message in messages {
            message.visibleInConversation = conversation
        }
        return conversation.conversationWindow(withSize: 10)
    }
    
    func createConversationWithMessages(_ messages: [ZMMessage], uiMOC : NSManagedObjectContext) -> ZMConversation {
        
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        for message in messages {
            message.visibleInConversation = conversation
        }
        return conversation
    }
    
    @objc class FakeObserver : NSObject, ZMConversationMessageWindowObserver
    {
        var notifications : [MessageWindowChangeInfo] = []
        var notificationBlock : ((MessageWindowChangeInfo) -> Void)?
        
        init(block: ((MessageWindowChangeInfo) -> Void)?) {
            notificationBlock = block
            super.init()
        }
        
        convenience override init() {
            self.init(block: nil)
        }
        
        @objc func conversationWindowDidChange(_ note: MessageWindowChangeInfo)
        {
            notifications.append(note)
            if let block = notificationBlock { block(note) }
        }
    }
    
    func testThatItNotifiesForClearingMessageHistory()
    {
        // given
        let observer = FakeObserver()
        
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message2 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let window = self.createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        let conversation = window.conversation
        message1.serverTimestamp = Date()
        message2.serverTimestamp = message1.serverTimestamp!.addingTimeInterval(5);
        conversation.lastServerTimeStamp = message2.serverTimestamp
        
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        let token = window.addConversationWindowObserver(observer)

        self.syncMOC.performGroupedBlockAndWait{
            let syncConv = self.syncMOC.object(with: conversation.objectID) as! ZMConversation
            
            // when
            syncConv.clearedTimeStamp = message1.serverTimestamp;
            self.syncMOC.saveOrRollback()
        }
        self.uiMOC.refresh(conversation, mergeChanges:true)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertEqual(note.deletedIndexes, IndexSet(integer: 1))
        }
        
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItNotifiesForAMessageUpdate()
    {
        // given
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message2 = ZMImageMessage.insertNewObject(in: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        self.uiMOC.saveOrRollback()
        
        let token = window.addConversationWindowObserver(observer)
        
        // when
        message2.mediumData = self.verySmallJPEGData()
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertEqual(note.updatedIndexes, IndexSet(integer: 0))
        }
        
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItDoesNotNotifyIfThereAreNoConversationWindowChanges()
    {
        // given
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        message1.text = "First"
        let message2 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        message2.text = "Second"
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        window.conversation.userDefinedName = "Fooooo"
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(observer.notifications.count, 0)
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItNotifiesIfThereAreConversationWindowChangesWithInsert()
    {
        // given
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message2 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message3 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)

        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        message3.visibleInConversation = window.conversation
        self.uiMOC.processPendingChanges()
        
        // then
        if let note = observer.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
        }
        else {
            XCTFail("New state is nil")
        }
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItNotifiesIfThereAreConversationWindowChangesWithDeletes()
    {
        // given
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message2 = ZMImageMessage.insertNewObject(in: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        window.conversation.mutableMessages.removeObject(at: 1)
        self.uiMOC.processPendingChanges()
        
        // then
        if let note = observer.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
        }
        else {
            XCTFail("New state is nil")
        }
        window.removeConversationWindowObserverToken(token)

    }
    
    func testThatItNotifiesIfThereAreConversationWindowChangesWithMoves()
    {
        // given
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message2 = ZMImageMessage.insertNewObject(in: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        window.conversation.mutableMessages.removeObject(at: 0)
        window.conversation.mutableMessages.add(message1)
        self.uiMOC.processPendingChanges()
        
        // then
        if let note = observer.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs, [ZMMovedIndex(from: 1, to: 0)])
        }
        else {
            XCTFail("New state is nil")
        }
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItNotifiesAfterAWindowScrollNotification()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message2 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message3 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        
        message1.visibleInConversation = conversation
        message2.visibleInConversation = conversation
        message3.visibleInConversation = conversation
        
        self.uiMOC.saveOrRollback()
        
        let window = conversation.conversationWindow(withSize: 2)
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        window.moveUp(byMessages: 10)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue:ZMConversationMessageWindowScrolledNotificationName), object: window)
        
        // then
        if let note = observer.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet(integer: 2))
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
        }
        else {
            XCTFail("New state is nil")
        }
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let message1 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message2 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let message3 = ZMTextMessage.insertNewObject(in: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        window.removeConversationWindowObserverToken(token)
        
        // when
        message3.visibleInConversation = window.conversation
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(observer.notifications.count, 0)
    }
}

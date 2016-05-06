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
import XCTest
@testable import ZMCDataModel




class MessageWindowChangeTokenTests : ZMBaseManagedObjectTest
{
    override func setUp() {
        super.setUp()
        self.setUpCaches()
        NSNotificationCenter.defaultCenter().postNotificationName("ZMApplicationDidEnterEventProcessingStateNotification", object: nil)
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
    }
    
    func createMessagesWithCount(messageCount: UInt, startEventIDMajor: UInt) -> [ZMTextMessage] {
        
        var messages = [ZMTextMessage]()
        
        for i in startEventIDMajor..<(messageCount + startEventIDMajor) {
            let message = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
            message.eventID = ZMEventID(major: UInt64(i), minor: 0)
            messages.append(message)
        }
        return messages
    }

    func createConversationWindowWithMessages(messages: [ZMMessage], uiMoc : NSManagedObjectContext) -> ZMConversationMessageWindow {
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMoc)!
        for message in messages {
            message.visibleInConversation = conversation
        }
        return conversation.conversationWindowWithSize(10)
    }
    
    func createConversationWithMessages(messages: [ZMMessage], uiMOC : NSManagedObjectContext) -> ZMConversation {
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(uiMOC)!
        for message in messages {
            message.visibleInConversation = conversation
        }
        let range = ZMEventIDRange(eventIDs: [messages.first!.eventID, messages.last!.eventID])
        conversation.addEventRangeToDownloadedEvents(range)
        conversation.updateLastEventIDIfNeededWithEventID(messages.last!.eventID)
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
        
        @objc func conversationWindowDidChange(note: MessageWindowChangeInfo)
        {
            notifications.append(note)
            if let block = notificationBlock { block(note) }
        }
    }
    
    func testThatItNotifiesForClearingMessageHistory()
    {
        // given
        let observer = FakeObserver()
        
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        let window = self.createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        let conversation = window.conversation
        message1.serverTimestamp = NSDate()
        message1.eventID = self.createEventID()
        message2.serverTimestamp = message1.serverTimestamp!.dateByAddingTimeInterval(5);
        message2.eventID = self.createEventID()
        conversation.lastServerTimeStamp = message2.serverTimestamp
        
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        let token = window.addConversationWindowObserver(observer)

        self.syncMOC.performGroupedBlockAndWait{
            let syncConv = self.syncMOC.objectWithID(conversation.objectID) as! ZMConversation
            
            // when
            syncConv.clearedTimeStamp = message1.serverTimestamp;
            self.syncMOC.saveOrRollback()
        }
        self.uiMOC.refreshObject(conversation, mergeChanges:true)
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmptyWithTimeout(0.5))
        
        // then
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertEqual(note.deletedIndexes, NSIndexSet(index: 1))
        }
        
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItNotifiesForAMessageUpdate()
    {
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMImageMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
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
            XCTAssertEqual(note.updatedIndexes, NSIndexSet(index: 0))
        }
        
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItDoesNotNotifyIfThereAreNoConversationWindowChanges()
    {
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.text = "First"
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.text = "Second"
        message2.eventID = ZMEventID(string: "2.aabb")
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
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let message3 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message3.eventID = ZMEventID(string: "3.aabb")
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
            XCTAssertEqual(note.insertedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet())
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
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMImageMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        window.conversation.mutableMessages.removeObjectAtIndex(1)
        self.uiMOC.processPendingChanges()
        
        // then
        if let note = observer.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, NSIndexSet())
            XCTAssertEqual(note.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(note.updatedIndexes, NSIndexSet())
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
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMImageMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        window.conversation.mutableMessages.removeObjectAtIndex(0)
        window.conversation.mutableMessages.addObject(message1)
        self.uiMOC.processPendingChanges()
        
        // then
        if let note = observer.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, NSIndexSet())
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet())
            XCTAssertEqual(note.movedIndexPairs, NSArray(object: ZMMovedIndex(from: 1, to: 0)))
        }
        else {
            XCTFail("New state is nil")
        }
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItNotifiesAfterAWindowScrollNotification()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)!
        
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let message3 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message3.eventID = ZMEventID(string: "3.aabb")
        
        message1.visibleInConversation = conversation
        message2.visibleInConversation = conversation
        message3.visibleInConversation = conversation
        
        self.uiMOC.saveOrRollback()
        
        let window = conversation.conversationWindowWithSize(2)
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        window.moveUpByMessages(10)
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationMessageWindowScrolledNotificationName, object: window)
        
        // then
        if let note = observer.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, NSIndexSet(index: 2))
            XCTAssertEqual(note.deletedIndexes, NSIndexSet())
            XCTAssertEqual(note.updatedIndexes, NSIndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
        }
        else {
            XCTFail("New state is nil")
        }
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let message3 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message3.eventID = ZMEventID(string: "3.aabb")
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

    func testThatItNotifiesWhenReceivingStartFetchingNotification() {
        
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)

        self.uiMOC.saveOrRollback()
        
        let expectation = self.expectationWithDescription("received notification")
        let observer = FakeObserver() { changeInfo in
            expectation.fulfill()
        }
        let token = window.addConversationWindowObserver(observer)
        
        // when
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationWillStartFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        XCTAssertEqual(observer.notifications.count, 1)
        
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItDoesNotNotifyTwiceWhenReceivingStartFetchingNotification() {
        
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let expectation = self.expectationWithDescription("received notification")
        let observer = FakeObserver() { changeInfo in
            expectation.fulfill()
        }
        let token = window.addConversationWindowObserver(observer)
        
        // when
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationWillStartFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationWillStartFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        XCTAssertEqual(observer.notifications.count, 1)
        
        window.removeConversationWindowObserverToken(token)
    }

    func testThatItDoesNotNotifyWhenReceivingDidFinishFetchingNotificationWithoutHavingPreviouslyStarted() {
        
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let observer = FakeObserver()
        let token = window.addConversationWindowObserver(observer)
        
        // when
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationDidFinishFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        XCTAssertEqual(observer.notifications.count, 0)
        
        window.removeConversationWindowObserverToken(token)
    }

    
    func testThatItNotifiesWhenReceivingDidFinishFetchingNotification() {
        
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let expectation = self.expectationWithDescription("received notification")
        let observer = FakeObserver() { changeInfo in
            expectation.fulfill()
        }
        let token = window.addConversationWindowObserver(observer)
        
        // when
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationWillStartFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationDidFinishFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))
        XCTAssertEqual(observer.notifications.count, 2)
        
        window.removeConversationWindowObserverToken(token)
    }
    
    func testThatItDoesNotNotifyTwiceWhenReceivingDidFinishFetchingNotification() {
        
        // given
        let message1 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message1.eventID = ZMEventID(string: "1.aabb")
        let message2 = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)!
        message2.eventID = ZMEventID(string: "2.aabb")
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let expectation = self.expectationWithDescription("received notification")
        let observer = FakeObserver() { changeInfo in
            expectation.fulfill()
        }
        let token = window.addConversationWindowObserver(observer)
        
        // when
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationWillStartFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationDidFinishFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        NSNotificationCenter.defaultCenter().postNotificationName(ZMConversationDidFinishFetchingMessages, object: nil, userInfo: [ZMNotificationConversationKey : window.conversation])
        
        // then
        XCTAssertTrue(self.waitForCustomExpectationsWithTimeout(0.5))

        XCTAssertEqual(observer.notifications.count, 2)
        
        window.removeConversationWindowObserverToken(token)
    }
}
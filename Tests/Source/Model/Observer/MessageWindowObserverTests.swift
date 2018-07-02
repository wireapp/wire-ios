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
@testable import WireDataModel

class TestWindowObserver : NSObject, ZMConversationMessageWindowObserver
{
    var messageChangeInfos = [MessageChangeInfo]()
    var notifications : [MessageWindowChangeInfo] = []
    var notificationBlock : ((MessageWindowChangeInfo) -> Void)?
    
    init(block: ((MessageWindowChangeInfo) -> Void)?) {
        notificationBlock = block
        super.init()
    }
    
    convenience override init() {
        self.init(block: nil)
    }
    
    func conversationWindowDidChange(_ changeInfo: MessageWindowChangeInfo)
    {
        notifications.append(changeInfo)
        if let block = notificationBlock { block(changeInfo) }
    }
    
    func messagesInsideWindow(_ window: ZMConversationMessageWindow, didChange messageChangeInfos: [MessageChangeInfo]) {
        self.messageChangeInfos = self.messageChangeInfos + messageChangeInfos
    }
}


class MessageWindowObserverTests : NotificationDispatcherTestBase {
    
    var windowObserver : TestWindowObserver!
    
    override func setUp() {
        windowObserver = TestWindowObserver()
        super.setUp()
    }
    
    override func tearDown() {
        windowObserver = nil
        super.tearDown()
    }
    
    func createMessagesWithCount(_ messageCount: UInt) -> [ZMClientMessage] {
        
        var messages = [ZMClientMessage]()
        
        (0..<messageCount).forEach {_ in
            let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
            messages.append(message)
        }
        return messages
    }
    
    func createConversationWindowWithMessages(_ messages: [ZMMessage], uiMoc : NSManagedObjectContext, windowSize: UInt = 10) -> ZMConversationMessageWindow {
        
        let conversation = ZMConversation.insertNewObject(in:uiMoc)
        for message in messages {
            message.visibleInConversation = conversation
        }
        return conversation.conversationWindow(withSize: windowSize)
    }
    
    func createConversationWithMessages(_ messages: [ZMMessage], uiMOC : NSManagedObjectContext) -> ZMConversation {
        
        let conversation = ZMConversation.insertNewObject(in:uiMOC)
        for message in messages {
            message.visibleInConversation = conversation
        }
        return conversation
    }
    
}

extension MessageWindowObserverTests {
    
    func testThatItDeallocates(){
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = self.createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        // when
        weak var observerCenter = uiMOC.messageWindowObserverCenter
        uiMOC.userInfo.removeObject(forKey: NSManagedObjectContext.MessageWindowObserverCenterKey)
        
        // then
        XCTAssertNil(observerCenter)
        XCTAssertNotNil(window)
    }

    func testThatItNotifiesForClearingMessageHistory()
    {
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = self.createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        let conversation = window.conversation
        message1.serverTimestamp = Date()
        message2.serverTimestamp = message1.serverTimestamp!.addingTimeInterval(5);
        conversation.lastServerTimeStamp = message2.serverTimestamp
        
        self.uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        self.syncMOC.performGroupedBlockAndWait{
            let syncConv = self.syncMOC.object(with: conversation.objectID) as! ZMConversation
            
            // when
            syncConv.clearedTimeStamp = message1.serverTimestamp;
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()
        
        // then
        XCTAssertEqual(windowObserver.notifications.count, 1)
        if let note = windowObserver.notifications.first {
            XCTAssertEqual(note.deletedIndexes, IndexSet(integer: 1))
        }
        
    }
    
    func testThatItNotifiesForAMessageUpdate()
    {
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        message2.transferState = .uploaded
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(windowObserver.notifications.count, 1)
        if let note = windowObserver.notifications.first {
            XCTAssertEqual(note.updatedIndexes, IndexSet(integer: 0))
        }
        
    }
    
    func testThatItNotifiesForASenderUpdate()
    {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Foo"
        
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message1.sender = user
        let message2 = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        user.name = "Bar"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(windowObserver.messageChangeInfos.count, 1)
        if let note = windowObserver.messageChangeInfos.first {
            XCTAssertEqual(note.message, message1)
            XCTAssertTrue(note.usersChanged)
        }
        
    }
    
    func testThatItNotifiesForASystemMessageUserUpdate()
    {
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Foo"
        
        let message1 = ZMSystemMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message1.users = Set([user])
        let message2 = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        user.name = "Bar"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(windowObserver.messageChangeInfos.count, 1)
        if let note = windowObserver.messageChangeInfos.first {
            XCTAssertEqual(note.message, message1)
            XCTAssertTrue(note.usersChanged)
        }
        
    }
    
    func testThatItDoesNotNotifyIfThereAreNoConversationWindowChanges()
    {
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        window.conversation.userDefinedName = "Fooooo"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(windowObserver.notifications.count, 0)
    }
    
    func testThatItSetsNeedReloadAfterComingToForegroundEvenWithNoChanges() {
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        let observerCenter = uiMOC.messageWindowObserverCenter
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        observerCenter.applicationDidEnterBackground()
        observerCenter.applicationWillEnterForeground()
        
        // then
        if let note = windowObserver.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
            XCTAssert(note.needsReload)
        }
        else {
            XCTFail("New state is nil")
        }

    }
    
    func testThatItNotifiesIfThereAreConversationWindowChangesWithInsert()
    {
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message3 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        message3.visibleInConversation = window.conversation
        self.uiMOC.saveOrRollback()
        
        // then
        if let note = windowObserver.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
        }
        else {
            XCTFail("New state is nil")
        }
    }
    
    func testThatItNotifiesIfThereAreConversationWindowChangesWithDeletes()
    {
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMAssetClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        window.conversation.mutableMessages.removeObject(at: 1)
        self.uiMOC.saveOrRollback()
        
        // then
        if let note = windowObserver.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
        }
        else {
            XCTFail("New state is nil")
        }
        
    }
    
    func testThatItNotifiesIfThereAreConversationWindowChangesWithMoves()
    {
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMImageMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        window.conversation.mutableMessages.removeObject(at: 0)
        window.conversation.mutableMessages.add(message1)
        self.uiMOC.saveOrRollback()
        
        // then
        if let note = windowObserver.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs, [MovedIndex(from: 1, to: 0)])
        }
        else {
            XCTFail("New state is nil")
        }
    }
    
    func testThatItNotifiesAfterAWindowScrollNotification()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message3 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        
        message1.visibleInConversation = conversation
        message2.visibleInConversation = conversation
        message3.visibleInConversation = conversation
        
        self.uiMOC.saveOrRollback()
        
        conversation.lastServerTimeStamp = message3.serverTimestamp
        conversation.markAsRead()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        let window = conversation.conversationWindow(withSize: 2)
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        window.moveUp(byMessages: 10)
        
        // then
        if let note = windowObserver.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet(integer: 2))
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs.count, 0)
        }
        else {
            XCTFail("New state is nil")
        }
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message3 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        self.token = nil
        message3.visibleInConversation = window.conversation
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(windowObserver.notifications.count, 0)
    }
    
    func testPerformanceOfCalculatingChangeNotificationsWhenANewMessageArrives_RegisteringNewObservers()
    {
        // before:
        // windowSize 10: average: 0.528, relative standard deviation: 0.515%, values: [0.528867, 0.528230, 0.525480, 0.525551, 0.530068, 0.532909, 0.527777, 0.524606, 0.527038, 0.532571]
        // windowSize 100: average: 0.651, relative standard deviation: 4.225%, values: [0.641393, 0.645058, 0.621273, 0.617338, 0.653535, 0.641560, 0.679653, 0.709796, 0.673929, 0.628096]
        // windowSize 1000: average: 1.134, relative standard deviation: 10.849%, values: [1.091754, 1.171760, 0.887102, 1.099604, 1.091845, 1.186577, 1.399376, 1.129551, 1.068521, 1.216519]
        
        // after:
        // windowSize 10: average: 0.496, relative standard deviation: 0.660%, values: [0.496551, 0.492295, 0.492022, 0.493457, 0.495677, 0.499688, 0.495764, 0.492826, 0.494440, 0.502799],
        // windowSize 100: average: 0.590, relative standard deviation: 0.625%, values: [0.593669, 0.583634, 0.595112, 0.586753, 0.592627, 0.593324, 0.586851, 0.586290, 0.587724, 0.589547],
        // windowSize 1000: average: 0.753, relative standard deviation: 0.928%, values: [0.749879, 0.744184, 0.753860, 0.759445, 0.767395, 0.757016, 0.746533, 0.743892, 0.755466, 0.750862],

        let count = 500
        self.measureMetrics([.wallClockTime], automaticallyStartMeasuring: false) {
            let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
            let message2 = ZMClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
            let window = self.createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC, windowSize: 10)
            self.uiMOC.saveOrRollback()

            self.token = MessageWindowChangeInfo.add(observer: self.windowObserver, for: window)
            
            self.startMeasuring()
            for _ in 1...count {
                let message = ZMClientMessage(nonce: UUID(), managedObjectContext: self.uiMOC)
                message.visibleInConversation = window.conversation
                self.uiMOC.saveOrRollback()
            }
            self.token = nil
            self.stopMeasuring()
        }
    }
    
    
    func checkThatItNotifiesAboutUserChange(in window: ZMConversationMessageWindow, modifier: (() -> Void), callBack: ((UserChangeInfo) -> Void)){
        self.token = MessageWindowChangeInfo.add(observer: windowObserver, for: window)
        
        // when
        modifier()
        uiMOC.saveOrRollback()
        
        // then
        if let note = windowObserver.messageChangeInfos.first {
            XCTAssertTrue(note.usersChanged)
            XCTAssertTrue(note.senderChanged)
            if let userChange = note.userChangeInfo {
                callBack(userChange)
            }
            else {
                XCTFail("There is no UserChangeInfo")
            }
        }
        else {
            XCTFail("There is no MessageChangeInfo")
        }
        self.token = nil
    }
    
    func testThatItNotifiesObserverWhenTheSenderNameChanges() {
        // given
        let sender = ZMUser.insertNewObject(in:self.uiMOC)
        sender.name = "Hans"
        
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.sender = sender

        let window = createConversationWindowWithMessages([message], uiMoc: self.uiMOC)
        uiMOC.saveOrRollback()
        
        checkThatItNotifiesAboutUserChange(in: window,
                                           modifier: { message.sender?.name = "Horst"},
                                           callBack: {
                                            XCTAssertTrue($0.nameChanged)
        })
    }


    func testThatItNotifiesObserverWhenTheSenderAccentColorChanges() {
        // given
        let sender = ZMUser.insertNewObject(in:self.uiMOC)
        sender.name = "Hans A"
        
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.sender = sender
        
        let window = createConversationWindowWithMessages([message], uiMoc: self.uiMOC)
        uiMOC.saveOrRollback()

        // when
        checkThatItNotifiesAboutUserChange(in: window,
                                           modifier: { message.sender!.accentColorValue = ZMAccentColor.softPink },
                                           callBack: {
                                            XCTAssertTrue($0.accentColorValueChanged)
        })

    }

    func testThatItNotifiesObserverWhenTheSenderSmallProfileImageChanges() {
        // given
        let sender = ZMUser.insertNewObject(in:self.uiMOC)
        sender.remoteIdentifier = UUID.create()
        sender.mediumRemoteIdentifier = UUID.create()
        
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.sender = sender
        
        let window = createConversationWindowWithMessages([message], uiMoc: self.uiMOC)
        uiMOC.saveOrRollback()
        
        // when
        checkThatItNotifiesAboutUserChange(in: window,
                                           modifier: { message.sender!.imageMediumData = self.verySmallJPEGData()},
                                           callBack: {
                                            XCTAssertTrue($0.imageMediumDataChanged)
        })

    }

    func testThatItNotifiesObserverWhenTheSenderMediumProfileImageChanges() {
        // given
        let sender = ZMUser.insertNewObject(in:self.uiMOC)
        sender.remoteIdentifier = UUID.create()
        sender.smallProfileRemoteIdentifier = UUID.create()
        
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.sender = sender
        
        let window = createConversationWindowWithMessages([message], uiMoc: self.uiMOC)
        uiMOC.saveOrRollback()
        
        // when
        checkThatItNotifiesAboutUserChange(in: window,
                                           modifier: { message.sender!.imageSmallProfileData = self.verySmallJPEGData()},
                                           callBack: {
                                            XCTAssertTrue($0.imageSmallProfileDataChanged)
        })
    }
    
    func testThatItRecreatesTheSnapshotIfTheWindowIsRecreatedForTheSameConversation(){
        // given
        let sender = ZMUser.insertNewObject(in:self.uiMOC)
        sender.remoteIdentifier = UUID.create()
        sender.smallProfileRemoteIdentifier = UUID.create()
        
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.sender = sender
        
        let window = createConversationWindowWithMessages([message], uiMoc: self.uiMOC)
        let newWindow = window.conversation.conversationWindow(withSize: 10)
        uiMOC.saveOrRollback()
        
        // when
        checkThatItNotifiesAboutUserChange(in: newWindow,
                                           modifier: { message.sender!.imageSmallProfileData = self.verySmallJPEGData()},
                                           callBack: {
                                            XCTAssertTrue($0.imageSmallProfileDataChanged)
        })
    
    }

    func testThatItNotifiesMultipleWindows()
    {
        // given
        let windowObserver1 = TestWindowObserver()
        let windowObserver2 = TestWindowObserver()
        
        let message1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let message2 = ZMImageMessage(nonce: UUID(), managedObjectContext: uiMOC)
        let window = createConversationWindowWithMessages([message1, message2], uiMoc: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        var tokens: [Any] = []
        tokens.append(MessageWindowChangeInfo.add(observer: windowObserver1, for: window))
        tokens.append(MessageWindowChangeInfo.add(observer: windowObserver2, for: window))
        self.token = tokens
        
        // when
        window.conversation.mutableMessages.removeObject(at: 0)
        window.conversation.mutableMessages.add(message1)
        self.uiMOC.saveOrRollback()
        
        // then
        if let note = windowObserver1.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs, [MovedIndex(from: 1, to: 0)])
        }
        else {
            XCTFail("New state is nil")
        }
        
        if let note = windowObserver2.notifications.first {
            XCTAssertEqual(note.conversationMessageWindow, window)
            XCTAssertEqual(note.insertedIndexes, IndexSet())
            XCTAssertEqual(note.deletedIndexes, IndexSet())
            XCTAssertEqual(note.updatedIndexes, IndexSet())
            XCTAssertEqual(note.movedIndexPairs, [MovedIndex(from: 1, to: 0)])
        }
        else {
            XCTFail("New state is nil")
        }
    }
}

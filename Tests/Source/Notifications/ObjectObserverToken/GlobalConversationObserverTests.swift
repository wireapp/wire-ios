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



class GlobalConversationObserverTests : MessagingTest {
    
    private func movedIndexes(changeSet: ConversationListChangeInfo) -> [ZMMovedIndex] {
        var array : [ZMMovedIndex] = []
        changeSet.enumerateMovedIndexes {(x: UInt, y: UInt) in array.append(ZMMovedIndex(from: x, to: y)) }
        return array
    }
    
    class TestObserver : NSObject, ZMConversationListObserver {
        
        var changes : [ConversationListChangeInfo] = []
        
        @objc func conversationListDidChange(changeInfo: ConversationListChangeInfo!) {
            changes.append(changeInfo)
        }
    }
    
    class GlobalVoiceChannelTestObserver : NSObject, ZMVoiceChannelStateObserver {
        
        var changes : [VoiceChannelStateChangeInfo] = []
        
        @objc func voiceChannelStateDidChange(info: VoiceChannelStateChangeInfo!) {
            changes.append(info)
        }
    }
    
    func testThatItNotifiesObserversWhenANewConversationIsInsertedThatMatchesListPredicate()
    {
        // given
        let conversationList = ZMConversation.conversationsIncludingArchivedInContext(self.uiMOC)

        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        conversation.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.connection.status = .Accepted
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)
    }
    
    func testThatItDoesNotNotifyObserversWhenANewConversationIsInsertedThatDoesNotMatchListPredicate()
    {
        // given
        let conversationList = ZMConversation.archivedConversationsInContext(self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 0)
        conversationList.removeConversationListObserverForToken(token)

    }
    
    
    func testThatItNotifiesObserversWhenAConversationChangesSoItNowDoesNotMatchThePredicate()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatItNotifiesObserversWhenAConversationChangesToNotMatchThePredicateAndThenToMatchThePredicateAgain()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        conversation.isArchived = false
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 2)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        if let first = testObserver.changes.last {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatItNotifiesObserversWhenAConversationChangesToNotMatchThePredicateAndThenToMatchThePredicateAgain_Calling()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        let selfUser = ZMUser.selfUserInContext(self.uiMOC)
        
        conversation.conversationType = .OneOnOne
        conversation.mutableOtherActiveParticipants.addObject(user)
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let mutableCallParticipants = conversation.mutableOrderedSetValueForKey(ZMConversationCallParticipantsKey)
        mutableCallParticipants.addObject(user)
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.callDeviceIsActive = true
        conversation.isFlowActive = true
        conversation.activeFlowParticipants = NSOrderedSet(array: [user, selfUser])
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        conversation.callDeviceIsActive = false
        conversation.isFlowActive = false
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation), notifyDirectly: true)
        
        // then
        XCTAssertEqual(testObserver.changes.count, 2)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(self.movedIndexes(first), [])
        }
        if let first = testObserver.changes.last {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(self.movedIndexes(first), [])
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmptyWithTimeout(0.5))
        conversation.voiceChannel.tearDown()
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatItNotifiesObserversWhenAConversationChangesSoItNowDoesMatchThePredicate()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        XCTAssertEqual(conversationList.count, 0)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.isArchived = false
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatAConversationThatGetsAddedToTheListIsLaterRemovedWhenItChangesNotToMatchThePredicate()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        conversation.isArchived = true
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.isArchived = false
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        
        // and when
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversationList.count, 0)
        XCTAssertEqual(testObserver.changes.count, 2)
        if let last = testObserver.changes.last {
            XCTAssertEqual(last.insertedIndexes, NSIndexSet())
            XCTAssertEqual(last.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(last.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(last), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }
    
    
    func testThatTheListIsReorderedWhenAConversationChangesTheLastModifiedTime()
    {
        // given
        let conversation1 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation1.conversationType = .Group
        conversation1.lastModifiedDate = NSDate(timeIntervalSince1970: 30)
        
        let conversation2 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation2.conversationType = .Group
        conversation2.lastModifiedDate = NSDate(timeIntervalSince1970: 90)
        
        let conversation3 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation3.conversationType = .Group
        conversation3.lastModifiedDate = NSDate(timeIntervalSince1970: 1400)
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()

        let token = conversationList.addConversationListObserver(testObserver)
        XCTAssertEqual(conversationList.count, 3)
        
        // when
        conversation2.lastModifiedDate = NSDate(timeIntervalSince1970: 1000000)
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversationList.count, 3)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(movedIndexes(first), [ZMMovedIndex(from: 1, to: 0)])
        }
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatTheListIsOrderedWhenAConversationIsInserted()
    {
        // given
        let conversation1 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation1.conversationType = .Group
        conversation1.lastModifiedDate = NSDate(timeIntervalSince1970: 30)
        
        let conversation2 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation2.conversationType = .Group
        conversation2.lastModifiedDate = NSDate(timeIntervalSince1970: 100)
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()

        let token = conversationList.addConversationListObserver(testObserver)
        XCTAssertEqual(conversationList.count, 2)
        
        // when
        let conversation3 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation3.conversationType = .Group
        conversation3.lastModifiedDate = NSDate(timeIntervalSince1970: 50)
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversationList.count, 3)
        XCTAssertEqual(conversationList[0] as? ZMConversation, conversation2)
        XCTAssertEqual(conversationList[1] as? ZMConversation, conversation3)
        XCTAssertEqual(conversationList[2] as? ZMConversation, conversation1)
        
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatAnObserverIsNotNotifiedAfterBeingRemoved()
    {
        // given
        let conversation1 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation1.conversationType = .Group
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        self.uiMOC.saveOrRollback()
        
        XCTAssertEqual(conversationList.count, 1)
        
        // when
        conversationList.removeConversationListObserverForToken(token)
        let conversation2 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation2.conversationType = .Group
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversationList.count, 2)
        XCTAssertEqual(testObserver.changes.count, 0)
    }
    
    
    func testThatItNotifiesTheObserverIfTheConnectionStateOfAConversationChangesAndAfterThatItMatchesAList()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.connection.status = .Pending
        conversation.conversationType = .Connection
        
        let pendingList = ZMConversation.pendingConversationsInContext(self.uiMOC)
        let normalList = ZMConversation.conversationsIncludingArchivedInContext(self.uiMOC)

        let pendingObserver = TestObserver()
        let token1 = pendingList.addConversationListObserver(pendingObserver)
        
        let normalObserver = TestObserver()
        let token2 = normalList.addConversationListObserver(normalObserver)
        
        self.uiMOC.saveOrRollback()
        
        XCTAssertEqual(pendingList.count, 1)
        XCTAssertEqual(normalList.count, 0)

        // when
        conversation.connection.status = .Accepted
        conversation.conversationType = .OneOnOne
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(pendingList.count, 0)
        XCTAssertEqual(normalList.count, 1)
        
        XCTAssertEqual(pendingObserver.changes.count, 1)
        XCTAssertEqual(normalObserver.changes.count, 1)
        if let pendingNote = pendingObserver.changes.first {
            XCTAssertEqual(pendingNote.insertedIndexes, NSIndexSet())
            XCTAssertEqual(pendingNote.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(pendingNote.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(pendingNote), [])
        }
        if let normalNote = normalObserver.changes.first {
            XCTAssertEqual(normalNote.insertedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(normalNote.deletedIndexes, NSIndexSet())
            XCTAssertEqual(normalNote.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(normalNote), [])
        }
        pendingList.removeConversationListObserverForToken(token1)
        normalList.removeConversationListObserverForToken(token2)

    }
    
    func testThatItNotifiesListObserversWhenAConversationIsRemovedFromTheListBecauseItIsArchived()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatItNotifiesObserversWhenAConversationUpdatesUserDefinedName()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.userDefinedName = "Soap"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }

    func testThatItNotifiesObserversWhenAUserInAConversationChangesTheirName()
    {
        // given
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.mutableOtherActiveParticipants.addObject(user)
        conversation.conversationType = .Group
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        // TODO: if I put a save here, I get no notifications at all?
        user.name = "Foo"
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        user.name = "Soap"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }

    func testThatItNotifiesObserversWhenThereIsAnUnreadPingInAConversation()
    {
        // given
        let conversation =  ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        conversation.lastEventID = self.createEventID()
        conversation.lastReadEventID = conversation.lastEventID
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        self.simulateUnreadMissedKnockInConversation(conversation)
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)
    }
    
    func testThatItNotifiesObserversWhenTheEstimatedUnreadCountChanges()
    {
        // given
        let conversation =  ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        conversation.lastServerTimeStamp = NSDate()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        
        let message = ZMMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        message.serverTimestamp = NSDate()
        
        self.uiMOC.saveOrRollback()
        
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        XCTAssertEqual(conversation.estimatedUnreadCount, 0)
        
        // when
        self.simulateUnreadCount(1, forConversation: conversation)
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversation.estimatedUnreadCount, 1)

        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }

    func testThatItDoesNotNotifyObserversWhenTheOnlyChangeIsAnInsertedMessage()
    {
        // given
        let conversation =  ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.lastReadServerTimeStamp = NSDate()
        conversation.conversationType = .Group
        
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        conversation.mutableMessages.addObject(ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC))
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 0)
        conversationList.removeConversationListObserverForToken(token)

    }

    func testThatItNotifiesObserversWhenTheUserInOneOnOneConversationGetsBlocked()
    {
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        let conversation = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.connection = ZMConnection.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.connection.status = .Accepted
        conversation.conversationType = .OneOnOne
        conversation.connection.to = user
        
        let normalList = ZMConversation.conversationsIncludingArchivedInContext(self.uiMOC)
        
        let testObserver = TestObserver()
        let token = normalList.addConversationListObserver(testObserver)
        
        self.uiMOC.saveOrRollback()
        
        XCTAssertEqual(normalList.count, 1)
        
        // when
        user.connection!.status = .Blocked
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(normalList.count, 0)
        
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(first.updatedIndexes, NSIndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        normalList.removeConversationListObserverForToken(token)
    }
    
    func testThatItNotifiesObserversWhenAMessageBecomesUnreadUnsent()
    {
        // given
        
        let message = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)

        let conversation =  ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        conversation.mutableMessages.addObject(message)

        
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        
        // when
        message.expire()
        
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }

    func testThatItNotifiesObserversWhenWeInsertAnUnreadMissedCall()
    {
        // given
        let conversation =  ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)

        // when
        self.simulateUnreadMissedCallInConversation(conversation)
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, NSIndexSet())
            XCTAssertEqual(first.deletedIndexes, NSIndexSet())
            XCTAssertEqual(first.updatedIndexes, NSIndexSet(index: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeConversationListObserverForToken(token)

    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let message = ZMTextMessage.insertNewObjectInManagedObjectContext(self.uiMOC)
        
        let conversation =  ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation.conversationType = .Group
        conversation.mutableMessages.addObject(message)
        
        
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchivedAndCallingInContext(self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.addConversationListObserver(testObserver)
        conversationList.removeConversationListObserverForToken(token)
        
        // when
        message.expire()
        self.uiMOC.saveOrRollback()

        
        // then
        XCTAssertEqual(testObserver.changes.count, 0)
    }

    func testThatItNotifiesGlobalVoiceChannelObserversWhenAVoiceChannelStateChanges()
    {
        // given
        let conversation1 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation1.conversationType = .OneOnOne
        let conversation2 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation2.conversationType = .OneOnOne
        let conversation3 = ZMConversation.insertNewObjectInManagedObjectContext(self.uiMOC)
        conversation3.conversationType = .OneOnOne
        self.uiMOC.saveOrRollback()
        
        let testObserver = GlobalVoiceChannelTestObserver()
        let token: AnyObject = self.uiMOC.globalManagedObjectContextObserver.addGlobalVoiceChannelObserver(testObserver)
        
        // when
        conversation1.voiceChannel.join()
        self.uiMOC.globalManagedObjectContextObserver.notifyUpdatedCallState(Set(arrayLiteral: conversation1, conversation2, conversation3), notifyDirectly: true)
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1);
        
        self.uiMOC.globalManagedObjectContextObserver.removeGlobalVoiceChannelStateObserverForToken(token)
    }
}

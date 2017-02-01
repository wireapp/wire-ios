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


import ZMCDataModel

class GlobalConversationObserverTests : ZMBaseManagedObjectTest {
    
    override func setUp() {
        super.setUp()
        self.uiMOC.globalManagedObjectContextObserver.syncCompleted(NSNotification(name: NSNotification.Name(rawValue: "fake"), object: nil) as Notification)
        NotificationCenter.default.post(name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    fileprivate func movedIndexes(_ changeSet: ConversationListChangeInfo) -> [ZMMovedIndex] {
        var array : [ZMMovedIndex] = []
        changeSet.enumerateMovedIndexes {(x: UInt, y: UInt) in array.append(ZMMovedIndex(from: x, to: y)) }
        return array
    }
    
    class TestObserver : NSObject, ZMConversationListObserver {
        
        var changes : [ConversationListChangeInfo] = []
        
        @objc func conversationListDidChange(_ changeInfo: ConversationListChangeInfo!) {
            changes.append(changeInfo)
        }
    }
    
    func testThatItNotifiesObserversWhenANewConversationIsInsertedThatMatchesListPredicate()
    {
        // given
        let conversationList = ZMConversation.conversationsIncludingArchived(in: self.uiMOC)

        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        conversation.connection = ZMConnection.insertNewObject(in: self.uiMOC)
        conversation.connection?.status = .accepted
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)
    }
    
    func testThatItDoesNotNotifyObserversWhenANewConversationIsInsertedThatDoesNotMatchListPredicate()
    {
        // given
        let conversationList = ZMConversation.archivedConversations(in: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 0)
        conversationList.removeObserver(for: token)

    }
    
    
    func testThatItNotifiesObserversWhenAConversationChangesSoItNowDoesNotMatchThePredicate()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }
    
    func testThatItNotifiesObserversWhenAConversationChangesToNotMatchThePredicateAndThenToMatchThePredicateAgain()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        conversation.isArchived = false
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 2)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        if let first = testObserver.changes.last {
            XCTAssertEqual(first.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }
    
    func testThatItNotifiesObserversWhenAConversationChangesSoItNowDoesMatchThePredicate()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        XCTAssertEqual(conversationList.count, 0)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        conversation.isArchived = false
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }
    
    func testThatAConversationThatGetsAddedToTheListIsLaterRemovedWhenItChangesNotToMatchThePredicate()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
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
            XCTAssertEqual(last.insertedIndexes, IndexSet())
            XCTAssertEqual(last.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(last.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(last), [])
        }
        conversationList.removeObserver(for: token)

    }
    
    
    func testThatTheListIsReorderedWhenAConversationChangesTheLastModifiedTime()
    {
        // given
        let conversation1 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation1.conversationType = .group
        conversation1.lastModifiedDate = Date(timeIntervalSince1970: 30)
        
        let conversation2 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation2.conversationType = .group
        conversation2.lastModifiedDate = Date(timeIntervalSince1970: 90)
        
        let conversation3 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation3.conversationType = .group
        conversation3.lastModifiedDate = Date(timeIntervalSince1970: 1400)
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()

        let token = conversationList.add(testObserver)
        XCTAssertEqual(conversationList.count, 3)
        
        // when
        conversation2.lastModifiedDate = Date(timeIntervalSince1970: 1000000)
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversationList.count, 3)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [ZMMovedIndex(from: 1, to: 0)])
        }
        conversationList.removeObserver(for: token)

    }
    
    func testThatTheListIsOrderedWhenAConversationIsInserted()
    {
        // given
        let conversation1 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation1.conversationType = .group
        conversation1.lastModifiedDate = Date(timeIntervalSince1970: 30)
        
        let conversation2 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation2.conversationType = .group
        conversation2.lastModifiedDate = Date(timeIntervalSince1970: 100)
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()

        let token = conversationList.add(testObserver)
        XCTAssertEqual(conversationList.count, 2)
        
        // when
        let conversation3 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation3.conversationType = .group
        conversation3.lastModifiedDate = Date(timeIntervalSince1970: 50)
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversationList.count, 3)
        XCTAssertEqual(conversationList[0] as? ZMConversation, conversation2)
        XCTAssertEqual(conversationList[1] as? ZMConversation, conversation3)
        XCTAssertEqual(conversationList[2] as? ZMConversation, conversation1)
        
        conversationList.removeObserver(for: token)

    }
    
    func testThatAnObserverIsNotNotifiedAfterBeingRemoved()
    {
        // given
        let conversation1 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation1.conversationType = .group
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        self.uiMOC.saveOrRollback()
        
        XCTAssertEqual(conversationList.count, 1)
        
        // when
        conversationList.removeObserver(for: token)
        let conversation2 = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation2.conversationType = .group
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(conversationList.count, 2)
        XCTAssertEqual(testObserver.changes.count, 0)
    }
    
    
    func testThatItNotifiesTheObserverIfTheConnectionStateOfAConversationChangesAndAfterThatItMatchesAList()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.connection = ZMConnection.insertNewObject(in: self.uiMOC)
        conversation.connection!.status = .pending
        conversation.conversationType = .connection
        
        let pendingList = ZMConversation.pendingConversations(in: self.uiMOC)
        let normalList = ZMConversation.conversationsIncludingArchived(in: self.uiMOC)

        let pendingObserver = TestObserver()
        let token1 = pendingList.add(pendingObserver)
        
        let normalObserver = TestObserver()
        let token2 = normalList.add(normalObserver)
        
        self.uiMOC.saveOrRollback()
        
        XCTAssertEqual(pendingList.count, 1)
        XCTAssertEqual(normalList.count, 0)

        // when
        conversation.connection!.status = .accepted
        conversation.conversationType = .oneOnOne
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(pendingList.count, 0)
        XCTAssertEqual(normalList.count, 1)
        
        XCTAssertEqual(pendingObserver.changes.count, 1)
        XCTAssertEqual(normalObserver.changes.count, 1)
        if let pendingNote = pendingObserver.changes.first {
            XCTAssertEqual(pendingNote.insertedIndexes, IndexSet())
            XCTAssertEqual(pendingNote.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(pendingNote.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(pendingNote), [])
        }
        if let normalNote = normalObserver.changes.first {
            XCTAssertEqual(normalNote.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(normalNote.deletedIndexes, IndexSet())
            XCTAssertEqual(normalNote.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(normalNote), [])
        }
        pendingList.removeObserver(for: token1)
        normalList.removeObserver(for: token2)

    }
    
    func testThatItNotifiesListObserversWhenAConversationIsRemovedFromTheListBecauseItIsArchived()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        conversation.isArchived = true
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }
    
    func testThatItNotifiesObserversWhenAConversationUpdatesUserDefinedName()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        conversation.userDefinedName = "Soap"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }

    func testThatItNotifiesObserversWhenAUserInAConversationChangesTheirName()
    {
        // given
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        conversation.mutableOtherActiveParticipants.add(user)
        conversation.conversationType = .group
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        user.name = "Foo"
        self.uiMOC.saveOrRollback()
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        user.name = "Soap"
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }

    func testThatItNotifiesObserversWhenThereIsAnUnreadPingInAConversation()
    {
        // given
        let conversation =  ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        
        self.uiMOC.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        self.simulateUnreadMissedKnock(in: conversation)
        self.uiMOC.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)
    }
    
    func testThatItNotifiesObserversWhenTheEstimatedUnreadCountChanges()
    {
        // given
        let conversation =  ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        conversation.lastServerTimeStamp = Date()
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp
        
        let message = ZMMessage.insertNewObject(in: self.uiMOC)
        message.serverTimestamp = Date()
        
        self.uiMOC.saveOrRollback()
        
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        XCTAssertEqual(conversation.estimatedUnreadCount, 0)
        
        // when
        self.simulateUnreadCount(1, for: conversation)
        self.uiMOC.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(conversation.estimatedUnreadCount, 1)

        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }

    func testThatItDoesNotNotifyObserversWhenTheOnlyChangeIsAnInsertedMessage()
    {
        // given
        let conversation =  ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        conversation.conversationType = .group
        
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        conversation.mutableMessages.add(ZMTextMessage.insertNewObject(in: self.uiMOC))
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 0)
        conversationList.removeObserver(for: token)

    }

    func testThatItNotifiesObserversWhenTheUserInOneOnOneConversationGetsBlocked()
    {
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        
        let conversation = ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.connection = ZMConnection.insertNewObject(in: self.uiMOC)
        conversation.connection?.status = .accepted
        conversation.conversationType = .oneOnOne
        conversation.connection?.to = user
        self.uiMOC.saveOrRollback()

        let normalList = ZMConversation.conversationsIncludingArchived(in: self.uiMOC)
        
        let testObserver = TestObserver()
        let token = normalList.add(testObserver)
        
        XCTAssertEqual(normalList.count, 1)
        
        // when
        user.connection!.status = .blocked
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(normalList.count, 0)
        
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
        normalList.removeObserver(for: token)
    }
    
    func testThatItNotifiesObserversWhenAMessageBecomesUnreadUnsent()
    {
        // given
        
        let message = ZMTextMessage.insertNewObject(in: self.uiMOC)

        let conversation =  ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        conversation.mutableMessages.add(message)

        
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        
        // when
        message.expire()
        
        self.uiMOC.saveOrRollback()
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }

    func testThatItNotifiesObserversWhenWeInsertAnUnreadMissedCall()
    {
        // given
        let conversation =  ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)

        // when
        self.simulateUnreadMissedCall(in: conversation)
        self.uiMOC.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
        conversationList.removeObserver(for: token)

    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let message = ZMTextMessage.insertNewObject(in: self.uiMOC)
        
        let conversation =  ZMConversation.insertNewObject(in:self.uiMOC)
        conversation.conversationType = .group
        conversation.mutableMessages.add(message)
        
        
        self.uiMOC.saveOrRollback()
        
        let conversationList = ZMConversation.conversationsExcludingArchived(in: self.uiMOC)
        let testObserver = TestObserver()
        let token = conversationList.add(testObserver)
        conversationList.removeObserver(for: token)
        
        // when
        message.expire()
        self.uiMOC.saveOrRollback()

        
        // then
        XCTAssertEqual(testObserver.changes.count, 0)
    }

}

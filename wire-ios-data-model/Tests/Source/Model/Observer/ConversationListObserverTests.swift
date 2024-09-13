//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

@testable import WireDataModel

class ConversationListObserverTests: NotificationDispatcherTestBase {
    class TestObserver: NSObject, ZMConversationListObserver {
        var changes: [ConversationListChangeInfo] = []

        func conversationListDidChange(_ changeInfo: ConversationListChangeInfo) {
            changes.append(changeInfo)
        }
    }

    var testObserver: TestObserver!

    class TestConversationListReloadObserver: NSObject, ZMConversationListReloadObserver {
        var conversationListsReloadCount = 0

        func conversationListsDidReload() {
            conversationListsReloadCount += 1
        }
    }

    var testConversationListReloadObserver: TestConversationListReloadObserver!

    class TestConversationListFolderObserver: NSObject, ZMConversationListFolderObserver {
        var conversationListsFolderChangeCount = 0

        func conversationListsDidChangeFolders() {
            conversationListsFolderChangeCount += 1
        }
    }

    var testConversationListFolderObserver: TestConversationListFolderObserver!

    override func setUp() {
        testObserver = TestObserver()
        testConversationListReloadObserver = TestConversationListReloadObserver()
        testConversationListFolderObserver = TestConversationListFolderObserver()
        super.setUp()
    }

    override func tearDown() {
        testObserver = nil
        testConversationListReloadObserver = nil
        testConversationListFolderObserver = nil
        super.tearDown()
    }

    fileprivate func movedIndexes(_ changeSet: ConversationListChangeInfo) -> [MovedIndex] {
        var array: [MovedIndex] = []
        changeSet.enumerateMovedIndexes { (x: Int, y: Int) in array.append(MovedIndex(from: x, to: y)) }
        return array
    }

    func testThatItDeallocates() {
        // given
        let conversationList = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        uiMOC.saveOrRollback()

        // when
        weak var observerCenter = uiMOC.conversationListObserverCenter
        uiMOC.userInfo.removeObject(forKey: NSManagedObjectContext.conversationListObserverCenterKey)

        // then
        XCTAssertNil(observerCenter)
        XCTAssertNotNil(conversationList)
    }

    func testThatItNotifiesObserversWhenConversationListsAreReloaded() {
        // given
        sut.isEnabled = false
        token = ConversationListChangeInfo.addReloadObserver(
            testConversationListReloadObserver,
            managedObjectContext: uiMOC
        )

        // when
        sut.isEnabled = true

        // then
        XCTAssertEqual(testConversationListReloadObserver.conversationListsReloadCount, 1)
    }

    func testThatItNotifiesObserversWhenANewConversationIsInsertedThatMatchesListPredicate() {
        // given
        let conversationList = ZMConversation.pendingConversations(in: uiMOC)
        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        syncMOC.performGroupedAndWait {
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .connection

            let user = ZMUser.insertNewObject(in: self.syncMOC)
            user.connection = ZMConnection.insertNewObject(in: self.syncMOC)
            user.connection?.status = .pending
            user.oneOnOneConversation = conversation

            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItDoesNotNotifyObserversWhenANewConversationIsInsertedThatDoesNotMatchListPredicate() {
        // given
        let conversationList = ZMConversation.archivedConversations(in: uiMOC)

        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 0)
    }

    func testThatItNotifiesObserversWhenAConversationChangesSoItNowDoesNotMatchThePredicate() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAConversationChangesToNotMatchThePredicateAndThenToMatchThePredicateAgain() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.isArchived = true
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        conversation.isArchived = false
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
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
    }

    func testThatItNotifiesObserversWhenAConversationChangesSoItNowDoesMatchThePredicate() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        uiMOC.saveOrRollback()
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        XCTAssertEqual(conversationList.items.count, 0)

        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.isArchived = false
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatAConversationThatGetsAddedToTheListIsLaterRemovedWhenItChangesNotToMatchThePredicate() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.isArchived = true
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.isArchived = false
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)

        // and when
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(conversationList.items.count, 0)
        XCTAssertEqual(testObserver.changes.count, 2)
        if let last = testObserver.changes.last {
            XCTAssertEqual(last.insertedIndexes, IndexSet())
            XCTAssertEqual(last.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(last.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(last), [])
        }
    }

    func testThatTheListIsReorderedWhenAConversationChangesTheLastModifiedTime() {
        assertThatTheListIsReorderedWhenAConversationChangesTheLastModifiedTime()
    }

    func assertThatTheListIsReorderedWhenAConversationChangesTheLastModifiedTime(
        team: Team? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // given
        let conversation1 = ZMConversation.insertNewObject(in: uiMOC)
        conversation1.team = team
        conversation1.conversationType = .group
        conversation1.lastModifiedDate = Date(timeIntervalSince1970: 30)

        let conversation2 = ZMConversation.insertNewObject(in: uiMOC)
        conversation2.conversationType = .group
        conversation2.team = team
        conversation2.lastModifiedDate = Date(timeIntervalSince1970: 90)

        let conversation3 = ZMConversation.insertNewObject(in: uiMOC)
        conversation3.conversationType = .group
        conversation3.team = team
        conversation3.lastModifiedDate = Date(timeIntervalSince1970: 1400)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        XCTAssertEqual(
            conversationList.items.map(\.objectID),
            [conversation3, conversation2, conversation1].map(\.objectID),
            file: file,
            line: line
        )

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )
        XCTAssertEqual(conversationList.items.count, 3, file: file, line: line)

        // when
        conversation2.lastModifiedDate = Date(timeIntervalSince1970: 1_000_000)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        // then
        XCTAssertEqual(
            conversationList.items.map(\.objectID),
            [conversation2, conversation3, conversation1].map(\.objectID),
            file: file,
            line: line
        )
        XCTAssertEqual(conversationList.items.count, 3, file: file, line: line)
        XCTAssertEqual(testObserver.changes.count, 1, file: file, line: line)
        if let first = testObserver.changes.last {
            XCTAssertEqual(first.insertedIndexes, IndexSet(), file: file, line: line)
            XCTAssertEqual(first.deletedIndexes, IndexSet(), file: file, line: line)
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0), file: file, line: line)
            XCTAssertEqual(movedIndexes(first), [MovedIndex(from: 1, to: 0)], file: file, line: line)
        }
    }

    func testThatTheListIsOrderedWhenAConversationIsInserted() {
        assertThatTheListIsOrderedWhenAConversationIsInserted()
    }

    func assertThatTheListIsOrderedWhenAConversationIsInserted(
        team: Team? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // given
        let conversation1 = ZMConversation.insertNewObject(in: uiMOC)
        conversation1.conversationType = .group
        conversation1.team = team
        conversation1.lastModifiedDate = Date(timeIntervalSince1970: 30)

        let conversation2 = ZMConversation.insertNewObject(in: uiMOC)
        conversation2.conversationType = .group
        conversation2.team = team
        conversation2.lastModifiedDate = Date(timeIntervalSince1970: 100)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        let testObserver = TestObserver()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )
        XCTAssertEqual(conversationList.items.count, 2, file: file, line: line)

        // when
        let conversation3 = ZMConversation.insertNewObject(in: uiMOC)
        conversation3.conversationType = .group
        conversation3.team = team
        conversation3.lastModifiedDate = Date(timeIntervalSince1970: 50)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)

        // then
        XCTAssertEqual(conversationList.items.count, 3, file: file, line: line)
        XCTAssertEqual(conversationList.items[0], conversation2, file: file, line: line)
        XCTAssertEqual(conversationList.items[1], conversation3, file: file, line: line)
        XCTAssertEqual(conversationList.items[2], conversation1, file: file, line: line)
    }

    func testThatAnObserverIsNotNotifiedAfterBeingRemoved() {
        // given
        let conversation1 = ZMConversation.insertNewObject(in: uiMOC)
        conversation1.conversationType = .group

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        uiMOC.saveOrRollback()
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        XCTAssertEqual(conversationList.items.count, 1)
        XCTAssertEqual(testObserver.changes.count, 0)

        // when
        token = nil
        let conversation2 = ZMConversation.insertNewObject(in: uiMOC)
        conversation2.conversationType = .group
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(conversationList.items.count, 2)
        XCTAssertEqual(testObserver.changes.count, 0)
    }

    func testThatItNotifiesTheObserverIfTheConnectionStateOfAConversationChangesAndAfterThatItMatchesAList() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .connection

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.connection = ZMConnection.insertNewObject(in: uiMOC)
        user.connection?.status = .pending
        user.oneOnOneConversation = conversation
        uiMOC.saveOrRollback()

        let pendingList = ZMConversation.pendingConversations(in: uiMOC)
        let normalList = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        let pendingObserver = TestObserver()
        var tokenArray: [Any] = []
        token = tokenArray
        tokenArray.append(ConversationListChangeInfo.addListObserver(
            pendingObserver,
            for: pendingList,
            managedObjectContext: uiMOC
        ))

        let normalObserver = TestObserver()
        tokenArray.append(ConversationListChangeInfo.addListObserver(
            normalObserver,
            for: normalList,
            managedObjectContext: uiMOC
        ))

        XCTAssertEqual(pendingList.items.count, 1)
        XCTAssertEqual(normalList.items.count, 0)

        // when
        user.connection?.status = .accepted
        conversation.conversationType = .oneOnOne
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(pendingList.items.count, 0)
        XCTAssertEqual(normalList.items.count, 1)

        XCTAssertEqual(pendingObserver.changes.count, 1)
        XCTAssertEqual(normalObserver.changes.count, 1)
        if let pendingNote = pendingObserver.changes.last {
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
    }

    func testThatItNotifiesListObserversWhenAConversationIsRemovedFromTheListBecauseItIsArchived() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.isArchived = true
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAConversationUpdatesUserDefinedName() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.userDefinedName = "Soap"
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAUserInAConversationChangesTheirName() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        let user = ZMUser.insertNewObject(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        conversation.conversationType = .group

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        uiMOC.saveOrRollback()

        user.name = "Foo"
        uiMOC.saveOrRollback()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        user.name = "Soap"
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenThereIsAnUnreadPingInAConversation() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        uiMOC.saveOrRollback()
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        simulateUnreadMissedKnock(in: conversation, merge: mergeLastChanges)
        XCTAssertTrue(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenTheEstimatedUnreadCountChanges() {
        assertThatItNotifiesObserversWhenTheEstimatedUnreadCountChanges()
    }

    func assertThatItNotifiesObserversWhenTheEstimatedUnreadCountChanges(
        team: Team? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.lastServerTimeStamp = Date()
        conversation.team = team
        conversation.lastReadServerTimeStamp = conversation.lastServerTimeStamp

        let message = ZMMessage(nonce: UUID(), managedObjectContext: uiMOC)
        message.serverTimestamp = Date()
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        XCTAssertEqual(conversation.estimatedUnreadCount, 0, file: file, line: line)

        // when
        simulateUnreadCount(1, for: conversation, merge: mergeLastChanges)

        // then
        XCTAssertEqual(conversation.estimatedUnreadCount, 1, file: file, line: line)

        XCTAssertEqual(testObserver.changes.count, 1, file: file, line: line)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet(), file: file, line: line)
            XCTAssertEqual(first.deletedIndexes, IndexSet(), file: file, line: line)
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0), file: file, line: line)
            XCTAssertEqual(movedIndexes(first), [], file: file, line: line)
        }
    }

    func testThatItNotifiesObserversWhenTheOnlyChangeIsAnInsertedMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        conversation.conversationType = .group

        uiMOC.saveOrRollback()

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.mutableMessages.add(TextMessage(nonce: UUID(), managedObjectContext: uiMOC))
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
    }

    func testThatItNotifiesObserversForMessageChangesAfterPostingANewMessage() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        conversation.conversationType = .group
        conversation.addParticipantAndUpdateConversationState(user: ZMUser.selfUser(in: uiMOC), role: nil)
        uiMOC.saveOrRollback()

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        let message = try? conversation.appendText(content: "hello")
        uiMOC.saveOrRollback()

        guard let user = conversation.participantRoles.first?.user else { XCTFail(); return }

        message?.textMessageData?.editText(
            user.name ?? "",
            mentions: [Mention(
                range: NSRange(
                    location: 0,
                    length: (user.name ?? "").count
                ),
                user: user
            )],
            fetchLinkPreview: false
        )
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
    }

    func testThatItNotifiesObserversWhenTheUserInOneOnOneConversationGetsBlocked() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.connection = ZMConnection.insertNewObject(in: uiMOC)
        user.connection?.status = .accepted
        user.oneOnOneConversation = conversation

        uiMOC.saveOrRollback()

        let normalList = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: normalList,
            managedObjectContext: uiMOC
        )

        XCTAssertEqual(normalList.items.count, 1)

        // when
        user.connection!.status = .blocked
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(normalList.items.count, 0)

        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenTheUserInOneOnOneConversationGetsBlockedDueToMissingLegalholdConsent() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .oneOnOne

        let user = ZMUser.insertNewObject(in: uiMOC)
        user.connection = ZMConnection.insertNewObject(in: uiMOC)
        user.connection?.status = .accepted
        user.oneOnOneConversation = conversation

        uiMOC.saveOrRollback()

        let normalList = ZMConversation.conversationsIncludingArchived(in: uiMOC)

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: normalList,
            managedObjectContext: uiMOC
        )

        XCTAssertEqual(normalList.items.count, 1)

        // when
        user.connection!.status = .blockedMissingLegalholdConsent
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(normalList.items.count, 0)

        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAMessageBecomesUnreadUnsent() {
        // given
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.mutableMessages.add(message)
        uiMOC.saveOrRollback()

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        message.expire()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenWeInsertAnUnreadMissedCall() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        uiMOC.saveOrRollback()

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        simulateUnreadMissedCall(in: conversation, merge: mergeLastChanges)

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAConversationMlsStatusChanges() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.mlsStatus = .pendingJoin
        conversation.messageProtocol = .mls
        conversation.conversationType = .group
        uiMOC.saveOrRollback()

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        XCTAssertEqual(conversationList.items.count, 0)

        // when
        conversation.mlsStatus = .ready
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(conversationList.items.count, 1)

        XCTAssertEqual(testObserver.changes.count, 1)
        let change = try XCTUnwrap(testObserver.changes.first)
        XCTAssertEqual(change.insertedIndexes, IndexSet(integer: 0))
        XCTAssertEqual(change.deletedIndexes, IndexSet())
        XCTAssertEqual(change.updatedIndexes, IndexSet())
        XCTAssertEqual(movedIndexes(change), [])
    }

    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        // given
        let message = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)

        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.mutableMessages.add(message)
        uiMOC.saveOrRollback()

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        token = nil
        message.expire()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.changes.count, 0)
    }

    func testThatItSendsTheCorrectUpdatesWhenRegisteringAnObserverDuringInsertAndUpdate() {
        // given
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        var conversation: ZMConversation!
        syncMOC.performGroupedAndWait {
            conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            self.syncMOC.saveOrRollback()
        }

        // when
        // This simulates an objectsDidChange notification without the immediate merge afterwards
        mergeLastChangesWithoutNotifying()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        //
        XCTAssertEqual(conversationList.items.count, 0)
        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        syncMOC.performGroupedAndWait {
            conversation.userDefinedName = "foo"
            self.syncMOC.saveOrRollback()
        }
        mergeLastChanges()

        // then
        XCTAssertEqual(conversationList.items.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatCanGetTheCurrentStateFromTheChangeInfo() {
        assertThatCanGetTheCurrentStateFromTheChangeInfo()
    }

    func assertThatCanGetTheCurrentStateFromTheChangeInfo(
        team: Team? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // given
        let conversation1 = ZMConversation.insertNewObject(in: uiMOC)
        conversation1.conversationType = .group
        conversation1.lastModifiedDate = Date(timeIntervalSince1970: 100)
        conversation1.team = team
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)

        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        let testObserver = TestObserver()

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )
        XCTAssertEqual(conversationList.items.count, 1, file: file, line: line)

        // when
        let conversation2 = ZMConversation.insertNewObject(in: uiMOC)
        conversation2.conversationType = .group
        conversation2.team = team
        conversation2.lastModifiedDate = Date(timeIntervalSince1970: 50)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)

        // when
        guard let changes1 = testObserver.changes.last else { return XCTFail("Did not sent notification") }
        XCTAssertEqual(
            changes1.orderedSetState,
            OrderedSetState(array: [conversation1, conversation2]),
            file: file,
            line: line
        )
        XCTAssertEqual(conversationList.items.count, 2, file: file, line: line)

        // when
        let conversation3 = ZMConversation.insertNewObject(in: uiMOC)
        conversation3.conversationType = .group
        conversation3.team = team
        conversation3.lastModifiedDate = Date(timeIntervalSince1970: 30)
        XCTAssert(uiMOC.saveOrRollback(), file: file, line: line)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5), file: file, line: line)

        // then
        // The set of the previous notification should not change
        XCTAssertEqual(
            changes1.orderedSetState,
            OrderedSetState(array: [conversation1, conversation2]),
            file: file,
            line: line
        )
        XCTAssertEqual(conversationList.items.count, 3, file: file, line: line)

        // The set of the new notification contains the new state
        guard let changes2 = testObserver.changes.last else { return XCTFail("Did not sent notification") }
        XCTAssertEqual(
            changes2.orderedSetState,
            OrderedSetState(array: [conversation1, conversation2, conversation3]),
            file: file,
            line: line
        )
    }

    // MARK: Folders

    func testThatItNotifiesTheObserver_WhenAFolderIsCreated() {
        // given
        var token: Any? = ConversationListChangeInfo.addFolderObserver(
            testConversationListFolderObserver,
            managedObjectContext: uiMOC
        )
        XCTAssertNotNil(token)

        // when
        _ = uiMOC.conversationListDirectory().createFolder("Folder 1")
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(testConversationListFolderObserver.conversationListsFolderChangeCount, 1)
        token = nil
    }

    func testThatItNotifiesTheObserver_WhenAFolderIsDeleted() {
        // given
        let folder = uiMOC.conversationListDirectory().createFolder("Folder 1") as! Label
        XCTAssertTrue(uiMOC.saveOrRollback())
        var token: Any? = ConversationListChangeInfo.addFolderObserver(
            testConversationListFolderObserver,
            managedObjectContext: uiMOC
        )
        XCTAssertNotNil(token)

        // when
        uiMOC.delete(folder)
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(testConversationListFolderObserver.conversationListsFolderChangeCount, 1)
        token = nil
    }

    func testThatItUpdatesTheFolderList_WhenAFolderIsCreated() {
        // given
        XCTAssertEqual(uiMOC.conversationListDirectory().allFolders.count, 0)

        // when
        _ = uiMOC.conversationListDirectory().createFolder("Folder 1")
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(uiMOC.conversationListDirectory().allFolders.count, 1)
    }

    func testThatItUpdatesTheFolderList_WhenAFolderIsMarkedForDeletion() {
        // given
        let label = uiMOC.conversationListDirectory().createFolder("Folder 1") as! Label
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertEqual(uiMOC.conversationListDirectory().allFolders.count, 1)

        // when
        label.markForDeletion()
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(uiMOC.conversationListDirectory().allFolders.count, 0)
    }

    func testThatItUpdatesTheFolderList_WhenAFolderIsDeleted() {
        // given
        let label = uiMOC.conversationListDirectory().createFolder("Folder 1") as! Label
        XCTAssertTrue(uiMOC.saveOrRollback())
        XCTAssertEqual(uiMOC.conversationListDirectory().allFolders.count, 1)

        // when
        uiMOC.delete(label)
        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(uiMOC.conversationListDirectory().allFolders.count, 0)
    }

    func testThatItThatTheFolderListIsSortedByName() {
        // given
        _ = uiMOC.conversationListDirectory().createFolder("B")
        _ = uiMOC.conversationListDirectory().createFolder("F")
        _ = uiMOC.conversationListDirectory().createFolder("C")
        _ = uiMOC.conversationListDirectory().createFolder("A")

        XCTAssertTrue(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(uiMOC.conversationListDirectory().allFolders.map(\.name), ["A", "B", "C", "F"])
    }

    // MARK: Teams

    func testThatItNotifiesTheObserverIfAConversationGetsArchived() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        let teamId = UUID.create()
        team.remoteIdentifier = teamId
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.team = team
        conversation.remoteIdentifier = .create()
        let conversationList = ZMConversation.conversationsIncludingArchived(in: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.isArchived = true

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])

            let archivedList = ZMConversation.archivedConversations(in: uiMOC)
            XCTAssertEqual(archivedList.items.first, conversation)
        }
    }

    func testThatItOnlyNotifiesTheObserverIrregardlessOfTheTeam() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        let teamId = UUID.create()
        team.remoteIdentifier = teamId
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.team = team
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        syncMOC.performGroupedAndWait {
            let team = Team.fetch(with: teamId, in: self.syncMOC)
            let conversation = ZMConversation.insertNewObject(in: self.syncMOC)
            conversation.conversationType = .group
            conversation.team = team

            let otherTeamConversation = ZMConversation.insertNewObject(in: self.syncMOC)
            otherTeamConversation.conversationType = .group
            otherTeamConversation.team = Team.fetchOrCreate(with: .create(), in: self.syncMOC)

            self.syncMOC.saveOrRollback()
        }

        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        mergeLastChanges()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet(integersIn: 0 ... 1))
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet())
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAConversationUpdatesUserDefinedNameInATeam() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.team = team
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.userDefinedName = "New Name"
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAUserInAConversationOfATeamChangesTheirName() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.team = team
        let user = ZMUser.insertNewObject(in: uiMOC)
        conversation.addParticipantAndUpdateConversationState(user: user, role: nil)
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)
        XCTAssert(uiMOC.saveOrRollback())

        user.name = "Old Name"
        XCTAssert(uiMOC.saveOrRollback())

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        user.name = "New Name"
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        if let first = testObserver.changes.first {
            XCTAssertEqual(first.insertedIndexes, IndexSet())
            XCTAssertEqual(first.deletedIndexes, IndexSet())
            XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
            XCTAssertEqual(movedIndexes(first), [])
        }
    }

    func testThatItNotifiesObserversWhenAConversationsTeamChangesSoItNowDoesMatch() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        XCTAssert(uiMOC.saveOrRollback())

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.team = team
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        guard let first = testObserver.changes.first else { return }
        XCTAssertEqual(first.insertedIndexes, IndexSet())
        XCTAssertEqual(first.deletedIndexes, IndexSet())
        XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
        XCTAssertEqual(movedIndexes(first), [])
    }

    func testThatItNotifiesObserversWhenAConversationsTeamChangesSoItNowDoesNotMatch() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.team = team
        let conversationList = ZMConversation.conversationsExcludingArchived(in: uiMOC)

        XCTAssert(uiMOC.saveOrRollback())

        token = ConversationListChangeInfo.addListObserver(
            testObserver,
            for: conversationList,
            managedObjectContext: uiMOC
        )

        // when
        conversation.team = nil
        XCTAssert(uiMOC.saveOrRollback())

        // then
        XCTAssertEqual(testObserver.changes.count, 1)
        guard let first = testObserver.changes.first else { return }
        XCTAssertEqual(first.insertedIndexes, IndexSet())
        XCTAssertEqual(first.deletedIndexes, IndexSet())
        XCTAssertEqual(first.updatedIndexes, IndexSet(integer: 0))
        XCTAssertEqual(movedIndexes(first), [])
    }

    func testThatTheListIsOrderedAfterChangesInATeam() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()

        // then
        assertThatTheListIsOrderedWhenAConversationIsInserted(team: team)
    }

    func testThatItCanGetTheCurrentStateFromTheChangeInfoInATeam() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()

        // then
        assertThatCanGetTheCurrentStateFromTheChangeInfo(team: team)
    }

    func testThatItNotifiesTheObserversWhenTheEstimatedUnreadCountChangesInATeam() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()

        // then
        assertThatItNotifiesObserversWhenTheEstimatedUnreadCountChanges(team: team)
    }

    func testThatTheListIsReorderedWhenAConversationChangesTheLastModifiedTimeInATeam() {
        // given
        let team = Team.insertNewObject(in: uiMOC)
        team.remoteIdentifier = .create()

        // then
        assertThatTheListIsReorderedWhenAConversationChangesTheLastModifiedTime(team: team)
    }
}

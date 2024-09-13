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

import Foundation

@objc
class UnreadMessageTestObserver: NSObject, ZMNewUnreadMessagesObserver, ZMNewUnreadKnocksObserver {
    var unreadMessageNotes: [NewUnreadMessagesChangeInfo] = []
    var unreadKnockNotes: [NewUnreadKnockMessagesChangeInfo] = []

    override init() {
        super.init()
    }

    @objc
    func didReceiveNewUnreadKnockMessages(_ changeInfo: NewUnreadKnockMessagesChangeInfo) {
        unreadKnockNotes.append(changeInfo)
    }

    @objc
    func didReceiveNewUnreadMessages(_ changeInfo: NewUnreadMessagesChangeInfo) {
        unreadMessageNotes.append(changeInfo)
    }

    func clearNotifications() {
        unreadKnockNotes = []
        unreadMessageNotes = []
    }
}

class NewUnreadMessageObserverTests: NotificationDispatcherTestBase {
    func processPendingChangesAndClearNotifications() {
        uiMOC.saveOrRollback()
        testObserver?.clearNotifications()
    }

    var testObserver: UnreadMessageTestObserver!
    var newMessageToken: NSObjectProtocol!
    var newKnocksToken: NSObjectProtocol!

    override func setUp() {
        super.setUp()

        testObserver = UnreadMessageTestObserver()
        newMessageToken = NewUnreadMessagesChangeInfo.add(
            observer: testObserver,
            managedObjectContext: uiMOC
        )
        newKnocksToken = NewUnreadKnockMessagesChangeInfo.add(
            observer: testObserver,
            managedObjectContext: uiMOC
        )
    }

    override func tearDown() {
        newMessageToken = nil
        newKnocksToken = nil
        testObserver = nil

        super.tearDown()
    }

    func testThatItNotifiesObserversWhenAMessageMoreRecentThanTheLastReadIsInserted() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        uiMOC.saveOrRollback()

        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.serverTimestamp = Date()
        msg1.visibleInConversation = conversation

        let msg2 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg2.serverTimestamp = Date()
        msg2.visibleInConversation = conversation

        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver.unreadMessageNotes.count, 1)
        XCTAssertEqual(testObserver.unreadKnockNotes.count, 0)

        if let note = testObserver.unreadMessageNotes.first {
            let expected = NSSet(objects: msg1, msg2)
            XCTAssertEqual(NSSet(array: note.messages), expected)
        }
    }

    func testThatItDoesNotNotifyObserversWhenAMessageOlderThanTheLastReadIsInserted() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastReadServerTimeStamp = Date().addingTimeInterval(30)
        processPendingChangesAndClearNotifications()

        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.visibleInConversation = conversation
        msg1.serverTimestamp = Date()

        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver!.unreadMessageNotes.count, 0)
    }

    func testThatItNotifiesObserversWhenTheConversationHasNoLastRead() {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        processPendingChangesAndClearNotifications()

        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.visibleInConversation = conversation
        msg1.serverTimestamp = Date()

        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver!.unreadMessageNotes.count, 1)
    }

    func testThatItDoesNotNotifyObserversWhenItHasNoConversation() {
        // when
        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        msg1.serverTimestamp = Date()

        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver!.unreadMessageNotes.count, 0)
    }

    func testThatItNotifiesObserversWhenANewOTRKnockMessageIsInserted() throws {
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.lastReadServerTimeStamp = Date()
        processPendingChangesAndClearNotifications()

        // when
        let genMsg = GenericMessage(content: Knock.with { $0.hotKnock = false })

        let msg1 = ZMClientMessage(nonce: UUID(), managedObjectContext: uiMOC)
        try msg1.setUnderlyingMessage(genMsg)
        msg1.visibleInConversation = conversation
        msg1.serverTimestamp = Date()
        uiMOC.saveOrRollback()

        // then
        XCTAssertEqual(testObserver!.unreadKnockNotes.count, 1)
        XCTAssertEqual(testObserver!.unreadMessageNotes.count, 0)
        if let note = testObserver?.unreadKnockNotes.first {
            let expected = NSSet(object: msg1)
            XCTAssertEqual(NSSet(array: note.messages), expected)
        }
    }
}

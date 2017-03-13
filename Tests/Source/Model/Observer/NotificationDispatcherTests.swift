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
@testable import ZMCDataModel



@objc public class NotificationDispatcherTestBase : ZMBaseManagedObjectTest {

    var dispatcher : NotificationDispatcher! {
        return sut
    }
    var sut : NotificationDispatcher!
    var conversationObserver : ConversationObserver!
    var mergeNotifications = [Notification]()
    
    override public func setUp() {
        super.setUp()
        conversationObserver = ConversationObserver()
        sut = NotificationDispatcher(managedObjectContext: uiMOC)
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationDispatcherTestBase.contextDidMerge(_:)), name: Notification.Name.NSManagedObjectContextDidSave, object: syncMOC)
        mergeNotifications = []
    }
    
    override public func tearDown() {
        NotificationCenter.default.removeObserver(self)
        sut.tearDown()
        sut = nil
        mergeNotifications = []
        super.tearDown()
    }
    
    @objc public func contextDidMerge(_ note: Notification) {
        mergeNotifications.append(note)
    }
    
    @objc public func mergeLastChanges() {
        let changedObjects =  mergeLastChangesWithoutNotifying()
        self.dispatcher.didMergeChanges(Set(changedObjects))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

    }
    @objc @discardableResult public func mergeLastChangesWithoutNotifying() -> [NSManagedObjectID] {
        guard let change = mergeNotifications.last else { return [] }
        let changedObjects = (change.userInfo?[NSUpdatedObjectsKey] as? Set<ZMManagedObject>)?.map{$0.objectID} ?? []
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        self.uiMOC.mergeChanges(fromContextDidSave: change)
        mergeNotifications = []
        return changedObjects
    }

    
}

class NotificationDispatcherTests : NotificationDispatcherTestBase {

    class Wrapper {
        let dispatcher : NotificationDispatcher
        
        init(managedObjectContext: NSManagedObjectContext) {
            self.dispatcher = NotificationDispatcher(managedObjectContext: managedObjectContext)
        }
        deinit{
            dispatcher.tearDown()
        }
    }
    
    func testThatDeallocates(){
        // when
        var wrapper : Wrapper? = Wrapper(managedObjectContext: uiMOC)
        weak var center = wrapper!.dispatcher
        XCTAssertNotNil(center)
        
        // when
        wrapper = nil
        
        // then
        XCTAssertNil(center)
    }
    
    func testThatItNotifiesAboutChanges(){
        
        // given
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let token = ConversationChangeInfo.add(observer: conversationObserver, for: conversation)

        // when
        conversation.userDefinedName = "foo"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(conversationObserver.notifications.count, 1)
        guard let changeInfo = conversationObserver.notifications.first else {
            return XCTFail()
        }
        XCTAssertTrue(changeInfo.nameChanged)
        ConversationChangeInfo.remove(observer: token, for: conversation)
    }
    
    func testThatItNotifiesAboutChangesInOtherObjects(){
        
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "Bernd"
        let conversation = ZMConversation.insertNewObject(in: uiMOC)
        conversation.conversationType = .group
        conversation.mutableOtherActiveParticipants.add(user)
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        let token = ConversationChangeInfo.add(observer: conversationObserver, for: conversation)
        
        // when
        user.name = "Brett"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(conversationObserver.notifications.count, 1)
        guard let changeInfo = conversationObserver.notifications.first else {
            return XCTFail()
        }
        XCTAssertTrue(changeInfo.nameChanged)
        ConversationChangeInfo.remove(observer: token, for: conversation)
    }
    
    func testThatItCanCalculateChangesWhenObjectIsFaulted(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        uiMOC.refresh(user, mergeChanges: true)
        XCTAssertTrue(user.isFault)
        XCTAssertEqual(user.displayName, "foo")
        let observer = UserObserver()
        let token = UserChangeInfo.add(observer: observer, for: user)
        
        // when
        syncMOC.performGroupedBlockAndWait {
            let syncUser = self.syncMOC.object(with: user.objectID) as! ZMUser
            syncUser.name = "bar"
            self.syncMOC.saveOrRollback()
        }
        mergeLastChanges()
        
        // then
        XCTAssertEqual(user.displayName, "bar")
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertTrue(note.nameChanged)
        }
        UserChangeInfo.remove(observer: token, forBareUser: user)
    }
    
    func testThatItProcessesNonCoreDataChangeNotifications(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        let token = UserChangeInfo.add(observer: observer, for: user)
        
        // when
        NotificationDispatcher.notifyNonCoreDataChanges(objectID: user.objectID, changedKeys: ["name"], uiContext: uiMOC)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertTrue(note.nameChanged)
        }
        UserChangeInfo.remove(observer: token, forBareUser: user)
    }
    
    func testThatItOnlySendsNotificationsWhenDidMergeIsCalled(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        let token = UserChangeInfo.add(observer: observer, for: user)
        
        // when
        user.name = "bar"
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        // then
        XCTAssertEqual(observer.notifications.count, 0)
        
        // and when
        sut.didMergeChanges(Set(arrayLiteral: user.objectID))
        
        // then
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertTrue(note.nameChanged)
        }
        UserChangeInfo.remove(observer: token, forBareUser: user)
    }
    
    func testThatItOnlySendsNotificationsWhenDidSaveIsCalled(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        let token = UserChangeInfo.add(observer: observer, for: user)
        
        // when
        user.name = "bar"
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        // then
        XCTAssertEqual(observer.notifications.count, 0)
        
        // and when
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))

        // then
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertTrue(note.nameChanged)
        }
        UserChangeInfo.remove(observer: token, forBareUser: user)
    }
    
    // MARK: Background behaviour
    func testThatItDoesNotProcessChangesWhenAppEntersBackground(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        let token = UserChangeInfo.add(observer: observer, for: user)
        
        // when
        sut.applicationDidEnterBackground()
        user.name = "bar"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(observer.notifications.count, 0)
        UserChangeInfo.remove(observer: token, forBareUser: user)
    }
    
    func testThatItProcessesChangesAfterAppEnteredBackgroundAndNowEntersForegroundAgain(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let observer = UserObserver()
        let token = UserChangeInfo.add(observer: observer, for: user)

        // when
        sut.applicationDidEnterBackground()
        sut.applicationWillEnterForeground()
        user.name = "bar"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertEqual(observer.notifications.count, 1)
        if let note = observer.notifications.first {
            XCTAssertTrue(note.nameChanged)
        }
        UserChangeInfo.remove(observer: token, forBareUser: user)
    }
    
    
    // MARK: ChangeInfoConsumer
    class ChangeConsumer : NSObject, ChangeInfoConsumer {
        var changes : [ClassIdentifier : [ObjectChangeInfo]]?
        var didCallEnterBackground = false
        var didCallEnterForeground = false
        
        func objectsDidChange(changes: [ClassIdentifier : [ObjectChangeInfo]]) {
            self.changes = changes
        }
        
        func applicationDidEnterBackground() {
            didCallEnterBackground = true
        }
        
        func applicationWillEnterForeground() {
            didCallEnterForeground = true
        }
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenAppEntersBackground(){
        // given
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallEnterBackground)

        // when
        sut.applicationDidEnterBackground()
        
        // then
        XCTAssertTrue(consumer.didCallEnterBackground)
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenAppEntersForeground(){
        // given
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertFalse(consumer.didCallEnterForeground)
        
        // when
        sut.applicationWillEnterForeground()
        
        // then
        XCTAssertTrue(consumer.didCallEnterForeground)
    }
    
    func testThatItNotifiesChangeInfoConsumersWhenObjectChanged(){
        // given
        let user = ZMUser.insertNewObject(in: uiMOC)
        user.name = "foo"
        uiMOC.saveOrRollback()
        
        let consumer = ChangeConsumer()
        sut.addChangeInfoConsumer(consumer)
        XCTAssertNil(consumer.changes)
        
        // when
        user.name = "bar"
        uiMOC.saveOrRollback()
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        // then
        XCTAssertNotNil(consumer.changes)
        if let changes = consumer.changes {
            XCTAssertEqual(changes.count, 1)
            guard let userChanges = changes[ZMUser.entityName()] as? [UserChangeInfo],
                  let change = userChanges.first
            else { return XCTFail()}
            XCTAssertTrue(change.nameChanged)
        }
    }
    
    func testThatItProcessesChangedObjectIDsFromMerge(){
        // given
        let conv = ZMConversation.insertNewObject(in: uiMOC)
        uiMOC.saveOrRollback()
        let token = ConversationChangeInfo.add(observer: conversationObserver, for: conv)

        syncMOC.performGroupedBlockAndWait {
            let syncConv = try! self.syncMOC.existingObject(with: conv.objectID) as! ZMConversation
            syncConv.userDefinedName = "foo"
            self.syncMOC.saveOrRollback()
        }
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        self.uiMOC.mergeChanges(fromContextDidSave: mergeNotifications.last!)
        
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        XCTAssertEqual(conversationObserver.notifications.count, 0)

        // when
        sut.didMergeChanges(Set(arrayLiteral: conv.objectID))
        
        // then
        XCTAssertEqual(conversationObserver.notifications.count, 1)
        guard let changeInfo = conversationObserver.notifications.first else {
            return XCTFail()
        }
        XCTAssertTrue(changeInfo.nameChanged)
        ConversationChangeInfo.remove(observer: token, for: conv)
    }
    
}

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

class ObjectDependencyTokenTests : ZMBaseManagedObjectTest {
    
    override func setUp() {
        super.setUp()
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ZMApplicationDidEnterEventProcessingStateNotification"), object: nil)
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testThatItNotifiesAnObserverThatAKeyChanged() {
        
        // given
        var called = false
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        self.uiMOC.saveOrRollback()

        let token = ObjectDependencyToken(
            keyFromParentObjectToObservedObject : KeyPath.keyPathForString("testObject"),
            observedObject : user,
            keysToObserve: KeySet(key: "name"),
            managedObjectContextObserver: self.uiMOC.globalManagedObjectContextObserver) {
            keysAndOldValues in
                called = true
                XCTAssertEqual(Array(keysAndOldValues.keys), [KeyPath.keyPathForString("testObject.name")])
        }
        
        // when
        user.name = "Fabio"
        self.uiMOC.saveOrRollback()

        // then
        XCTAssertTrue(called);
        self.uiMOC.globalManagedObjectContextObserver.removeChangeObserver(token, object: user)
    }
 
    func testThatItDoesNotNotifyTheObserverThatAKeyItDoesNotTrackChanged() {
        
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.accentColorValue = ZMAccentColor.brightYellow
        self.uiMOC.saveOrRollback()
        
        let token = ObjectDependencyToken(
            keyFromParentObjectToObservedObject : KeyPath.keyPathForString("testObject"),
            observedObject : user,
            keysToObserve: KeySet(key: "name"),
            managedObjectContextObserver: self.uiMOC.globalManagedObjectContextObserver
            ) { _ in
            XCTFail()
        }
        
        // when
        user.accentColorValue = ZMAccentColor.brightOrange
        self.uiMOC.saveOrRollback()
        
        self.uiMOC.globalManagedObjectContextObserver.removeChangeObserver(token, object: user)
    }
    
    func testThatItDoesNotNotifyTheObserverForADifferentObject() {
        
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        let user2 = ZMUser.insertNewObject(in:self.uiMOC)
        self.uiMOC.saveOrRollback()
        
        let token = ObjectDependencyToken(
            keyFromParentObjectToObservedObject : KeyPath.keyPathForString("testObject"),
            observedObject : user,
            keysToObserve: KeySet(key: "name"),
            managedObjectContextObserver: self.uiMOC.globalManagedObjectContextObserver
            ) { _ in
                XCTFail()
        }
        
        // when
        user2.name = "Fabio"
        self.uiMOC.saveOrRollback()
        
        self.uiMOC.globalManagedObjectContextObserver.removeChangeObserver(token, object: user)
    }
}

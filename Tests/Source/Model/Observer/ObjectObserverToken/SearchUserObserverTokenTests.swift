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

class SearchUserObserverTokenTests : ZMBaseManagedObjectTest {
    
    class TestSearchUserObserver : NSObject, ZMUserObserver {
        
        var receivedChangeInfo : [UserChangeInfo] = []
        
        func userDidChange(_ changes: UserChangeInfo) {
            receivedChangeInfo.append(changes)
        }
    }
    
    override func setUp() {
        super.setUp()
        self.setUpCaches()
        self.uiMOC.globalManagedObjectContextObserver.syncCompleted(Notification(name: Notification.Name(rawValue: "fake"), object: nil))
        XCTAssert(waitForAllGroupsToBeEmpty(withTimeout: 0.5))
    }
    
    func testThatItNotifiesTheObserverOfASmallProfilePictureChange() {
        
        // given
        let remoteID = UUID.create()
        let searchUser = ZMSearchUser(name: "Hans",
                                      handle: "hans",
                                      accentColor: .brightOrange,
                                      remoteID: remoteID,
                                      user: nil,
                                      syncManagedObjectContext: self.syncMOC,
                                      uiManagedObjectContext:self.uiMOC)!
        
        let testObserver = TestSearchUserObserver()
        let token = ZMUser.add(testObserver, forUsers:[searchUser], managedObjectContext: self.uiMOC)
        
        // when
        searchUser.notifyNewSmallImageData(self.verySmallJPEGData(), managedObjectContextObserver: self.uiMOC.globalManagedObjectContextObserver)
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
        ZMUser.removeObserver(for: token)
    }
    
    func testThatItNotifiesTheObserverOfASmallProfilePictureChangeIfTheInternalUserUpdates() {
        
        // given
        let user = ZMUser.insertNewObject(in:self.uiMOC)
        user.remoteIdentifier = UUID.create()
        self.uiMOC.saveOrRollback()
        let searchUser = ZMSearchUser(name: "Foo",
                                      handle: "foo",
                                      accentColor: .brightYellow,
                                      remoteID: user.remoteIdentifier,
                                      user: user,
                                      syncManagedObjectContext: self.syncMOC,
                                      uiManagedObjectContext:self.uiMOC)!
        
        let testObserver = TestSearchUserObserver()
        let token = ZMUser.add(testObserver, forUsers:[searchUser], managedObjectContext: self.uiMOC)
        
        // when
        user.smallProfileRemoteIdentifier = UUID.create()
        user.imageSmallProfileData = self.verySmallJPEGData()
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
        ZMUser.removeObserver(for: token)
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let remoteID = UUID.create()
        let searchUser = ZMSearchUser(name: "Hans",
                                      handle: "hans",
                                      accentColor: .brightOrange,
                                      remoteID: remoteID,
                                      user: nil,
                                      syncManagedObjectContext: self.syncMOC,
                                      uiManagedObjectContext:self.uiMOC)!
        
        let testObserver = TestSearchUserObserver()
        let token = ZMUser.add(testObserver, forUsers:[searchUser], managedObjectContext: self.uiMOC)
        ZMUser.removeObserver(for: token)
        
        // when
        searchUser.notifyNewSmallImageData(self.verySmallJPEGData(), managedObjectContextObserver: self.uiMOC.globalManagedObjectContextObserver)
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 0)
    }

    
}

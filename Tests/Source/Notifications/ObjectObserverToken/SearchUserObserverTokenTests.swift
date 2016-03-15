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

class SearchUserObserverTokenTests : MessagingTest {
    
    class TestSearchUserObserver : NSObject, ZMUserObserver {
        
        var receivedChangeInfo : [UserChangeInfo] = []
        
        func userDidChange(changes: UserChangeInfo) {
            receivedChangeInfo.append(changes)
        }
    }
    
    func testThatItNotifiesTheObserverOfASmallProfilePictureChange() {
        
        // given
        let remoteID = NSUUID.createUUID()
        let searchUser = ZMSearchUser(name: "Hans", accentColor: .BrightOrange, remoteID: remoteID, user: nil, syncManagedObjectContext: self.syncMOC, uiManagedObjectContext:self.uiMOC)
        
        let testObserver = TestSearchUserObserver()
        let token = ZMUser.addUserObserver(testObserver, forUsers:[searchUser], managedObjectContext: self.uiMOC)
        
        // when
        searchUser.notifyNewSmallImageData(self.verySmallJPEGData(), managedObjectContextObserver: self.uiMOC.globalManagedObjectContextObserver)
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
        ZMUser.removeUserObserverForToken(token)
    }
    
    func testThatItNotifiesTheObserverOfASmallProfilePictureChangeIfTheInternalUserUpdates() {
        
        // given
        let user = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        user.remoteIdentifier = NSUUID.createUUID()
        self.uiMOC.saveOrRollback()
        let searchUser = ZMSearchUser(name: "Foo", accentColor: .BrightYellow, remoteID: user.remoteIdentifier, user: user, syncManagedObjectContext: self.syncMOC, uiManagedObjectContext:self.uiMOC)
        
        let testObserver = TestSearchUserObserver()
        let token = ZMUser.addUserObserver(testObserver, forUsers:[searchUser], managedObjectContext: self.uiMOC)
        
        // when
        user.smallProfileRemoteIdentifier = NSUUID.createUUID()
        user.imageSmallProfileData = self.verySmallJPEGData()
        self.uiMOC.processPendingChanges()
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 1)
        if let note = testObserver.receivedChangeInfo.first {
            XCTAssertTrue(note.imageSmallProfileDataChanged)
        }
        ZMUser.removeUserObserverForToken(token)
    }
    
    func testThatItStopsNotifyingAfterUnregisteringTheToken() {
        
        // given
        let remoteID = NSUUID.createUUID()
        let searchUser = ZMSearchUser(name: "Hans", accentColor: .BrightOrange, remoteID: remoteID, user: nil, syncManagedObjectContext: self.syncMOC, uiManagedObjectContext:self.uiMOC)
        
        let testObserver = TestSearchUserObserver()
        let token = ZMUser.addUserObserver(testObserver, forUsers:[searchUser], managedObjectContext: self.uiMOC)
        ZMUser.removeUserObserverForToken(token)
        
        // when
        searchUser.notifyNewSmallImageData(self.verySmallJPEGData(), managedObjectContextObserver: self.uiMOC.globalManagedObjectContextObserver)
        
        // then
        XCTAssertEqual(testObserver.receivedChangeInfo.count, 0)
    }

    
}

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
import zmessaging

class UserImageLocalCacheTests : BaseZMMessageTests {
    
    var testUser : ZMUser!
    var sut : UserImageLocalCache!
    
    override func setUp() {
        super.setUp()
        testUser = ZMUser.insertNewObjectInManagedObjectContext(self.uiMOC)
        testUser.remoteIdentifier = NSUUID.createUUID()
        testUser.mediumRemoteIdentifier = NSUUID.createUUID()
        testUser.smallProfileRemoteIdentifier = NSUUID.createUUID()
        
        sut = UserImageLocalCache()
    }
    
    func testThatItHasNilDataWhenNotSet() {
        
        XCTAssertNil(sut.largeUserImage(testUser))
        XCTAssertNil(sut.smallUserImage(testUser))
    }
    
    func testThatItSetsSmallAndLargeUserImage() {
        
        // given
        let largeData = "LARGE".dataUsingEncoding(NSUTF8StringEncoding)!
        let smallData = "SMALL".dataUsingEncoding(NSUTF8StringEncoding)!
        
        // when
        sut.setLargeUserImage(testUser, imageData: largeData)
        sut.setSmallUserImage(testUser, imageData: smallData)

        
        // then
        XCTAssertEqual(sut.largeUserImage(testUser), largeData)
        XCTAssertEqual(sut.smallUserImage(testUser), smallData)

    }
    
    func testThatItPersistsSmallAndLargeUserImage() {
        
        // given
        let largeData = "LARGE".dataUsingEncoding(NSUTF8StringEncoding)!
        let smallData = "SMALL".dataUsingEncoding(NSUTF8StringEncoding)!
        
        // when
        sut.setLargeUserImage(testUser, imageData: largeData)
        sut.setSmallUserImage(testUser, imageData: smallData)
        sut = UserImageLocalCache()
        
        // then
        XCTAssertEqual(sut.largeUserImage(testUser), largeData)
        XCTAssertEqual(sut.smallUserImage(testUser), smallData)
        
    }
    
}
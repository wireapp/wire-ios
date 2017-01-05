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
import ZMTesting
import ZMCDataModel
import WireRequestStrategy
@testable import WireShareEngine

class OperationLoopTests :  ZMTBaseTest {

    var databaseDirectory : URL! = nil
    var otrDirectory : URL! = nil
    var uiMoc   : NSManagedObjectContext! = nil
    var syncMoc : NSManagedObjectContext! = nil
    var sut : OperationLoop! = nil
    
    override func setUp() {
        super.setUp()
        
        let directoryURL = try! FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        databaseDirectory = directoryURL.appendingPathComponent("wire.database")
        otrDirectory = directoryURL.appendingPathComponent("otr")
        
        NSManagedObjectContext.setUseInMemoryStore(true)
        resetState()
        ZMPersistentCookieStorage.setDoNotPersistToKeychain(true)
        
        uiMoc = NSManagedObjectContext.createUserInterfaceContextWithStore(at: databaseDirectory)!
        uiMoc.add(self.dispatchGroup)
        syncMoc = NSManagedObjectContext.createSyncContextWithStore(at: databaseDirectory, keyStore: otrDirectory)!
        syncMoc.performGroupedBlockAndWait {
            self.syncMoc.add(self.dispatchGroup)
            self.syncMoc.saveOrRollback()
            
            self.syncMoc.zm_userInterface = self.uiMoc
        }
        uiMoc.zm_sync = syncMoc
        
        sut = OperationLoop(userContext: uiMoc, syncContext: syncMoc, callBackQueue: OperationQueue())
    }
    
    override func tearDown() {
        
        sut = nil
        
        resetState()
    
        uiMoc = nil
        syncMoc = nil
        
        super.tearDown()
    }
    
    func resetState() {
    
        if uiMoc != nil {
            uiMoc.globalManagedObjectContextObserver.tearDown()
        }
        
        if syncMoc != nil {
            syncMoc.performGroupedBlock {
                self.syncMoc.globalManagedObjectContextObserver.tearDown()
                self.syncMoc.userInfo.removeAllObjects()
            }
            if !waitForAllGroupsToBeEmpty(withTimeout: 0.5) {
                fatalError()
            }
        }
        NSManagedObjectContext.resetUserInterfaceContext()
        NSManagedObjectContext.resetSharedPersistentStoreCoordinator()
    }
}


extension OperationLoopTests {
    
    func testThatItMergesUiContextInSyncContext() {
        
        let userID = UUID()
        
        var syncUser : ZMUser! = nil
        syncMoc.performGroupedBlock { [unowned self] in
            syncUser = ZMUser(remoteID: userID, createIfNeeded: true, in: self.syncMoc)!
            self.syncMoc.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        XCTAssertNotNil(syncUser)
        XCTAssertNil(syncUser.name)
        
        uiMoc.performGroupedBlock {
            let uiUser = ZMUser(remoteID: userID, createIfNeeded: false, in: self.uiMoc)!
            uiUser.name = "Jean Claude YouKnowWho"
            XCTAssertNotNil(uiUser)
            self.uiMoc.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        XCTAssertEqual(syncUser.name, "Jean Claude YouKnowWho")
    }
    
    func testThatItMergesSyncContextInUIContext() {
        let userID = UUID()
        
        var syncUser : ZMUser! = nil
        syncMoc.performGroupedBlock { [unowned self] in
            syncUser = ZMUser(remoteID: userID, createIfNeeded: true, in: self.syncMoc)!
            self.syncMoc.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        XCTAssertNotNil(syncUser)
        XCTAssertNil(syncUser.name)
        
        var uiUser : ZMUser! = nil
        uiMoc.performGroupedBlock {
            uiUser = ZMUser(remoteID: userID, createIfNeeded: false, in: self.uiMoc)!
            XCTAssertNotNil(uiUser)
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        syncMoc.performGroupedBlockAndWait {
            syncUser.name = "Jean Claude YouKnowWho"
            self.syncMoc.saveOrRollback()
        }
        XCTAssertTrue(self.waitForAllGroupsToBeEmpty(withTimeout: 0.5))
        
        XCTAssertEqual(uiUser.name, syncUser.name)
    }
    
    func testThatItGeneratesTheExpectedRequest() {
        var count = 0
        sut.requestAvailableClosure = {
            count += 1
        }
        XCTAssertEqual(count, 0)
        
        sut.newRequestsAvailable()
        XCTAssertEqual(count, 1)
        
        sut.newRequestsAvailable()
        XCTAssertEqual(count, 2)
    }
}




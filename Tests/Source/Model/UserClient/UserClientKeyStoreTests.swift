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


import XCTest
@testable import ZMCDataModel
import Cryptobox


class UserClientKeysStoreTests: OtrBaseTest {
    
    var sut: UserClientKeysStore!
    
    static func cleanOTRFolder() {
        let fm = NSFileManager.defaultManager()
        for path in [UserClientKeysStore.legacyOtrDirectory.path!, UserClientKeysStore.otrDirectory.path!] {
            _ = try? fm.removeItemAtPath(path)
        }
    }
    
    override func setUp() {
        super.setUp()
        self.dynamicType.cleanOTRFolder()
        sut = UserClientKeysStore()
    }
    
    override func tearDown() {
        sut = nil
        self.dynamicType.cleanOTRFolder()
        super.tearDown()
    }
    
    func testThatTheOTRFolderHasBackupDisabled() {
        
        // given
        let otrURL = UserClientKeysStore.otrDirectory
        
        // then
        var rsrc: AnyObject?
        try! otrURL.getResourceValue(&rsrc, forKey: NSURLIsExcludedFromBackupKey)
        let number = rsrc as! NSNumber
        XCTAssertTrue(number == true)
        
    }
    
    func testThatItCanGenerateMoreKeys() {
        // when
        do {
            let (newKey, _, _) = try sut.generateMoreKeys(1)
            XCTAssertNotNil(newKey, "Should generate more keys")
            
        } catch let error as NSError {
            XCTAssertNil(error, "Should not return error while generating key")
            
        }
        
    }
    
    func testThatItWrapsKeysTo0WhenReachingTheMaximum() {
        // given
        let prekeyBatchSize : UInt = 50
        let startingPrekey = CBMaxPreKeyID - prekeyBatchSize - 1 // -1 is to generate at least 2 batches
        let maxIterations = 2
        
        var previousMaxKeyId : UInt = startingPrekey
        var iterations = 0
        
        // when
        while(true) {
            var newKey : [CBPreKey] = []
            var maxKey : UInt = 0
            var minKey : UInt = 0
            do {
                (newKey, minKey, maxKey) = try sut.generateMoreKeys(UInt(prekeyBatchSize), start: previousMaxKeyId)
            } catch let error as NSError {
                XCTAssertNil(error, "Should not return error while generating key: \(error)")
                return
            }
            
            // then
            iterations += 1
            if(iterations > maxIterations) {
                XCTFail("Too many keys are generated without wrapping: \(iterations) iterations, max key is \(maxKey)")
                return
            }
            
            XCTAssertNotNil(newKey, "Should generate more keys")
            if(minKey == 0) { // it wrapped!!
                XCTAssertGreaterThan(iterations, 1)
                // success!
                return
            }
            
            XCTAssertEqual(minKey, previousMaxKeyId) // is it the right starting point?
            
            previousMaxKeyId = maxKey
            if(maxKey > CBMaxPreKeyID) {
                XCTFail("Prekey \(maxKey) is too big")
                return
            }
            
        }
        
    }
    
    private static func createFakeOTRFolder() {
        try! NSFileManager.defaultManager().createDirectoryAtPath(UserClientKeysStore.legacyOtrDirectory.path!, withIntermediateDirectories: true, attributes: [:])
    }
    
    func testThatTheNonEmptyLegacyOTRFolderIsDetected() {
        
        // given
        self.dynamicType.createFakeOTRFolder()
        "foo".dataUsingEncoding(NSUTF8StringEncoding)!.writeToURL(UserClientKeysStore.legacyOtrDirectory.URLByAppendingPathComponent("dummy.txt"), atomically: true)
        
        // then
        XCTAssertTrue(UserClientKeysStore.needToMigrateIdentity)
    }
    
    func testThatANonEmptyLegacyOTRFolderIsDeleted() {
        
        // given
        self.dynamicType.createFakeOTRFolder()
        XCTAssertTrue(UserClientKeysStore.needToMigrateIdentity)
        
        // when
        UserClientKeysStore.removeOldIdentityFolder()
        
        // then
        XCTAssertFalse(UserClientKeysStore.needToMigrateIdentity)
    }
    
    func testThatItCanDeleteANonExistingOldIdentityFolder() {
        
        // when
        UserClientKeysStore.removeOldIdentityFolder()
        
        // then
        XCTAssertFalse(UserClientKeysStore.needToMigrateIdentity)
    }

    func testThatTheEmptyLegacyOTRFolderIsDetected() {
        
        // given
        self.dynamicType.createFakeOTRFolder()
        
        // then
        XCTAssertTrue(UserClientKeysStore.needToMigrateIdentity)
    }

    func testThatItMovesTheLegacyCryptobox() {
        
        // given
        self.dynamicType.cleanOTRFolder()

        self.dynamicType.createFakeOTRFolder()
        "foo".dataUsingEncoding(NSUTF8StringEncoding)!.writeToURL(UserClientKeysStore.legacyOtrDirectory.URLByAppendingPathComponent("dummy.txt"), atomically: true)

        // when
        let _ = UserClientKeysStore()
        
        // then
        let fooData = NSData(contentsOfURL: UserClientKeysStore.otrDirectory.URLByAppendingPathComponent("dummy.txt"))!
        let fooString = String(data: fooData, encoding: NSUTF8StringEncoding)!
        XCTAssertEqual(fooString, "foo")
        XCTAssertFalse(UserClientKeysStore.needToMigrateIdentity)
    }

    
    func testThatTheLegacyOTRFolderIsNotDetected() {
        
        // then
        XCTAssertFalse(UserClientKeysStore.needToMigrateIdentity)
    }
    
    func testThatTheOTRFolderHasTheRightPath() {
        
        // given
        let otrURL = try! NSFileManager.defaultManager().URLForDirectory(NSSearchPathDirectory.ApplicationSupportDirectory, inDomain: NSSearchPathDomainMask.UserDomainMask, appropriateForURL: nil, create: false).URLByAppendingPathComponent("otr")
        
        // then
        XCTAssertEqual(UserClientKeysStore.otrDirectory, otrURL)
    }
    
}

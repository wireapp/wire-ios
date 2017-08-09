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
@testable import WireDataModel
import WireCryptobox


class UserClientKeysStoreTests: OtrBaseTest {
    
    var sut: UserClientKeysStore!
    var accountID : UUID!
    var accountFolder: URL!
    
    override func setUp() {
        super.setUp()
        self.cleanOTRFolder()
        self.accountID = UUID()
        self.accountFolder = StorageStack.accountFolder(accountIdentifier: accountID, applicationContainer: OtrBaseTest.sharedContainerURL)
        self.sut = UserClientKeysStore(accountDirectory: accountFolder, applicationContainer: OtrBaseTest.sharedContainerURL)
    }
    
    override func tearDown() {
        self.sut = nil
        self.cleanOTRFolder()
        self.accountID = nil
        self.accountFolder = nil
        super.tearDown()
    }
    
    func cleanOTRFolder() {
        let fm = FileManager.default
        var paths = UserClientKeysStore.legacyDirectories(applicationContainer: OtrBaseTest.sharedContainerURL).map{$0.path}
        if let accountID = accountID {
            paths.append(OtrBaseTest.otrDirectoryURL(accountIdentifier: accountID).path)
        }
        paths.forEach { try? fm.removeItem(atPath: $0) }
    }
    
    func testThatTheOTRFolderHasBackupDisabled() {
        // when
        guard let values = try? self.sut.cryptoboxDirectory.resourceValues(forKeys: Set(arrayLiteral: URLResourceKey.isExcludedFromBackupKey)) else {return XCTFail()}

        // then
        XCTAssertTrue(values.isExcludedFromBackup!)
    }
    
    func testThatItCanGenerateMoreKeys() {
        // when
        do {
            let newKeys = try sut.generateMoreKeys(1, start: 0)
            XCTAssertNotEqual(newKeys.count, 0, "Should generate more keys")
            
        } catch let error as NSError {
            XCTAssertNil(error, "Should not return error while generating key")
            
        }
    }
    
    func testThatItWrapsKeysTo0WhenReachingTheMaximum() {
        // given
        let maxPreKey : UInt16 = UserClientKeysStore.MaxPreKeyID
        print(maxPreKey)
        let prekeyBatchSize : UInt16 = 50
        let startingPrekey = maxPreKey - prekeyBatchSize - 1 // -1 is to generate at least 2 batches
        let maxIterations = 2
        
        var previousMaxKeyId : UInt16 = startingPrekey
        var iterations = 0
        
        // when
        while (true) {
            var newKeys : [(id: UInt16, prekey: String)]!
            var maxKey : UInt16!
            var minKey : UInt16!
            do {
                newKeys = try sut.generateMoreKeys(50, start: previousMaxKeyId)
                maxKey = newKeys.last?.id ?? 0
                minKey = newKeys.first?.id ?? 0
            } catch let error as NSError {
                XCTAssertNil(error, "Should not return error while generating key: \(error)")
                return
            }
            
            // then
            iterations += 1
            if (iterations > maxIterations) {
                XCTFail("Too many keys are generated without wrapping: \(iterations) iterations, max key is \(maxKey)")
                return
            }
            
            XCTAssertGreaterThan(newKeys.count, 0, "Should generate more keys")
            if (minKey == 0) { // it wrapped!!
                XCTAssertGreaterThan(iterations, 1)
                // success!
                return
            }
            
            XCTAssertEqual(minKey, previousMaxKeyId) // is it the right starting point?
            
            previousMaxKeyId = maxKey
            if (maxKey > UserClientKeysStore.MaxPreKeyID) {
                XCTFail("Prekey \(maxKey) is too big")
                return
            }
            
        }
        
    }
    
    fileprivate func createFakeOTRFolder() {
        try! FileManager.default.createDirectory(atPath: OtrBaseTest.legacyOtrDirectory.path, withIntermediateDirectories: true, attributes: [:])
    }

    func testThatItMovesTheLegacyCryptoboxToTheGivenURL() {
        
        // given
        self.sut = nil
        self.cleanOTRFolder()

        self.createFakeOTRFolder()
        try! "foo".data(using: String.Encoding.utf8)!.write(to: OtrBaseTest.legacyOtrDirectory.appendingPathComponent("dummy.txt"), options: Data.WritingOptions.atomic)
        
        // when
        let _ = UserClientKeysStore(accountDirectory: self.accountFolder, applicationContainer: OtrBaseTest.sharedContainerURL)
        
        // then
        let fooData = try! Data(contentsOf: OtrBaseTest.otrDirectoryURL(accountIdentifier: accountID).appendingPathComponent("dummy.txt"))
        let fooString = String(data: fooData, encoding: String.Encoding.utf8)!
        XCTAssertEqual(fooString, "foo")
        XCTAssertFalse(UserClientKeysStore.needToMigrateIdentity(applicationContainer: OtrBaseTest.sharedContainerURL))
    }
    
    func testThatItMovesTheOTRFolderToTheGivenURL() {
        // given
        self.sut = nil
        self.cleanOTRFolder()

        try! FileManager.default.createDirectory(at: OtrBaseTest.otrDirectoryURL(accountIdentifier:accountID), withIntermediateDirectories: true, attributes: [:])
        try! "foo".data(using: String.Encoding.utf8)!.write(to: OtrBaseTest.otrDirectoryURL(accountIdentifier:accountID).appendingPathComponent("dummy.txt"), options: Data.WritingOptions.atomic)
        
        // when
        let accountFolder = StorageStack.accountFolder(accountIdentifier: self.accountID, applicationContainer: OtrBaseTest.sharedContainerURL)
        let _ = UserClientKeysStore(accountDirectory: accountFolder, applicationContainer: OtrBaseTest.sharedContainerURL)
        
        // then
        let fooData = try! Data(contentsOf: OtrBaseTest.otrDirectoryURL(accountIdentifier: accountID).appendingPathComponent("dummy.txt"))
        let fooString = String(data: fooData, encoding: String.Encoding.utf8)!
        XCTAssertEqual(fooString, "foo")
        XCTAssertFalse(UserClientKeysStore.needToMigrateIdentity(applicationContainer: OtrBaseTest.sharedContainerURL))

    }
}

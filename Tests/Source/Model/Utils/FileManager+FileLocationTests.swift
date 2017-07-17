//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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


class FileManager_StoreLocationTests : XCTestCase {
    
    func testThatTheStoreLocationIsTheExpected() {
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let storeURL = url.appendingStorePath()
        
        // then
        var components = storeURL.pathComponents
        
        if !components.isEmpty {
            let lastComp = components.removeLast()
            XCTAssertEqual(lastComp, "store.wiredatabase")
        } else {
            XCTFail("WARNING!! Changing the method `appendingStorePath` might break migration. See PersistentStoreRelocator")
        }
            
        if !components.isEmpty {
            let lastComp = components.removeLast()
            XCTAssertEqual(lastComp, Bundle.main.bundleIdentifier)
        } else {
            XCTFail("WARNING!! Changing the method `appendingStorePath` might break migration. See PersistentStoreRelocator")
        }
        
        if !components.isEmpty {
            let lastComp = components.removeLast()
            XCTAssertEqual(lastComp, "Caches")
        } else {
            XCTFail("WARNING!! Changing the method `appendingStorePath` might break migration. See PersistentStoreRelocator")
        }
    }
    
    func testThatItAppendsTheAccountIDIfSpecifiedForTheCurrentStoreLocation() {
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let accountId = UUID()
        
        // when
        let storeURL = FileManager.currentStoreURLForAccount(with: accountId, in: url)
        
        // then
        var components = storeURL.pathComponents

        guard !components.isEmpty else { return XCTFail() }
        let dataBaseComp = components.removeLast()
        XCTAssertEqual(dataBaseComp, "store.wiredatabase")
        
        guard !components.isEmpty else { return XCTFail() }
        let bundleComp = components.removeLast()
        XCTAssertEqual(bundleComp, Bundle.main.bundleIdentifier)
        
        guard !components.isEmpty else { return XCTFail() }
        let accountIdComp = components.removeLast()
        XCTAssertEqual(accountIdComp, accountId.uuidString)

        XCTAssertEqual(components, url.pathComponents)
    }
    
    func testThatItIgnoresIfNotSpecifiedForTheCurrentStoreLocation() {
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let storeURL = FileManager.currentStoreURLForAccount(with: nil, in: url)
        
        // then
        var components = storeURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let dataBaseComp = components.removeLast()
        XCTAssertEqual(dataBaseComp, "store.wiredatabase")
        
        guard !components.isEmpty else { return XCTFail() }
        let bundleComp = components.removeLast()
        XCTAssertEqual(bundleComp, Bundle.main.bundleIdentifier)
        
        XCTAssertEqual(components, url.pathComponents)
    }
}

class FileManager_CryptoboxTests : XCTestCase {
    
    func testThatItReturnsTheCryptoboxPath_withAccountId(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let accountId = UUID()
        
        // when
        let storeURL = FileManager.keyStoreURLForAccount(with: accountId, in: url, createParentIfNeeded: false)
        
        // then
        var components = storeURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let otrComp = components.removeLast()
        XCTAssertEqual(otrComp, FileManager.keyStoreFolderPrefix)

        guard !components.isEmpty else { return XCTFail() }
        let accountIdComp = components.removeLast()
        XCTAssertEqual(accountIdComp, accountId.uuidString)
        
        XCTAssertEqual(components, url.pathComponents)
    }
    
    func testThatItReturnsTheCryptoboxPath_withoutAccountId(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let storeURL = FileManager.keyStoreURLForAccount(with: nil, in: url, createParentIfNeeded: false)
        
        // then
        var components = storeURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let otrComp = components.removeLast()
        XCTAssertEqual(otrComp, FileManager.keyStoreFolderPrefix)
        
        XCTAssertEqual(components, url.pathComponents)
    }
    
    func testThatItCreatesTheParentDirectoryIfNeededAndExcludesItFromBackup(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let storeURL = FileManager.keyStoreURLForAccount(with: nil, in: url, createParentIfNeeded: true)
        
        // then
        let parentURL = storeURL.deletingLastPathComponent()
        var isDirectory : ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: parentURL.path, isDirectory:&isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
        XCTAssertTrue(parentURL.isExcludedFromBackup)
        
        try! FileManager.default.removeItem(at:parentURL)
    }
}


class FileManager_CacheTests : XCTestCase {

    func testThatItReturnsTheCachesDirectory_WithAccountId(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let accountId = UUID()
        
        // when
        let cachesURL = FileManager.default.cachesURLForAccount(with: accountId, in: url)
        
        // then
        var components = cachesURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let accountIdComp = components.removeLast()
        XCTAssertEqual(accountIdComp, accountId.uuidString)
        
        guard !components.isEmpty else { return XCTFail() }
        let cachesComp = components.removeLast()
        XCTAssertEqual(cachesComp, "Caches")
        
        guard !components.isEmpty else { return XCTFail() }
        let libraryComp = components.removeLast()
        XCTAssertEqual(libraryComp, "Library")
        
        XCTAssertEqual(components, url.pathComponents)
    }
    
    
    func testThatItReturnsTheCachesDirectory_WithoutAccountId(){
        // given
        let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        
        // when
        let cachesURL = FileManager.default.cachesURLForAccount(with: nil, in: url)
        
        // then
        var components = cachesURL.pathComponents
        
        guard !components.isEmpty else { return XCTFail() }
        let cachesComp = components.removeLast()
        XCTAssertEqual(cachesComp, "Caches")
        
        guard !components.isEmpty else { return XCTFail() }
        let libraryComp = components.removeLast()
        XCTAssertEqual(libraryComp, "Library")
        
        XCTAssertEqual(components, url.pathComponents)
    }
}

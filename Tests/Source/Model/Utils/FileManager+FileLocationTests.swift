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


class URL_StoreLocationTests : XCTestCase {
    
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
}


class FileManager_FileLocationTests : XCTestCase {

    func testThatItReturnsTheLocationForTheCaches_WithoutAccountIdentifier(){
        // when
//        let url = FileManager.cachesURL(forAppGroupIdentifier: <#T##String#>, accountIdentifier: <#T##UUID?#>)
        // then
    }
    
    
    func testThatItReturnsTheLocationForTheCaches_WithAccountIdentifier(){
        
    }
}

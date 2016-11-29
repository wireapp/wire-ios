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

class PersistentStoreRelocatorTests: DatabaseBaseTest {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testThatItFindsPreviousStoreInCachesDirectory() {
        // given
        createDatabase(in: .cachesDirectory)
        
        // new store is located in documents directory
        let sut = PersistentStoreRelocator(storeLocation: PersistentStoreRelocator.storeURL(in: .documentDirectory)!)
        
        // then
        XCTAssertEqual(sut.previousStoreLocation, PersistentStoreRelocator.storeURL(in: .cachesDirectory)!)
    }
    
    func testThatItFindsPreviousStoreInApplicationSupportDirectory() {
        // given
        createDatabase(in: .applicationSupportDirectory)
        
        // new store is located in documents directory
        let sut = PersistentStoreRelocator(storeLocation: PersistentStoreRelocator.storeURL(in: .documentDirectory)!)
        
        // then
        XCTAssertEqual(sut.previousStoreLocation, PersistentStoreRelocator.storeURL(in: .applicationSupportDirectory)!)
    }
    
    func testThatIsNecessaryToRelocateStoreIfItsLocatedInAPreviousLocation() {
        // given
        createDatabase(in: .cachesDirectory)
        
        // new store is located in documents directory
        let sut = PersistentStoreRelocator(storeLocation: PersistentStoreRelocator.storeURL(in: .documentDirectory)!)
        
        // then
        XCTAssertTrue(sut.storeNeedsToBeRelocated)
    }
    
    func testThatIsNecessaryToRelocateStoreIfItsLocatedInAPreviousLocation_and_newStoreAlreadyExists() {
        // given
        let cachesStoreURL = PersistentStoreRelocator.storeURL(in: .cachesDirectory)!
        
        createDatabase(in: .documentDirectory)
        createDirectoryForStore(at: cachesStoreURL)
        createExternalSupportFileForDatabase(at: cachesStoreURL)
        
        // new store is located in documents directory
        let sut = PersistentStoreRelocator(storeLocation: PersistentStoreRelocator.storeURL(in: .documentDirectory)!)
        
        // then
        XCTAssertTrue(sut.storeNeedsToBeRelocated)
    }
    
    func testThatIsNotNecessaryToRelocateStoreIfNotPreviousStoreExists() {
        // given new store is located in documents directory
        let sut = PersistentStoreRelocator(storeLocation: PersistentStoreRelocator.storeURL(in: .documentDirectory)!)
        
        // then
        XCTAssertFalse(sut.storeNeedsToBeRelocated)
    }
    
    func testThatIsNotNecessaryToRelocateStoreIfItsLocatedInAPreviousLocation_and_newStoreIsTheSame() {
        // given
        createDatabase(in: .cachesDirectory)
        
        // new store is also located in caches directory
        let sut = PersistentStoreRelocator(storeLocation: PersistentStoreRelocator.storeURL(in: .cachesDirectory)!)
        
        // then
        XCTAssertFalse(sut.storeNeedsToBeRelocated)
    }
    
}

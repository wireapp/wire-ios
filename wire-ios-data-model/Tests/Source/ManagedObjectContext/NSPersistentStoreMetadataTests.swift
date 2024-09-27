//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

// MARK: - NSPersistentStoreMetadataTests

class NSPersistentStoreMetadataTests: ZMBaseManagedObjectTest {
    override var shouldUseInMemoryStore: Bool {
        false
    }

    func forceSave() {
        // I need to insert or modify an entity, or core data will not save
        uiMOC.forceSaveOrRollback()
    }
}

extension NSPersistentStoreMetadataTests {
    func testThatItStoresMetadataInMemory() {
        // GIVEN
        let data = "foo"
        let key = "boo"

        // WHEN
        uiMOC.setPersistentStoreMetadata(data, key: key)

        // THEN
        XCTAssertEqual(data, uiMOC.persistentStoreMetadata(forKey: key) as? String)
    }

    func testThatItDeletesMetadataFromMemory() {
        // GIVEN
        let data = "foo"
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)

        // WHEN
        uiMOC.setPersistentStoreMetadata(nil as String?, key: key)

        // THEN
        XCTAssertEqual(nil, uiMOC.persistentStoreMetadata(forKey: key) as? String)
    }

    func testThatMetadataAreNotPersisted() {
        // GIVEN
        let data = "foo"
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)

        // WHEN
        resetUIandSyncContextsAndResetPersistentStore(false)

        // THEN
        XCTAssertEqual(nil, uiMOC.persistentStoreMetadata(forKey: key) as? String)
    }

    func testThatItPersistsMetadataWhenSaving() {
        // GIVEN
        let data = "foo"
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)

        // WHEN
        forceSave()
        resetUIandSyncContextsAndResetPersistentStore(false)

        // THEN
        XCTAssertEqual(data, uiMOC.persistentStoreMetadata(forKey: key) as? String)
    }

    func testThatItDiscardsMetadataWhenRollingBack() {
        // GIVEN
        let data = "foo"
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)

        // WHEN
        uiMOC.enableForceRollback()
        forceSave()

        // THEN
        XCTAssertEqual(nil, uiMOC.persistentStoreMetadata(forKey: key) as? String)

        // AFTER
        uiMOC.disableForceRollback()
    }

    func testThatItDeletesAlreadySetMetadataInMemory() {
        // GIVEN
        let data = "foo"
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)
        forceSave()

        // WHEN
        uiMOC.setPersistentStoreMetadata(nil as String?, key: key)

        // THEN
        XCTAssertEqual(nil, uiMOC.persistentStoreMetadata(forKey: key) as? String)
    }

    func testThatItDiscardsDeletesAlreadySetMetadataInMemory() {
        // GIVEN
        let data = "foo"
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)
        forceSave()
        uiMOC.setPersistentStoreMetadata(nil as String?, key: key)

        // WHEN
        resetUIandSyncContextsAndResetPersistentStore(false)

        // THEN
        XCTAssertEqual(data, uiMOC.persistentStoreMetadata(forKey: key) as? String)
    }

    func testThatItDeletesAlreadySetMetadataFromStore() {
        // GIVEN
        let data = "foo"
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)
        forceSave()
        uiMOC.setPersistentStoreMetadata(nil as String?, key: key)

        // WHEN
        forceSave()
        resetUIandSyncContextsAndResetPersistentStore(false)

        // THEN
        XCTAssertEqual(nil, uiMOC.persistentStoreMetadata(forKey: key) as? String)
    }
}

// MARK: - What can be saved

extension NSPersistentStoreMetadataTests {
    func checkThatItCanSave<T: Equatable & SwiftPersistableInMetadata>(
        data: T,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // GIVEN
        let key = "boo"
        uiMOC.setPersistentStoreMetadata(data, key: key)

        // WHEN
        forceSave()
        resetUIandSyncContextsAndResetPersistentStore(false)

        // THEN
        XCTAssertEqual(data, uiMOC.persistentStoreMetadata(forKey: key) as? T, file: file, line: line)
    }

    func testThatItCanStoreStrings() {
        checkThatItCanSave(data: "Foo")
    }

    func testThatItCanStoreDates() {
        checkThatItCanSave(data: Date())
    }

    func testThatItCanStoreData() {
        checkThatItCanSave(data: Data([21, 3]))
    }

    func testThatItCanStoreArrayOfString() {
        // GIVEN
        let key = "boo"
        let data = ["a", "z"]
        uiMOC.setPersistentStoreMetadata(array: data, key: key)

        // WHEN
        forceSave()
        resetUIandSyncContextsAndResetPersistentStore(false)

        // THEN
        for i in 0 ..< data.count {
            XCTAssertEqual(data[i], (uiMOC.persistentStoreMetadata(forKey: key) as? [String])?[i])
        }
    }
}

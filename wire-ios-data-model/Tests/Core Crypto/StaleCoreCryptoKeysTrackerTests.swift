//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

import WireFoundationSupport
import XCTest
@testable import WireDataModel

final class StaleCoreCryptoKeysTrackerTests: XCTestCase {

    private var mockDefaults: UserDefaultsProtocolMock!
    private var sut: StaleCoreCryptoKeysTracker!
    private var storage: [String: Any]!

    override func setUp() {
        super.setUp()
        storage = [:]
        mockDefaults = UserDefaultsProtocolMock()
        mockDefaults.setValueAnyForKeyDefaultNameStringVoidClosure = { [weak self] value, key in
            self?.storage[key] = value
        }
        mockDefaults.stringArrayForKeyDefaultNameStringStringClosure = { [weak self] key in
            return self?.storage[key] as? [String]
        }
        mockDefaults.removeObjectForKeyDefaultNameStringVoidClosure = { [weak self] key in
            self?.storage.removeValue(forKey: key)
        }

        sut = StaleCoreCryptoKeysTracker(defaults: mockDefaults)
    }

    override func tearDown() {
        sut = nil
        mockDefaults = nil
        super.tearDown()
    }

    // MARK: addKey

    func test_itStoresId() {
        // GIVEN
        let id = UUID()

        // WHEN
        sut.addKey(id: id)

        // THEN
        let stored = mockDefaults.stringArray(forKey: sut.key)
        XCTAssertEqual(stored, [id.uuidString])
    }

    func test_itDoesNotAddDuplicates() {
        // GIVEN
        let id = UUID()

        // WHEN
        sut.addKey(id: id)
        sut.addKey(id: id)

        // THEN
        let stored = mockDefaults.stringArray(forKey: sut.key)
        XCTAssertEqual(stored?.count, 1)
    }

    // MARK: getAll

    func test_itReturnsEmptyArray_WhenNoKeys() {
        // WHEN
        let ids = sut.getAll()

        // THEN
        XCTAssertTrue(ids.isEmpty)
    }

    func test_itReturnsAllStoredKeys() {
        // GIVEN
        let id1 = UUID()
        let id2 = UUID()
        mockDefaults.set([id1.uuidString, id2.uuidString], forKey: sut.key)

        // WHEN
        let ids = sut.getAll()

        // THEN
        XCTAssertEqual(Set(ids), Set([id1, id2]))
    }

    // MARK: removeKey

    func test_itRemovesTheKey() {
        // GIVEN
        let id1 = UUID()
        let id2 = UUID()
        mockDefaults.set([id1.uuidString, id2.uuidString], forKey: sut.key)

        // WHEN
        sut.removeKey(id: id1)

        // THEN
        let remaining = sut.getAll()
        XCTAssertEqual(remaining, [id2])
    }

    // MARK: clear

    func test_itRemovesAllKeys() {
        // GIVEN
        sut.addKey(id: UUID())
        sut.addKey(id: UUID())

        // WHEN
        sut.clear()

        // THEN
        XCTAssertTrue(sut.getAll().isEmpty)
        XCTAssertNil(mockDefaults.stringArray(forKey: sut.key))
    }
}

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

import Foundation
import XCTest

@testable public import WireFoundation

final class PrivateUserDefaultsTests: XCTestCase {
    var sut: PrivateUserDefaults<String>!
    var mockUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(
            suiteName: Scaffolding.defaultsTestSuiteName
        )

        sut = PrivateUserDefaults(
            userID: Scaffolding.userID,
            storage: mockUserDefaults
        )
    }

    override func tearDown() {
        mockUserDefaults.removePersistentDomain(
            forName: Scaffolding.defaultsTestSuiteName
        )
        mockUserDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_setUUID() throws {
        // Given
        let uuid = UUID()

        // When
        sut.setUUID(uuid, forKey: Scaffolding.key)

        // Then
        let scopedKey = "\(Scaffolding.userID.uuidString)_\(Scaffolding.key)"
        let storedValue = mockUserDefaults.string(forKey: scopedKey)
        XCTAssertEqual(storedValue, uuid.uuidString)

        // When
        sut.setUUID(nil, forKey: Scaffolding.key)

        // Then
        XCTAssertNil(mockUserDefaults.string(forKey: scopedKey))
    }

    func test_getUUID() throws {
        // Given
        let scopedKey = "\(Scaffolding.userID.uuidString)_\(Scaffolding.key)"
        let uuid = UUID()

        // Then
        XCTAssertNil(sut.getUUID(forKey: Scaffolding.key))

        // When
        mockUserDefaults.set(uuid.uuidString, forKey: scopedKey)

        // Then
        XCTAssertEqual(sut.getUUID(forKey: Scaffolding.key), uuid)
    }

    func test_setBool_withAdditionalScope() throws {
        let extraScope = "extra-scope"
        XCTAssertFalse(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))

        sut.set(true, forKey: Scaffolding.key, additionalScope: extraScope)
        XCTAssertTrue(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))

        sut.set(false, forKey: Scaffolding.key, additionalScope: extraScope)
        XCTAssertFalse(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))

        sut.set(true, forKey: Scaffolding.key, additionalScope: extraScope)
        XCTAssertTrue(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))

        sut.removeObject(forKey: Scaffolding.key, additionalScope: extraScope)
        XCTAssertFalse(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))
    }

    func test_doesNotAffectValuesInSameAdditionalScope() throws {
        let extraScope = "extra-scope"
        XCTAssertFalse(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))
        XCTAssertFalse(sut.bool(forKey: Scaffolding.key2, additionalScope: extraScope))

        sut.set(true, forKey: Scaffolding.key, additionalScope: extraScope)
        XCTAssertTrue(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))

        sut.set(true, forKey: Scaffolding.key2, additionalScope: extraScope)
        XCTAssertTrue(sut.bool(forKey: Scaffolding.key2, additionalScope: extraScope))

        sut.removeObject(forKey: Scaffolding.key2, additionalScope: extraScope)
        XCTAssertFalse(sut.bool(forKey: Scaffolding.key2, additionalScope: extraScope))
        XCTAssertTrue(sut.bool(forKey: Scaffolding.key, additionalScope: extraScope))
    }

    // MARK: Removing all

    func test_removeAll() throws {
        // Given
        let scopedKey = "\(Scaffolding.userID.uuidString)_B"
        let storage = UserDefaults.standard
        storage.set("A", forKey: "A-key")
        storage.set("B", forKey: scopedKey)

        // When
        PrivateUserDefaults.removeAll(forUserID: Scaffolding.userID, in: .standard)

        // Then
        XCTAssertEqual(storage.value(forKey: "A-key") as? String, "A")
        XCTAssertNil(storage.value(forKey: scopedKey))
    }

    private enum Scaffolding {
        static let userID = UUID()
        static let key = "foo"
        static let key2 = "fooBar"
        static let defaultsTestSuiteName = UUID().uuidString
    }
}

extension String: DefaultsKey {

    public var rawValue: String {
        self
    }

}

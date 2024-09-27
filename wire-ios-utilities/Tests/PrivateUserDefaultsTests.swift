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
@testable import WireUtilities

// MARK: - PrivateUserDefaultsTests

final class PrivateUserDefaultsTests: XCTestCase {
    var sut: PrivateUserDefaults<String>!
    var userID: UUID!
    let key = "foo"

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        userID = UUID.create()
        sut = PrivateUserDefaults(userID: userID, storage: .standard)
    }

    override func tearDown() {
        sut.setUUID(nil, forKey: key)
        sut = nil
        userID = nil
        super.tearDown()
    }

    // MARK: - Get / set id

    func test_setUUID() throws {
        // Given
        let uuid = UUID()

        // When
        sut.setUUID(uuid, forKey: key)

        // Then
        let scopedKey = "\(userID.uuidString)_\(key)"
        let storedValue = UserDefaults.standard.string(forKey: scopedKey)
        XCTAssertEqual(storedValue, uuid.uuidString)

        // When
        sut.setUUID(nil, forKey: key)

        // Then
        XCTAssertNil(UserDefaults.standard.string(forKey: scopedKey))
    }

    func test_getUUID() throws {
        // Given
        let scopedKey = "\(userID.uuidString)_\(key)"
        let uuid = UUID()

        // Then
        XCTAssertNil(sut.getUUID(forKey: key))

        // When
        UserDefaults.standard.set(uuid.uuidString, forKey: scopedKey)

        // Then
        XCTAssertEqual(sut.getUUID(forKey: key), uuid)
    }

    // MARK: Removing all

    func test_removeAll() throws {
        // Given
        let scopedKey = "\(userID.uuidString)_B"
        let storage = UserDefaults.standard
        storage.set("A", forKey: "A-key")
        storage.set("B", forKey: scopedKey)

        // When
        PrivateUserDefaults.removeAll(forUserID: userID, in: .standard)

        // Then
        XCTAssertEqual(storage.value(forKey: "A-key") as? String, "A")
        XCTAssertNil(storage.value(forKey: scopedKey))
    }
}

// MARK: - String + DefaultsKey

extension String: DefaultsKey {
    public var rawValue: String {
        self
    }
}

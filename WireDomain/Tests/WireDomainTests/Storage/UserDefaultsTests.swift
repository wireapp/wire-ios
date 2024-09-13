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
@testable import WireDomain
import XCTest

final class PrivateUserDefaultsTests: XCTestCase {

    enum Key: String {
        case foo
    }

    var sut: UserDefault<Key, String?>!
    var userID: UUID!
    let key = Key.foo

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        userID = UUID()
        sut = UserDefault(key: key, userID: userID)
    }

    override func tearDown() {
        sut = nil
        userID = nil
        super.tearDown()
    }

    // MARK: - Get / set id

    func test_set_UUID_In_Defaults() throws {
        // Given
        let uuid = UUID()

        // When
        sut.wrappedValue = uuid.uuidString

        // Then
        let scopedKey = "\(userID.uuidString)_\(key)"
        let storedValue = UserDefaults.standard.string(forKey: scopedKey)
        XCTAssertEqual(storedValue, uuid.uuidString)

        // When
        sut.wrappedValue = nil

        // Then
        XCTAssertNil(UserDefaults.standard.string(forKey: scopedKey))
    }

    func test_retrieve_UUID_From_Defaults() throws {
        // Given
        let scopedKey = "\(userID.uuidString)_\(key.rawValue)"
        let uuid = UUID()

        // Then
        XCTAssertNil(sut.wrappedValue)

        // When
        UserDefaults.standard.set(uuid.uuidString, forKey: scopedKey)

        // Then
        XCTAssertEqual(sut.wrappedValue, uuid.uuidString)
    }

    // MARK: Removing all

    func test_remove_All_From_Defaults() throws {
        // Given
        let scopedKey = "\(userID.uuidString)_B"
        let storage = UserDefaults.standard
        storage.set("A", forKey: "A-key")
        storage.set("B", forKey: scopedKey)

        // When

        UserDefaults.removeAll(forUserID: userID, in: .standard)

        // Then
        XCTAssertEqual(storage.value(forKey: "A-key") as? String, "A")
        XCTAssertNil(storage.value(forKey: scopedKey))
    }
}

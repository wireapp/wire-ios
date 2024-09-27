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
@testable import WireDataModel

final class LastEventIDRepositoryTests: XCTestCase {
    var sut: LastEventIDRepository!
    var userID: UUID!
    var userDefaults: UserDefaults!

    // MARK: - Helper

    var userDefaultsKey: String {
        "\(userID.uuidString)_lastEventID"
    }

    var getStoredValue: String? {
        userDefaults.string(forKey: userDefaultsKey)
    }

    override func setUp() {
        super.setUp()

        userID = UUID.create()
        userDefaults = .temporary()
        sut = LastEventIDRepository(userID: userID, sharedUserDefaults: userDefaults)
    }

    override func tearDown() {
        sut = nil
        userID = nil
        userDefaults = nil

        super.tearDown()
    }

    func storeValue(_ string: String) {
        userDefaults.set(string, forKey: userDefaultsKey)
    }

    // MARK: - Store

    func test_StoreLastEventID() throws {
        // Given
        let eventID = UUID()
        XCTAssertNil(getStoredValue)

        // When
        sut.storeLastEventID(eventID)

        // Then
        XCTAssertEqual(getStoredValue, eventID.uuidString)
    }

    // MARK: - Fetch

    func test_FetchLastEventID() throws {
        // Given
        let eventID = UUID()
        storeValue(eventID.uuidString)

        // Then
        XCTAssertEqual(sut.fetchLastEventID(), eventID)
    }
}

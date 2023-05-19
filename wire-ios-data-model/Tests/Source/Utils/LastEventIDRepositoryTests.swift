//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

    // MARK: - Life cycle

    override func setUp() {
        super.setUp()
        userID = UUID.create()
        sut = LastEventIDRepository(userID: userID, userDefaults: .standard)
    }

    override func tearDown() {
        sut.storeLastEventID(nil)
        sut = nil
        userID = nil
        super.tearDown()
    }

    // MARK: - Fetch and store

    func test_fetchAndStoreLastEventID() throws {
        // Given
        let eventID = UUID()
        XCTAssertNil(sut.fetchLastEventID())

        // When
        sut.storeLastEventID(eventID)

        // Then
        XCTAssertEqual(sut.fetchLastEventID(), eventID)

        // When
        sut.storeLastEventID(nil)

        // Then
        XCTAssertNil(sut.fetchLastEventID())
    }

}

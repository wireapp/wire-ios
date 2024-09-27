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

import XCTest
@testable import WireSystem

final class TimePointTests: XCTestCase {
    func testThatATimePointDoesNotWarnTooEarly() {
        // Given
        let tp = TimePoint(interval: 1000)

        // Then
        XCTAssertFalse(tp.warnIfLongerThanInterval())
    }

    func testThatATimePointWarnsIfTooMuchTimeHasPassed() {
        // Given
        let tp = TimePoint(interval: 0.01)

        // When
        let waitExpectation = XCTestExpectation()
        waitExpectation.isInverted = true
        wait(for: [waitExpectation], timeout: 0.1)

        // Then
        XCTAssertTrue(tp.warnIfLongerThanInterval())
    }
}

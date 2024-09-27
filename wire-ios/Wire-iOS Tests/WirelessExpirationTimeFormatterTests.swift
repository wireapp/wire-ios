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
@testable import Wire

class WirelessExpirationTimeFormatterTests: XCTestCase {
    // MARK: Internal

    func testExpirationTimeFormatting_LargerThan2Hours() {
        assert(remainingTime: 12000, expected: "4h left")
    }

    func testExpirationTimeFormatting_2Hours() {
        assert(remainingTime: 7200, expected: "3h left")
    }

    func testExpirationTimeFormatting_91Minutes() {
        assert(remainingTime: 5460, expected: "2h left")
    }

    func testExpirationTimeFormatting_90Minutes() {
        assert(remainingTime: 5400, expected: "1.5h left")
    }

    func testExpirationTimeFormatting_89Minutes() {
        assert(remainingTime: 5340, expected: "1.5h left")
    }

    func testExpirationTimeFormatting_61Minutes() {
        assert(remainingTime: 3660, expected: "1.5h left")
    }

    func testExpirationTimeFormatting_60Minutes() {
        assert(remainingTime: 3600, expected: "1h left")
    }

    func testExpirationTimeFormatting_59Minutes() {
        assert(remainingTime: 3540, expected: "1h left")
    }

    func testExpirationTimeFormatting_46Minutes() {
        assert(remainingTime: 2760, expected: "1h left")
    }

    func testExpirationTimeFormatting_45Minutes() {
        assert(remainingTime: 2700, expected: "1h left")
    }

    func testExpirationTimeFormatting_44Minutes() {
        assert(remainingTime: 2640, expected: "Less than 45m left")
    }

    func testExpirationTimeFormatting_31Minutes() {
        assert(remainingTime: 1860, expected: "Less than 45m left")
    }

    func testExpirationTimeFormatting_30Minutes() {
        assert(remainingTime: 1800, expected: "Less than 45m left")
    }

    func testExpirationTimeFormatting_29Minutes() {
        assert(remainingTime: 1740, expected: "Less than 30m left")
    }

    func testExpirationTimeFormatting_16Minutes() {
        assert(remainingTime: 960, expected: "Less than 30m left")
    }

    func testExpirationTimeFormatting_15Minutes() {
        assert(remainingTime: 900, expected: "Less than 30m left")
    }

    func testExpirationTimeFormatting_14Minutes() {
        assert(remainingTime: 840, expected: "Less than 15m left")
    }

    func testExpirationTimeFormatting_5Minutes() {
        assert(remainingTime: 300, expected: "Less than 15m left")
    }

    func testExpirationTimeFormatting_1Minute() {
        assert(remainingTime: 60, expected: "Less than 15m left")
    }

    func testExpirationTimeFormatting_0Minutes() {
        assert(remainingTime: 0, expected: nil)
    }

    func testExpirationTimeFormatting_NegativeValue() {
        assert(remainingTime: -10, expected: nil)
    }

    // MARK: Private

    // MARK: - Helper

    private func assert(
        remainingTime: TimeInterval,
        expected: String?,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let result = WirelessExpirationTimeFormatter.shared.string(for: remainingTime)
        XCTAssertEqual(result, expected, file: file, line: line)
    }
}

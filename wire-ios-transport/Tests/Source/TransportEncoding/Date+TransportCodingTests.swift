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

final class Date_TransportCodingTests: XCTestCase {

    func testThatTransportDatesCanBeParsed_0() throws {
        let date = try XCTUnwrap(Date(transportString: "2014-03-14T16:47:37.573Z"))
        let components = Calendar.current.dateComponents(in: gmt, from: date)
        XCTAssertEqual(components.timeZone, gmt)
        XCTAssertEqual(components.year, 2014)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 14)
        XCTAssertEqual(components.hour, 16)
        XCTAssertEqual(components.minute, 47)
        XCTAssertEqual(components.second, 37)
        XCTAssertEqual(components.nanosecond.map { (Float($0) / 1_000_000).rounded() }, 573)
    }

    func testThatTransportDatesCanBeParsed_1() throws {
        let date = try XCTUnwrap(Date(transportString: "2014-04-15T08:45:04.502Z"))
        let components = Calendar.current.dateComponents(in: gmt, from: date)
        XCTAssertEqual(components.timeZone, gmt)
        XCTAssertEqual(components.year, 2014)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 8)
        XCTAssertEqual(components.minute, 45)
        XCTAssertEqual(components.second, 4)
        XCTAssertEqual(components.nanosecond.map { (Float($0) / 1_000_000).rounded() }, 502)
    }

    func testThatTransportDatesCanBeParsed_2() throws {
        let date = try XCTUnwrap(Date(transportString: "2024-01-04T12:34:56.78+02:00"))
        let components = Calendar.current.dateComponents(in: cet, from: date)
        XCTAssertEqual(components.timeZone, cet)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 4)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 34)
        XCTAssertEqual(components.second, 56)
        XCTAssertEqual(components.nanosecond.map { (Float($0) / 1_000_000).rounded() }, 780)
    }

    // Parsing timestamps without fractional digets should not be required anymore
    // after bug [WPB-6529](https://wearezeta.atlassian.net/browse/WPB-6529) is fixed.

    func testThatTransportDatesCanBeParsed_withoutFractionalSeconds_0() throws {
        let date = try XCTUnwrap(Date(transportString: "2024-01-04T12:34:56+02:00"))
        let components = Calendar.current.dateComponents(in: cet, from: date)
        XCTAssertEqual(components.timeZone, cet)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 4)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(components.minute, 34)
        XCTAssertEqual(components.second, 56)
        XCTAssertEqual(components.nanosecond, 0)
    }

    func testThatTransportDatesCanBeParsed_withoutFractionalSeconds_1() throws {
        let date = try XCTUnwrap(Date(transportString: "2014-04-15T08:45:04Z"))
        let components = Calendar.current.dateComponents(in: gmt, from: date)
        XCTAssertEqual(components.timeZone, gmt)
        XCTAssertEqual(components.year, 2014)
        XCTAssertEqual(components.month, 4)
        XCTAssertEqual(components.day, 15)
        XCTAssertEqual(components.hour, 8)
        XCTAssertEqual(components.minute, 45)
        XCTAssertEqual(components.second, 4)
        XCTAssertEqual(components.nanosecond, 0)
    }

    func testThatNilIsReturnedForInvalidValue() {
        XCTAssertNil(Date(transportString: "2014-03-14T16:37.573Z"))
        XCTAssertNil(Date(transportString: "2014-03-14 16:47:37.573Z"))
        XCTAssertNil(Date(transportString: "2014-03T16:47:37.573Z"))
    }

    func testEncodedValues() {
        XCTAssertEqual(Date(timeIntervalSinceReferenceDate: 416508457.573).transportString(), "2014-03-14T16:47:37.573Z")
        XCTAssertEqual(Date(timeIntervalSinceReferenceDate: 419244304.502).transportString(), "2014-04-15T08:45:04.502Z")
    }

    var gmt: TimeZone {
        .gmt
    }

    var cet: TimeZone {
        .init(secondsFromGMT: 2 * 3600)!
    }
}

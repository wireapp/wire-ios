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

import XCTest

@testable import WireNetwork

final class PinnedKeyTests: XCTestCase {

    func testInit_withInvalidKeyData() {
        // GIVEN, WHEN, THEN
        XCTAssertThrowsError(
            try PinnedKey(
                rawKey: Data(),
                hosts: [.equals("foo.example.com")]
            )
        ) { error in
            XCTAssertEqual(error as? PinnedKey.Failure, .invalidKeyData)
        }
    }

    func testMatchesHost() throws {
        // GIVEN
        let sut = try PinnedKey(
            rawKey: try PublicKeys.wire,
            hosts: [
                .equals("foo.example.com"),
                .equals("bar.example.com"),
                .endsWith("example.net")
            ]
        )

        // WHEN, THEN
        XCTAssertTrue(sut.matches(host: "bar.example.com"))
        XCTAssertFalse(sut.matches(host: "something.bar.example.com"))
        XCTAssertTrue(sut.matches(host: "example.net"))
        XCTAssertTrue(sut.matches(host: "something.example.net"))
        XCTAssertFalse(sut.matches(host: "example.net.something"))
    }

}

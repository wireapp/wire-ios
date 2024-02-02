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
@testable import WireUtilities

final class StringRandomTests: XCTestCase {

    func test_randomAlphanumerical_withLenghtZero() {
        // given
        // when
        let string = String.randomAlphanumerical(length: 0)

        // then
        XCTAssertEqual(string.count, 0)
    }

    func test_randomAlphanumerical_withLengthOne() {
        // given
        // when
        let string = String.randomAlphanumerical(length: 1)

        // then
        XCTAssertEqual(string.count, 1)
    }

    func test_randomAlphanumerical_withLength256() {
        // given
        // when
        let string = String.randomAlphanumerical(length: 256)

        // then
        XCTAssertEqual(string.count, 256)
    }

    func test_randomAlphanumerical_withAlphanumericCharacters() {
        // given
        let characterSet = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

        // when
        let string = String.randomAlphanumerical(length: 128)

        // then
        XCTAssert(string.allSatisfy { character in
            characterSet.contains { $0 == character }
        })
    }

    func test_randomClientIdentifier_withDefaultLength() {
        // given
        // when
        let string = String.randomClientIdentifier()

        // then
        XCTAssertEqual(string.count, 16)
    }

    func test_randomClientIdentifier_withLength8() {
        // given
        // when
        let string = String.randomClientIdentifier(length: 8)

        // then
        XCTAssertEqual(string.count, 8)
    }

    func test_randomDomain_withDefaultLenght() {
        // given
        // when
        let string = String.randomDomain()

        // then
        XCTAssertEqual(string.count, 9)
        XCTAssert(string.hasSuffix(".com"))
    }

    func test_randomDomain_withLength8() {
        // given
        // when
        let string = String.randomDomain(hostLength: 8)

        // then
        XCTAssertEqual(string.count, 12)
        XCTAssert(string.hasSuffix(".com"))
    }

    func test_randomRemoteIdentifier_withDefaultLength() {
        // given
        // when
        let string = String.randomClientIdentifier()

        // then
        XCTAssertEqual(string.count, 16)
    }

    func test_randomRemoteIdentifier_withLength8() {
        // given
        // when
        let string = String.randomClientIdentifier(length: 8)

        // then
        XCTAssertEqual(string.count, 8)
    }
}

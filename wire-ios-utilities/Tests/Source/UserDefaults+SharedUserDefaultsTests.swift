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
@testable import WireUtilities

final class UserDefaultsSharedTests: XCTestCase {

    private let cookiesKeyName = "ZMCookieKey"

    override func tearDown() {
        UserDefaults.shared()?.removeObject(forKey: cookiesKeyName)
        super.tearDown()
    }

    func testThatItReturnsTheSameCookiesKey() {
        // given
        let key1 = UserDefaults.cookiesKey()

        // when
        let key2 = UserDefaults.cookiesKey()

        // then
        XCTAssertEqual(key1, key2)
    }

    func testThatItCreatesNewKeyIfNoKeyFoundInDefaults() {
        // given
        let key1 = UserDefaults.cookiesKey()
        UserDefaults.shared()?.removeObject(forKey: cookiesKeyName)

        // when
        let key2 = UserDefaults.cookiesKey()

        // then
        XCTAssertNotEqual(key1, key2)
    }

    func testThatItMovesCookiesFromStandardDefaultsToSharedDefaults() {
        // given
        let key1 = UserDefaults.cookiesKey()
        UserDefaults.standard.set(key1, forKey: cookiesKeyName)
        UserDefaults.shared()?.removeObject(forKey: cookiesKeyName)

        // when
        let key2 = UserDefaults.cookiesKey()
        XCTAssertEqual(key2, key1)

        // then
        XCTAssertNil(UserDefaults.standard.object(forKey: cookiesKeyName))
        XCTAssertEqual(UserDefaults.shared()?.data(forKey: cookiesKeyName), key1)
    }

}

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

import Testing

@testable import WireUtilities

@Suite(.serialized)
final class UserDefaults_SharedTests {

    deinit {
        UserDefaults.shared().removeObject(forKey: ZMCookieKeyKey)
    }

    @Test()
    func `existingCookiesKey defaults to nil`() {
        // Given, When, Then
        #expect(UserDefaults.existingCookiesKey == nil)
    }

    @Test()
    func `existingCookiesKey returns cookiesKey if set`() throws {
        // Given
        let key = try #require(UserDefaults.cookiesKey()) // This call creates the key in UserDefaults

        // When, Then
        #expect(UserDefaults.existingCookiesKey == key)
    }

}

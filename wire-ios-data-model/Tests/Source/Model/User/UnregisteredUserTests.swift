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
@testable import WireDataModel

final class UnregisteredUserTests: XCTestCase {
    func testThatItReturnsCompletedWhenUserIsComplete_Email() {
        // GIVEN
        let user = UnregisteredUser()

        // WHEN
        user.name = "Mario"
        user.unverifiedEmail = "alexis@example.com"
        user.verificationCode = "123456"
        user.accentColor = .turquoise
        user.acceptedTermsOfService = true
        user.marketingConsent = false

        // WHEN: we check if the user needs a password
        XCTAssertFalse(user.isComplete)
        XCTAssertTrue(user.needsPassword)

        // WHEN: we provide the password
        user.password = "12345678"

        // THEN
        XCTAssertTrue(user.isComplete)
        XCTAssertFalse(user.needsPassword)
    }
}

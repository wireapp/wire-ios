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

@testable import WireAuthenticationLogic

final class EmailValidatorTests: XCTestCase {

    func testIsValid_withValidEmails() {
        // given
        let testCases: [String] = [
            "MARIA@EXAMPLE.COM",
            "maria@example.com",
            "maria@sub-team22.example.com",
            "firstName.secondName@example.com"
        ]

        for email in testCases {
            // when, then
            XCTAssertTrue(EmailValidator.isValid(email: email), "Email \(email) should be valid")
        }
    }

    func testIsValid_withInvalidEmails() {
        // given
        let testCases: [String] = [
            "maria@example.com ",
            " maria@example.com",
            "something",
            "@example.com",
            "something@a.b",
            "maria@☮️.com",
            "maria@h香港.com"
        ]

        for email in testCases {
            // when, then
            XCTAssertFalse(EmailValidator.isValid(email: email), "Email \(email) should be invalid")
        }
    }
}

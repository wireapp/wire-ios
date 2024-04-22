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

class UnregisteredUserTests: XCTestCase {

    func testThatItValidatesTheUserName() {
        // GIVEN
        let validName = "Maria"
        let longName = "Ro" + String(repeating: "x", count: 200) + "y"
        let shortName = "M"

        // THEN
        XCTAssertTrue(UnregisteredUser.normalizedName(validName).isValid)
        XCTAssertFalse(UnregisteredUser.normalizedName(longName).isValid)
        XCTAssertFalse(UnregisteredUser.normalizedName(shortName).isValid)
    }

    func testThatItValidatesTheEmail() {
        // GIVEN
        let validEmail = "anette@foo.bar"
        let invalidEmail = "kathrine@"

        // THEN
        XCTAssertTrue(UnregisteredUser.normalizedEmailAddress(validEmail).isValid)
        XCTAssertFalse(UnregisteredUser.normalizedEmailAddress(invalidEmail).isValid)
    }

    func testThatItNormalizesTheEmailAddress() {
        // GIVEN
        let email = " john.doe@gmail.com "

        // WHEN
        let normalizedEmail = UnregisteredUser.normalizedEmailAddress(email)

        // THEN
        assertNormalizationValue(normalizedEmail, "john.doe@gmail.com")
    }

    func testThatItReturnsCompletedWhenUserIsComplete_Email() {
        // GIVEN
        let user = UnregisteredUser()

        // WHEN
        user.name = "Mario"
        user.credentials = .email("alexis@example.com")
        user.verificationCode = "123456"
        user.accentColorValue = .softPink
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

// MARK: - Helpers

private extension UnregisteredUserTests {

    func assertNormalizationValue<T>(_ normalizationResult: NormalizationResult<T>, _ expectedValue: T) where T: Equatable {
        guard case let .valid(value) = normalizationResult else {
            XCTFail()
            return
        }

        XCTAssertEqual(value, expectedValue)
    }

    func assertNormalizationErrorCode<T>(_ normalizationResult: NormalizationResult<T>, _ expectedCode: ZMManagedObjectValidationErrorCode) {
        guard case let .invalid(errorCode) = normalizationResult else {
            XCTFail()
            return
        }

        XCTAssertEqual(errorCode, expectedCode)
    }

}

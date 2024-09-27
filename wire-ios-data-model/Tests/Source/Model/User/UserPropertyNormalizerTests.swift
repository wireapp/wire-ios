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

final class UserPropertyNormalizerTests: XCTestCase {
    // MARK: Internal

    var sut: UserPropertyNormalizer!

    override func setUp() {
        sut = .init()
    }

    override func tearDown() {
        sut = nil
    }

    func testThatItValidatesTheUserName() {
        // GIVEN
        let validName = "Maria"
        let longName = "Ro" + String(repeating: "x", count: 200) + "y"
        let shortName = "M"

        // THEN
        XCTAssertTrue(sut.normalizeName(validName).isValid)
        XCTAssertFalse(sut.normalizeName(longName).isValid)
        XCTAssertFalse(sut.normalizeName(shortName).isValid)
    }

    func testThatItValidatesTheEmail() {
        // GIVEN
        let validEmail = "anette@foo.bar"
        let invalidEmail = "kathrine@"

        // THEN
        XCTAssertTrue(sut.normalizeEmailAddress(validEmail).isValid)
        XCTAssertFalse(sut.normalizeEmailAddress(invalidEmail).isValid)
    }

    func testThatItValidatesThePhoneNumber() {
        // GIVEN
        let validPhone = "+4912345678"
        let invalidPhone = "+49" + String(repeating: "0", count: 100)

        // WHEN
        XCTAssertTrue(sut.normalizePhoneNumber(validPhone).isValid)
        XCTAssertFalse(sut.normalizePhoneNumber(invalidPhone).isValid)
    }

    func testThatItDoesNotValidateAPhoneNumberWithLettersWithTheRightError() {
        // GIVEN
        let phoneWithLetters = "+49abcdefg"
        let shortPhoneWithLetters = "ab"

        // WHEN
        let normalizedPhoneWithLetters = sut.normalizePhoneNumber(phoneWithLetters)
        let normalizedShortPhoneWithLetters = sut.normalizePhoneNumber(shortPhoneWithLetters)

        // THEN
        assertNormalizationErrorCode(normalizedPhoneWithLetters, .phoneNumberContainsInvalidCharacters)
        assertNormalizationErrorCode(normalizedShortPhoneWithLetters, .phoneNumberContainsInvalidCharacters)
    }

    func testThatItDoesNotValidateAShortPhoneNumberWithTheRightError() {
        // GIVEN
        let shortPhone = "+49"

        // WHEN
        let normalizedPhone = sut.normalizePhoneNumber(shortPhone)

        // THEN
        assertNormalizationErrorCode(normalizedPhone, .tooShort)
    }

    func testThatItDoesNotValidateALongPhoneNumberWithTheRightError() {
        // GIVEN
        let longPhone = "+4900000002132131241241234234"

        // WHEN
        let normalizedPhone = sut.normalizePhoneNumber(longPhone)

        // THEN
        assertNormalizationErrorCode(normalizedPhone, .tooLong)
    }

    func testThatItNormalizesThePhoneNumber() {
        // GIVEN
        let phoneNumber = "+49(123)45.6-78"

        // WHEN
        let normalizedPhoneNumber = sut.normalizePhoneNumber(phoneNumber)

        // THEN
        assertNormalizationValue(normalizedPhoneNumber, "+4912345678")
    }

    func testThatItNormalizesTheEmailAddress() {
        // GIVEN
        let email = " john.doe@gmail.com "

        // WHEN
        let normalizedEmail = sut.normalizeEmailAddress(email)

        // THEN
        assertNormalizationValue(normalizedEmail, "john.doe@gmail.com")
    }

    // MARK: Private

    // MARK: - Helpers

    private func assertNormalizationValue<T>(
        _ normalizationResult: UserPropertyNormalizationResult<T>,
        _ expectedValue: T
    ) where T: Equatable {
        XCTAssertTrue(normalizationResult.isValid)
        XCTAssertEqual(normalizationResult.normalizedValue, expectedValue)
    }

    private func assertNormalizationErrorCode(
        _ normalizationResult: UserPropertyNormalizationResult<some Any>,
        _ expectedCode: ZMManagedObjectValidationErrorCode
    ) {
        guard normalizationResult.validationError != nil else {
            return XCTFail("unexpected success")
        }
        guard let error = normalizationResult.validationError as? NSError else {
            return XCTFail("unexpected error type")
        }
        XCTAssertEqual(error.code, expectedCode.rawValue)
    }
}

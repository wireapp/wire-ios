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

final class TextFieldValidatorTests: XCTestCase {

    var sut: TextFieldValidator!

    override func setUp() {
        super.setUp()
        sut = TextFieldValidator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testOneCharacterNameIsNotAccepted() {
        // GIVEN
        let text = "a"
        let type: ValidatedTextField.Kind = .name(isTeam: false)
        let expectedError: TextFieldValidator.ValidationError = .tooShort(kind: type)

        // WHEN
        let error = sut.validate(text: text, kind: type)

        // THEN
        XCTAssertEqual(expectedError, error, "Error should be \(expectedError), was \(String(describing: error))")
    }

    func testOneCharacterNameWithLeadingAndTrailingSpaceIsNotAccepted() {
        // GIVEN
        let text = " a "
        let type: ValidatedTextField.Kind = .name(isTeam: false)
        let expectedError: TextFieldValidator.ValidationError = .tooShort(kind: type)

        // WHEN
        let error = sut.validate(text: text, kind: type)

        // THEN
        XCTAssertEqual(expectedError, error, "Error should be \(expectedError), was \(String(describing: error))")
    }

    func testNameWithTenSpaceIsNotAccepted() {
        // GIVEN
        let text = String(repeating: " ", count: 10)
        let type: ValidatedTextField.Kind = .name(isTeam: false)
        let expectedError: TextFieldValidator.ValidationError = .tooShort(kind: type)

        // WHEN
        let error = sut.validate(text: text, kind: type)

        // THEN
        XCTAssertEqual(expectedError, error, "Error should be \(expectedError), was \(String(describing: error))")
    }

    func testTwoCharacterNameIsAccepted() {
        // GIVEN
        let text = "aa"
        let type: ValidatedTextField.Kind = .name(isTeam: false)
        let expectedError: TextFieldValidator.ValidationError? = .none

        // WHEN
        let error = sut.validate(text: text, kind: type)

        // THEN
        XCTAssertEqual(expectedError, error, "Error should be nil, was \(String(describing: error))")
    }
}

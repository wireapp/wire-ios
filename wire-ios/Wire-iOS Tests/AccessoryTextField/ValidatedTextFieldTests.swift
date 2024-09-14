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

import WireTestingPackage
import XCTest

@testable import Wire

final class ValidatedTextFieldTests: XCTestCase {

    // MARK: - Properties

    private var snapshotHelper: SnapshotHelper_!
    private var sut: ValidatedTextField!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        snapshotHelper = SnapshotHelper_()
        sut = ValidatedTextField(style: .default)
        sut.frame = CGRect(x: 0, y: 0, width: 375, height: 56)
    }

    // MARK: - tearDown

    override func tearDown() {
        snapshotHelper = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Snapshot Tests

    func testThatItShowsEmptyTextField() {
        // GIVEN

        // WHEN && THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItShowsPlaceHolderText() {
        // GIVEN

        // WHEN
        sut.placeholder = "TEAM NAME"

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItShowsTextInputedAndConfrimButtonIsEnabled() {
        // GIVEN

        // WHEN
        sut.text = "Wire Team"
        sut.textFieldDidChange(textField: sut)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    func testThatItShowsPasswordInputedAndConfirmButtonIsEnabled() {
        // GIVEN
        sut.kind = .password(.nonEmpty, isNew: false)

        // WHEN
        sut.text = "Password"
        sut.textFieldDidChange(textField: sut)

        // THEN
        snapshotHelper.verify(matching: sut)
    }

    // MARK: - Unit Tests

    func test_ItValidatesInput_WhenTextIsSet() {
        // Given
        let didValidate = expectation(description: "didValidate")
        sut.enableConfirmButton = {
            didValidate.fulfill()
            return true
        }

        // When
        sut.text = "foo"

        // Then
        waitForExpectations(timeout: 0.5)
    }

}

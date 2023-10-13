//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

class CreateSecureGuestLinkViewModelTests: XCTestCase {

    // MARK: - Properties

    var viewModel: CreateSecureGuestLinkViewModel!
    var mockDelegate: MockCreatePasswordSecuredLinkViewModelDelegate!

    // MARK: - setUp

    override func setUp() {
        super.setUp()
        viewModel = CreateSecureGuestLinkViewModel(delegate: mockDelegate)
        mockDelegate = MockCreatePasswordSecuredLinkViewModelDelegate()
        viewModel.delegate = mockDelegate
    }

    // MARK: - tearDown

    override func tearDown() {
        viewModel = nil
        mockDelegate = nil
        super.tearDown()
    }

    // MARK: - Unit Tests

    // MARK: - Validation

    func testPasswordValidationWithEmptyTextField() {
        let textField = ValidatedTextField(style: .default)
        textField.text = ""
        let confirmPasswordField = ValidatedTextField(style: .default)
        confirmPasswordField.text = "somePassword"

        XCTAssertFalse(viewModel.validatePassword(for: textField, against: confirmPasswordField))
    }

    func testPasswordValidationWithInvalidPassword() {
        let textField = ValidatedTextField(style: .default)
        textField.text = "invalid"
        let confirmPasswordField = ValidatedTextField(style: .default)
        confirmPasswordField.text = "invalid"

        XCTAssertFalse(viewModel.validatePassword(for: textField, against: confirmPasswordField))
    }

    func testPasswordValidationWithValidPasswordAndMatchedPasswords() {
        let textField = ValidatedTextField(style: .default)
        textField.text = "Aqa123456!Aqa123"
        let confirmPasswordField = ValidatedTextField(style: .default)
        confirmPasswordField.text = "Aqa123456!Aqa123"

        XCTAssertTrue(viewModel.validatePassword(for: textField, against: confirmPasswordField))
    }

    func testPasswordValidationWithValidPasswordAndMismatchedPasswords() {
        let textField = ValidatedTextField(style: .default)
        textField.text = "Aqa123456!Aqa123"
        let confirmPasswordField = ValidatedTextField(style: .default)
        confirmPasswordField.text = "Aqa123456!Aqa12"

        XCTAssertFalse(viewModel.validatePassword(for: textField, against: confirmPasswordField))
    }

    // MARK: - Generation of Password

    func testGenerateRandomPassword() {
        // GIVEN && WHEN
        let randomPassword = viewModel.generateRandomPassword()

        // THEN
        XCTAssertTrue(randomPassword.count >= 15 && randomPassword.count <= 20, "Password length should be between 15 and 20 characters")
        XCTAssertTrue(randomPassword.contains { "abcdefghijklmnopqrstuvwxyz".contains($0) }, "Password should contain at least one lowercase letter")
        XCTAssertTrue(randomPassword.contains { "ABCDEFGHIJKLMNOPQRSTUVWXYZ".contains($0) }, "Password should contain at least one uppercase letter")
        XCTAssertTrue(randomPassword.contains { "0123456789".contains($0) }, "Password should contain at least one number")
        XCTAssertTrue(randomPassword.contains { "!@#$%^&*()-_+=<>?/[]{|}".contains($0) }, "Password should contain at least one special character")
    }

    func testRequestRandomPassword() {
        // GIVEN
        mockDelegate.viewModelDidGeneratePassword_MockMethod = { _, _ in }

        // WHEN
        viewModel.requestRandomPassword()

        // THEN
        XCTAssertEqual(mockDelegate.viewModelDidGeneratePassword_Invocations.count, 1)
    }

}

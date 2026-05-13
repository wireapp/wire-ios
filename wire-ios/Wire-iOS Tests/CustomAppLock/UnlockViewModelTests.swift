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

@testable import Wire

final class UnlockViewModelTests: XCTestCase {

    func testDisplayModel() {
        let sut = UnlockViewModel()

        XCTAssertEqual(sut.displayModel.title, L10n.Localizable.Unlock.titleLabel)
        XCTAssertEqual(sut.displayModel.passcodePlaceholder, L10n.Localizable.Unlock.Textfield.placeholder)
        XCTAssertEqual(sut.displayModel.wipeButtonTitle, L10n.Localizable.Unlock.wipeButton)
        XCTAssertEqual(sut.displayModel.unlockButton.title, L10n.Localizable.Unlock.SubmitButton.title)
        XCTAssertFalse(sut.displayModel.unlockButton.isEnabled)
        XCTAssertNil(sut.inputState.passcode)
        XCTAssertTrue(sut.inputState.isSecureTextEntry)
        XCTAssertNil(sut.inputState.errorMessage)
    }

    func testPasscodeValidationUpdatesUnlockButtonAndClearsError() {
        var sut = UnlockViewModel()

        _ = sut.route(for: .wrongPasscode)
        XCTAssertEqual(sut.inputState.errorMessage, L10n.Localizable.Unlock.errorLabel)

        XCTAssertEqual(sut.route(for: .passcodeValidationUpdated(passcode: "passcode", isValid: true)), .none)

        XCTAssertEqual(sut.inputState.passcode, "passcode")
        XCTAssertTrue(sut.displayModel.unlockButton.isEnabled)
        XCTAssertNil(sut.inputState.errorMessage)

        _ = sut.route(for: .passcodeValidationUpdated(passcode: "", isValid: false))

        XCTAssertFalse(sut.displayModel.unlockButton.isEnabled)
    }

    func testRoutes() {
        var sut = UnlockViewModel()

        XCTAssertEqual(sut.route(for: .unlockSubmitted(nil)), .none)
        XCTAssertNil(sut.inputState.passcode)

        XCTAssertEqual(sut.route(for: .unlockSubmitted("passcode")), .unlock("passcode"))
        XCTAssertEqual(sut.inputState.passcode, "passcode")
        XCTAssertEqual(sut.route(for: .wipeTapped), .wipeDatabase)
    }

    func testWrongPasscodeDisablesUnlockAndShowsError() {
        var sut = UnlockViewModel()

        _ = sut.route(for: .passcodeValidationUpdated(passcode: "passcode", isValid: true))

        XCTAssertEqual(sut.route(for: .wrongPasscode), .none)
        XCTAssertFalse(sut.displayModel.unlockButton.isEnabled)
        XCTAssertEqual(sut.inputState.errorMessage, L10n.Localizable.Unlock.errorLabel)
        XCTAssertTrue(sut.inputState.shouldShowWrongPasscodeError)
    }

    func testSecureEntryToggleUpdatesStateAndRoutesToToggle() {
        var sut = UnlockViewModel()

        XCTAssertEqual(sut.route(for: .secureEntryToggleTapped), .toggleSecureTextEntry)
        XCTAssertFalse(sut.inputState.isSecureTextEntry)

        XCTAssertEqual(sut.route(for: .secureEntryToggleTapped), .toggleSecureTextEntry)
        XCTAssertTrue(sut.inputState.isSecureTextEntry)
    }

}

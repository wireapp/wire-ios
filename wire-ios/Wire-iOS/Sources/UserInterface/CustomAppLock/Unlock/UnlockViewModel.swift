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

import Foundation

struct UnlockViewModel {

    struct ButtonState: Equatable {
        let title: String
        let isEnabled: Bool
    }

    struct DisplayModel: Equatable {
        let title: String
        let passcodePlaceholder: String
        let wipeButtonTitle: String
        let unlockButton: ButtonState
    }

    struct InputState: Equatable {
        let passcode: String?
        let isSecureTextEntry: Bool
        let errorMessage: String?

        var shouldShowWrongPasscodeError: Bool {
            errorMessage != nil
        }
    }

    enum Action: Equatable {
        case passcodeValidationUpdated(passcode: String?, isValid: Bool)
        case unlockSubmitted(String?)
        case wipeTapped
        case secureEntryToggleTapped
        case wrongPasscode
    }

    enum Route: Equatable {
        case unlock(String)
        case wipeDatabase
        case toggleSecureTextEntry
        case none
    }

    private(set) var displayModel = DisplayModel(
        title: L10n.Localizable.Unlock.titleLabel,
        passcodePlaceholder: L10n.Localizable.Unlock.Textfield.placeholder,
        wipeButtonTitle: L10n.Localizable.Unlock.wipeButton,
        unlockButton: ButtonState(
            title: L10n.Localizable.Unlock.SubmitButton.title,
            isEnabled: false
        )
    )

    private(set) var inputState = InputState(
        passcode: nil,
        isSecureTextEntry: true,
        errorMessage: nil
    )

    mutating func route(for action: Action) -> Route {
        switch action {
        case let .passcodeValidationUpdated(passcode, isValid):
            displayModel = DisplayModel(
                title: displayModel.title,
                passcodePlaceholder: displayModel.passcodePlaceholder,
                wipeButtonTitle: displayModel.wipeButtonTitle,
                unlockButton: ButtonState(
                    title: displayModel.unlockButton.title,
                    isEnabled: isValid
                )
            )
            inputState = InputState(
                passcode: passcode,
                isSecureTextEntry: inputState.isSecureTextEntry,
                errorMessage: nil
            )
            return .none

        case let .unlockSubmitted(passcode):
            inputState = InputState(
                passcode: passcode,
                isSecureTextEntry: inputState.isSecureTextEntry,
                errorMessage: inputState.errorMessage
            )
            guard let passcode else { return .none }
            return .unlock(passcode)

        case .wipeTapped:
            return .wipeDatabase

        case .secureEntryToggleTapped:
            inputState = InputState(
                passcode: inputState.passcode,
                isSecureTextEntry: !inputState.isSecureTextEntry,
                errorMessage: inputState.errorMessage
            )
            return .toggleSecureTextEntry

        case .wrongPasscode:
            displayModel = DisplayModel(
                title: displayModel.title,
                passcodePlaceholder: displayModel.passcodePlaceholder,
                wipeButtonTitle: displayModel.wipeButtonTitle,
                unlockButton: ButtonState(
                    title: displayModel.unlockButton.title,
                    isEnabled: false
                )
            )
            inputState = InputState(
                passcode: inputState.passcode,
                isSecureTextEntry: inputState.isSecureTextEntry,
                errorMessage: L10n.Localizable.Unlock.errorLabel
            )
            return .none
        }
    }

}

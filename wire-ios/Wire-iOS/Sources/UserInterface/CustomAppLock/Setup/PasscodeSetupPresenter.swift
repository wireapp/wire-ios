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

import Foundation

// MARK: - PasscodeSetupPresenter

final class PasscodeSetupPresenter {
    // MARK: Lifecycle

    convenience init(userInterface: PasscodeSetupUserInterface) {
        let interactor = PasscodeSetupInteractor()
        self.init(userInterface: userInterface, interactorInput: interactor)
        interactor.interactorOutput = self
    }

    init(
        userInterface: PasscodeSetupUserInterface,
        interactorInput: PasscodeSetupInteractorInput
    ) {
        self.userInterface = userInterface
        self.interactorInput = interactorInput
    }

    // MARK: Internal

    var isPasscodeValid: Bool {
        switch passcodeValidationResult {
        case .valid:
            true
        default:
            false
        }
    }

    func validate(error: TextFieldValidator.ValidationError?) {
        interactorInput.validate(error: error)
    }

    func storePasscode(passcode: String, callback: ResultHandler?) {
        do {
            try interactorInput.storePasscode(passcode: passcode)
            callback?(true)
        } catch {
            callback?(false)
        }
    }

    // MARK: Private

    private weak var userInterface: PasscodeSetupUserInterface?
    private var interactorInput: PasscodeSetupInteractorInput

    private var passcodeValidationResult: PasswordValidationResult?
    private let passcodeCharacterClasses: [PasswordCharacterClass] = [
        .uppercase,
        .lowercase,
        .special,
        .digits,
    ]
}

// MARK: PasscodeSetupInteractorOutput

extension PasscodeSetupPresenter: PasscodeSetupInteractorOutput {
    private func resetValidationLabels(errors: Set<PasscodeError>, passed: Bool) {
        for errorReason in errors {
            userInterface?.setValidationLabelsState(errorReason: errorReason, passed: passed)
        }
    }

    func passcodeValidated(result: PasswordValidationResult) {
        passcodeValidationResult = result

        switch result {
        case .valid:
            userInterface?.createButtonEnabled = true
            resetValidationLabels(errors: Set(PasscodeError.allCases), passed: true)

        case let .invalid(violations):
            userInterface?.createButtonEnabled = false

            resetValidationLabels(errors: Set(PasscodeError.allCases), passed: true)
            resetValidationLabels(errors: passcodeError(from: violations), passed: false)
        }
    }
}

// MARK: - Helpers

extension PasscodeSetupPresenter {
    private func passcodeError(from violations: [PasswordValidationResult.Violation]) -> Set<PasscodeError> {
        var passcodeErrors: Set<PasscodeError> = Set()
        for violation in violations {
            switch violation {
            case .tooShort:
                passcodeErrors.insert(.tooShort)
            case let .missingRequiredClasses(passwordCharacterClass):
                passcodeErrors = passcodeErrors.union(passcodeError(from: passwordCharacterClass))
            default:
                break
            }
        }
        return passcodeErrors
    }

    private func passcodeError(from missingCharacterClasses: Set<PasswordCharacterClass>) -> Set<PasscodeError> {
        var passcodeErrors: Set<PasscodeError> = Set()
        for passcodeCharacterClass in passcodeCharacterClasses {
            if missingCharacterClasses.contains(passcodeCharacterClass) {
                switch passcodeCharacterClass {
                case .uppercase:
                    passcodeErrors.insert(.noUppercaseChar)
                case .lowercase:
                    passcodeErrors.insert(.noLowercaseChar)
                case .special:
                    passcodeErrors.insert(.noSpecialChar)
                case .digits:
                    passcodeErrors.insert(.noNumber)
                default:
                    break
                }
            }
        }

        return passcodeErrors
    }
}

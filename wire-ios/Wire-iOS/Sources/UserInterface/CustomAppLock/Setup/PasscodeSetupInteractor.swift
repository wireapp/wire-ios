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
import WireCommonComponents
import WireSyncEngine
import WireTransport
import WireUtilities

// MARK: - PasscodeSetupInteractorInput

protocol PasscodeSetupInteractorInput: AnyObject {
    func validate(error: TextFieldValidator.ValidationError?)
    func storePasscode(passcode: String) throws
}

// MARK: - PasscodeSetupInteractorOutput

protocol PasscodeSetupInteractorOutput: AnyObject {
    func passcodeValidated(result: PasswordValidationResult)
}

// MARK: - PasscodeSetupInteractor

final class PasscodeSetupInteractor {
    weak var interactorOutput: PasscodeSetupInteractorOutput?
}

// MARK: PasscodeSetupInteractorInput

extension PasscodeSetupInteractor: PasscodeSetupInteractorInput {
    func storePasscode(passcode: String) throws {
        // swiftlint:disable:next todo_requires_jira_link
        // TODO: [John] Inject the app lock controller.
        guard let appLock = ZMUserSession.shared()?.appLockController else { return }

        try appLock.updatePasscode(passcode)
        _ = appLock.evaluateAuthentication(customPasscode: passcode)
    }

    func validate(error: TextFieldValidator.ValidationError?) {
        guard let error else {
            interactorOutput?.passcodeValidated(result: .valid)
            return
        }

        switch error {
        case let .invalidPassword(violations):
            interactorOutput?.passcodeValidated(result: .invalid(violations: violations))
        default:
            break
        }
    }
}

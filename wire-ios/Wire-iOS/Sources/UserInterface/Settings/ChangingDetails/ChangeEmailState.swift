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
import WireSyncEngine

struct ChangeEmailState {
    let flowType: ChangeEmailFlowType
    let currentEmail: String?
    var newEmail: String?
    var newPassword: String?

    var emailValidationError: TextFieldValidator.ValidationError?
    var passwordValidationError: TextFieldValidator.ValidationError?
    var isEmailPasswordInputValid: Bool

    var visibleEmail: String? {
        return newEmail ?? currentEmail
    }

    var validatedEmail: String? {
        guard let newEmail = self.newEmail else { return nil }

        switch flowType {
        case .changeExistingEmail:
            guard case .none = emailValidationError else {
                return nil
            }

            return newEmail

        case .setInitialEmail:
            return isEmailPasswordInputValid ? newEmail : nil
        }
    }

    var validatedPassword: String? {
        guard let newPassword = self.newPassword else { return nil }
        return isEmailPasswordInputValid ? newPassword : nil
    }

    var validatedCredentials: UserEmailCredentials? {
        guard let email = validatedEmail, let password = validatedPassword else {
            return nil
        }

        return UserEmailCredentials(email: email, password: password)
    }

    var isValid: Bool {
        switch flowType {
        case .changeExistingEmail:
            return validatedEmail != nil
        case .setInitialEmail:
            return isEmailPasswordInputValid
        }
    }

    init(currentEmail: String?) {
        self.currentEmail = currentEmail
        flowType = currentEmail != nil ? .changeExistingEmail : .setInitialEmail
        emailValidationError = currentEmail != nil ? nil : .tooShort(kind: .email)
        isEmailPasswordInputValid = false
    }

}

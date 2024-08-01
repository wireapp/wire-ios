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

import WireSyncEngine

final class ChangeEmailViewModel {

    // MARK: - Properties

    private weak var userProfile: UserProfile?

    private let currentEmail: String?
    var newEmail: String?
    private var emailValidationError: TextFieldValidator.ValidationError?

    // MARK: - Computed Properties

    var visibleEmail: String? {
        return newEmail ?? currentEmail
    }

    var validatedEmail: String? {
        guard let newEmail = self.newEmail else { return nil }
        guard case .none = emailValidationError else {
            return nil
        }
        return newEmail
    }

    var isValid: Bool {
        return validatedEmail != nil
    }

    // MARK: - Initialization

    init(currentEmail: String?, userProfile: UserProfile?) {
        self.currentEmail = currentEmail
        self.userProfile = userProfile
        self.emailValidationError = nil
    }

    // MARK: - Methods

    func updateNewEmail(_ newEmail: String) {
        self.newEmail = newEmail
    }

    func updateEmailValidationError(_ error: TextFieldValidator.ValidationError?) {
        emailValidationError = error
    }

    func requestEmailUpdate() throws {
        guard let email = validatedEmail else {
            throw ChangeEmailError.invalidEmail
        }

        try userProfile?.requestEmailChange(email: email)
    }
}

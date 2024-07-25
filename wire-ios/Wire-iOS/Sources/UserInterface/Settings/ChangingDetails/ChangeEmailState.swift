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

/// Represents the state of the email change process.
struct ChangeEmailState {
    /// The user's current email address, if any.
    let currentEmail: String?

    /// The new email address entered by the user, if any.
    var newEmail: String?

    /// Any validation error associated with the new email address.
    var emailValidationError: TextFieldValidator.ValidationError?

    /// The email address to display in the UI.
    /// Returns the new email if set, otherwise falls back to the current email.
    var visibleEmail: String? {
        return newEmail ?? currentEmail
    }

    /// The validated new email address.
    /// Returns nil if the new email is not set or if there's a validation error.
    var validatedEmail: String? {
        guard let newEmail = self.newEmail else { return nil }
        guard case .none = emailValidationError else {
            return nil
        }
        return newEmail
    }

    /// Indicates whether the state is valid for submission.
    /// The state is considered valid if there's a validated email address.
    var isValid: Bool {
        return validatedEmail != nil
    }

    /// Initializes a new ChangeEmailState instance.
    /// - Parameter currentEmail: The user's current email address, if any.
    init(currentEmail: String?) {
        self.currentEmail = currentEmail
        emailValidationError = nil
    }
}

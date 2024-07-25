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
    let currentEmail: String?
    var newEmail: String?
    var emailValidationError: TextFieldValidator.ValidationError?

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

    init(currentEmail: String?) {
        self.currentEmail = currentEmail
        emailValidationError = nil
    }
}

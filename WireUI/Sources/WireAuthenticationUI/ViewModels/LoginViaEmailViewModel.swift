//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireReusableUIComponents

package class LoginViaEmailViewModel {

    let email: String
    let forgotPasswordURL: URL
    let passwordValidator: any PasswordValidator
    let showCreateAccount: Bool
    let onCreateAccount: @Sendable () -> Void

    // MARK: - Life cycle

    package init(
        email: String,
        forgotPasswordURL: URL,
        passwordValidator: any PasswordValidator,
        showCreateAccount: Bool,
        onCreateAccount: @Sendable @escaping () -> Void
    ) {
        self.email = email
        self.forgotPasswordURL = forgotPasswordURL
        self.passwordValidator = passwordValidator
        self.showCreateAccount = showCreateAccount
        self.onCreateAccount = onCreateAccount
    }

}

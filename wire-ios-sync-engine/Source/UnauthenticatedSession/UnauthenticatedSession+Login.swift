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

import WireDataModel

extension UserCredentials {
    var isInvalid: Bool {
        let noEmail = email?.isEmpty ?? true
        let noPassword = password?.isEmpty ?? true
        return noEmail || noPassword
    }
}

extension UnauthenticatedSession {
    @objc(continueAfterBackupImportStep)
    public func continueAfterBackupImportStep() {
        authenticationStatus.continueAfterBackupImportStep()
    }

    /// Attempt to log in with the given credentials
    @objc(loginWithCredentials:)
    public func login(with credentials: UserCredentials) {
        let updatedCredentialsInUserSession = delegate?.session(session: self, updatedCredentials: credentials) ?? false

        guard !updatedCredentialsInUserSession else {
            return
        }

        if credentials.isInvalid {
            let error = NSError(userSessionErrorCode: .needsCredentials, userInfo: nil)
            authenticationStatus.notifyAuthenticationDidFail(error)
        } else {
            authenticationErrorIfNotReachable {
                self.authenticationStatus.prepareForLogin(with: credentials)
                RequestAvailableNotification.notifyNewRequestsAvailable(nil)
            }
        }
    }

    /// Triggers a request for an email verification code for login.
    ///
    /// Returns: false if the email address was invalid.
    @objc(requestEmailVerificationCodeForLogin:)
    @discardableResult
    public func requestEmailVerificationCodeForLogin(email: String) -> Bool {
        do {
            var email: String? = email
            _ = try userPropertyValidator.validate(emailAddress: &email)
        } catch {
            return false
        }

        authenticationErrorIfNotReachable {
            self.authenticationStatus.prepareForRequestingEmailVerificationCode(forLogin: email)
            RequestAvailableNotification.notifyNewRequestsAvailable(nil)
        }
        return true
    }
}

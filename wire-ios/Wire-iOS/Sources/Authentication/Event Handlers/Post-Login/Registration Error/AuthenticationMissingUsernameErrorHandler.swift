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

/// Handles client registration errors related to the lack of a username

final class AuthenticationMissingUsernameErrorHandler: AuthenticationEventHandler {

    weak var statusProvider: AuthenticationStatusProvider?

    func handleEvent(
        currentStep: AuthenticationFlowStep,
        context: (NSError, UUID)
    ) -> [AuthenticationCoordinatorAction]? {
        let (error, _) = context

        // Only handle needsToHandleToRegisterClient errors
        guard error.userSessionErrorCode == .needsToHandleToRegisterClient else {
            return nil
        }

        // Verify the state and ask the user to add a username
        guard statusProvider?.selfUser != nil, statusProvider?.selfUserProfile != nil else {
            return nil
        }

        #if DEBUG
            if let username = UserDefaults.standard.consumePendingDeveloperCredentialUsername(
                for: statusProvider?.selfUser?.emailAddress
            ) {
                return [.hideLoadingView, .showLoadingView, .startPostLoginFlow, .setUsername(username)]
            }
        #endif

        return [.hideLoadingView, .startPostLoginFlow, .transition(.addUsername, mode: .reset)]
    }

}

#if DEBUG
    extension UserDefaults {
        func consumePendingDeveloperCredentialUsername(for email: String?) -> String? {
            let usernameKey = "DeveloperCredentialQRCode.pendingUsername"
            let emailKey = "DeveloperCredentialQRCode.pendingUsernameEmail"
            let createdAtKey = "DeveloperCredentialQRCode.pendingUsernameCreatedAt"
            let maxAge: TimeInterval = 10 * 60

            if object(forKey: usernameKey) != nil, object(forKey: emailKey) == nil {
                removeObject(forKey: usernameKey)
            }

            guard
                let username = string(forKey: usernameKey),
                let storedEmail = string(forKey: emailKey),
                let email,
                !username.isEmpty,
                storedEmail.caseInsensitiveCompare(email) == .orderedSame
            else {
                return nil
            }

            guard Date().timeIntervalSince1970 - double(forKey: createdAtKey) <= maxAge else {
                removeObject(forKey: usernameKey)
                removeObject(forKey: emailKey)
                removeObject(forKey: createdAtKey)
                return nil
            }

            removeObject(forKey: usernameKey)
            removeObject(forKey: emailKey)
            removeObject(forKey: createdAtKey)
            return username
        }
    }
#endif

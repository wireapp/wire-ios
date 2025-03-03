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

/// A object that facilitates intermodule communication, both **inbound**
/// (from outside into this module) and **outbound** (from inside this module
/// to the external world).

public struct WireAuthenticationBridge {

    public let onFlowCompletion: (AuthenticationResult) -> Void
    private let onRegisterAccount: () -> Void
    private let onSSOSuccess: (UUID, [HTTPCookie]) -> Void
    private let onSSOFailure: () -> Void

    public init(
        onFlowCompletion: @escaping (AuthenticationResult) -> Void,
        onRegisterAccount: @escaping () -> Void,
        onSSOSuccess: @escaping (UUID, [HTTPCookie]) -> Void,
        onSSOFailure: @escaping () -> Void
    ) {
        self.onFlowCompletion = onFlowCompletion
        self.onRegisterAccount = onRegisterAccount
        self.onSSOSuccess = onSSOSuccess
        self.onSSOFailure = onSSOFailure
    }

    // MARK: - Methods are called within the module, but their implementations exist outside of it.

    /// Completes the authentication flow with the given result.

    public func completeFlow(_ result: AuthenticationResult) {
        onFlowCompletion(result)
    }

    /// Initiates the account registration process.

    public func registerAccount() {
        onRegisterAccount()
    }

    // MARK: - Methods are implemented inside the module and are meant to be invoked externally.

    /// Completes the SSO process successfully.

    public func completeSSOSuccess(userID: UUID, cookies: [HTTPCookie]) {
        onSSOSuccess(userID, cookies)
    }

    /// Handles the failure of the SSO process.

    public func completeSSOFailure() {
        onSSOFailure()
    }

}

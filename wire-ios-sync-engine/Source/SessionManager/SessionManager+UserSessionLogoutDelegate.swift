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

// MARK: - UserSessionLogoutDelegate

protocol UserSessionLogoutDelegate: AnyObject {
    /// Invoked when the user successfully logged out
    func userDidLogout(accountId: UUID)

    /// Invoked when the authentication has proven invalid
    func authenticationInvalidated(_ error: NSError, accountId: UUID)
}

// MARK: - SessionManager + UserSessionLogoutDelegate

extension SessionManager: UserSessionLogoutDelegate {
    /// Invoked when the user successfully logged out
    public func userDidLogout(accountId: UUID) {
        WireLogger.sessionManager.debug("\(accountId): User logged out")

        if let account = accountManager.account(with: accountId) {
            delete(account: account, reason: .userInitiated)
        }
    }

    public func authenticationInvalidated(_ error: NSError, accountId: UUID) {
        guard
            let userSessionErrorCode = UserSessionErrorCode(rawValue: error.code),
            let account = accountManager.account(with: accountId)
        else {
            return
        }

        WireLogger.authentication
            .warn("authentication was invalidated for account \(accountId): \(userSessionErrorCode)")

        switch userSessionErrorCode {
        case .clientDeletedRemotely:
            delete(account: account, reason: .sessionExpired)

        case .accessTokenExpired:
            if configuration.wipeOnCookieInvalid {
                delete(account: account, reason: .sessionExpired)
            } else {
                logout(account: account, error: error)
            }

        default:
            if unauthenticatedSession == nil {
                createUnauthenticatedSession(accountId: accountId)
            }

            let account = accountManager.account(with: accountId)
            guard account == accountManager.selectedAccount else {
                return
            }
            delegate?.sessionManagerDidFailToLogin(error: error)
        }
    }
}

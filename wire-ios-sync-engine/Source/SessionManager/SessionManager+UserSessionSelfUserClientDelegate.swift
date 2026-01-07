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
import WireLogging

protocol UserSessionSelfUserClientDelegate: AnyObject {
    /// Invoked when a client is successfully registered
    func clientRegistrationDidSucceed(accountId: UUID)

    /// Invoked when there was an error registering the client
    func clientRegistrationDidFail(_ error: NSError, accountId: UUID)

    /// Invoked when the client has completed the initial sync
    func clientCompletedInitialSync(accountId: UUID)

    func clientDidFailSyncing(
        error: any Error,
        retryHandler: @escaping () -> Void
    )
}

extension SessionManager: UserSessionSelfUserClientDelegate {
    public func clientRegistrationDidSucceed(accountId: UUID) {
        WireLogger.sessionManager.debug("Client registration was successful")

        if configuration.encryptionAtRestEnabledByDefault {
            do {
                try activeUserSession?.setEncryptionAtRest(enabled: true, skipMigration: true)
            } catch {
                if let account = accountManager.account(with: accountId) {
                    delete(account: account, reason: .biometricPasscodeNotAvailable)
                }
            }
        }

        loginDelegate?.clientRegistrationDidSucceed(accountId: accountId)
    }

    public func clientRegistrationDidFail(_ error: NSError, accountId: UUID) {
        if unauthenticatedSession == nil || unauthenticatedSession?.accountId != accountId {
            createUnauthenticatedSession(accountId: accountId)
        }
        loginDelegate?.clientRegistrationDidFail(error, accountId: accountId)

        let account = accountManager.account(with: accountId)
        guard account == accountManager.selectedAccount else { return }

        let environment = try? environmentStore.fetchBackendEnvironment(accountID: accountId)

        delegate?.sessionManagerWillLogout(
            environment: environment,
            error: error,
            userSessionCanBeTornDown: nil
        )
    }

    public func clientCompletedInitialSync(accountId: UUID) {
        let account = accountManager.account(with: accountId)

        guard account == accountManager.selectedAccount else {
            return
        }

        Task {
            if let activeUserSession {
                await configureAnalytics(for: activeUserSession)
            }

            await MainActor.run {
                delegate?.sessionManagerDidCompleteInitialSync(for: activeUserSession)
            }
        }
    }

    func clientDidFailSyncing(
        error: any Error,
        retryHandler: @escaping () -> Void
    ) {
        delegate?.sessionManagerDidFailSyncing(
            error: error,
            retryHandler: retryHandler
        )
    }
}

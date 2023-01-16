//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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

private let log = ZMSLog(tag: "APIVersion")

extension SessionManager: APIVersionResolverDelegate {

    public func resolveAPIVersion(completion: @escaping (Error?) -> Void = {_ in }) {
        if apiVersionResolver == nil {
            apiVersionResolver = createAPIVersionResolver()
        }

        apiMigrationManager.previousAPIVersion = BackendInfo.apiVersion
        apiVersionResolver?.resolveAPIVersion(completion: completion)
    }

    func createAPIVersionResolver() -> APIVersionResolver {
        let transportSession = UnauthenticatedTransportSession(
            environment: environment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            reachability: reachability,
            applicationVersion: appVersion,
            readyForRequests: self.isUnauthenticatedTransportSessionReady
        )

        let apiVersionResolver = APIVersionResolver(
            transportSession: transportSession,
            isDeveloperModeEnabled: isDeveloperModeEnabled
        )

        apiVersionResolver.delegate = self
        return apiVersionResolver
    }

    func apiVersionResolverDidResolve(apiVersion: APIVersion) {
        let sessions = backgroundUserSessions.map(\.value)

        if apiMigrationManager.isMigration(to: apiVersion, neededForSessions: sessions) {
            migrateSessions(sessions, to: apiVersion)
        } else {
            apiMigrationManager.persistLastUsedAPIVersion(for: sessions, apiVersion: apiVersion)
        }
    }

    private func migrateSessions(_ sessions: [ZMUserSession], to apiVersion: APIVersion) {
        delegate?.sessionManagerWillMigrateAccount { [weak self] in
            guard let `self` = self else { return }
            Task {
                await self.apiMigrationManager.migrateIfNeeded(
                    sessions: sessions,
                    to: apiVersion
                )
                self.delegate?.sessionManagerDidPerformAPIMigrations()
            }
        }
    }

    func apiVersionResolverFailedToResolveVersion(reason: BlacklistReason) {
        delegate?.sessionManagerDidBlacklistCurrentVersion(reason: reason)
    }

    func apiVersionResolverDetectedFederationHasBeenEnabled() {
        delegate?.sessionManagerWillMigrateAccount { [weak self] in
            self?.migrateAllAccountsForFederation()
        }
    }

    private func migrateAllAccountsForFederation() {
        let dispatchGroup = ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Accounts Migration Group")
        let dispatchQueue = DispatchQueue(label: "Accounts Migration Queue", qos: .userInitiated)

        dispatchQueue.async { [weak self] in
            guard let `self` = self else { return }

            self.activeUserSession = nil
            self.accountManager.accounts.forEach { account in

                // 1. Tear down the user sessions
                DispatchQueue.main.sync {
                    self.tearDownBackgroundSession(for: account.userIdentifier)
                }

                // 2. Migrate users and conversations
                CoreDataStack.migrateLocalStorage(
                    accountIdentifier: account.userIdentifier,
                    applicationContainer: self.sharedContainerURL,
                    dispatchGroup: dispatchGroup,
                    migration: {
                        try $0.migrateToFederation()
                    },
                    completion: { result in
                        if case .failure = result {
                            log.error("Failed to migrate account for federation")
                        }
                    }
                )
            }

            // The migration above will call enter() / leave() on the dispatch group
            dispatchGroup?.wait(forInterval: 5)

            // 3. Reload sessions
            var authenticated = false
            self.accountManager.accounts.forEach { account in
                dispatchGroup?.enter()

                if account == self.accountManager.selectedAccount {
                    // When completed, this should trigger an AppState change through the SessionManagerDelegate
                    self.loadSession(for: account) { _ in
                        authenticated = true
                        dispatchGroup?.leave()
                    }
                } else {
                    self.withSession(for: account) { _ in
                        dispatchGroup?.leave()
                    }
                }
            }

            dispatchGroup?.wait(forInterval: 1)
            self.delegate?.sessionManagerDidPerformFederationMigration(authenticated: authenticated)
        }
    }

}

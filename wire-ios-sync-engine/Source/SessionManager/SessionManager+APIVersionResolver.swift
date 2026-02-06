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

private let log = ZMSLog(tag: "APIVersion")

extension SessionManager: APIVersionResolverDelegate {

    public func resolveAPIVersion(completion: @escaping (Error?) -> Void = { _ in }) {
        // TODO: [WPB-22507] remove this part is a complete PR
        guard !DeveloperFlag.multibackend.isOn else {
            completion(nil) // we don't need to resolve apiversion here
            return
        }
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
            applicationVersion: currentBuildNumber,
            readyForRequests: isUnauthenticatedTransportSessionReady
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
            guard let self else { return }
            Task {
                await self.apiMigrationManager.migrateIfNeeded(
                    sessions: sessions,
                    to: apiVersion
                )
                self.delegate?.sessionManagerDidPerformAPIMigrations(activeSession: self.activeUserSession)
            }
        }
    }

    func apiVersionResolverFailedToResolveVersion(reason: BlacklistReason) {
        delegate?.sessionManagerDidBlacklistCurrentVersion(reason: reason)
    }

    func apiVersionResolverDetectedFederationHasBeenEnabled(localDomain: String) {
        delegate?.sessionManagerWillMigrateAccount { [weak self] in
            self?.migrateAllAccountsForFederation(localDomain: localDomain)
        }
    }

    private func migrateAllAccountsForFederation(localDomain: String) {
        let dispatchGroup = ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Accounts Migration Group")
        let dispatchQueue = DispatchQueue(label: "Accounts Migration Queue", qos: .userInitiated)

        dispatchQueue.async { [weak self] in
            guard let self else { return }

            activeUserSession = nil
            accountManager.accounts.forEach { account in

                // 1. Tear down the user sessions
                DispatchQueue.main.async {
                    dispatchGroup.enter()
                    self.tearDownBackgroundSession(for: account.userIdentifier) {
                        Task {
                            do {
                                // 2. Migrate users and conversations
                                try await CoreDataStack.migrateLocalStorage(
                                    accountIdentifier: account.userIdentifier,
                                    applicationContainer: self.sharedContainerURL,
                                    migration: {
                                        try $0.migrateToFederation(localDomain: localDomain)
                                    }
                                )
                            } catch {
                                log.error("Failed to migrate account for federation: \(error)")
                            }

                            dispatchGroup.leave()
                        }
                    }
                }
            }

            // The migration above will call enter() / leave() on the dispatch group
            dispatchGroup.wait(forInterval: 5)

            // 3. Reload sessions
            accountManager.accounts.forEach { account in
                dispatchGroup.enter()

                if account == self.accountManager.selectedAccount {
                    // When completed, this should trigger an AppState change through the SessionManagerDelegate
                    Task {
                        _ = await self.loadSession(for: account)
                        dispatchGroup.leave()
                    }

                } else {
                    Task {
                        _ = try? await self.withSession(for: account)
                        dispatchGroup.leave()
                    }
                }
            }

            dispatchGroup.wait(forInterval: 1)
            delegate?.sessionManagerDidPerformFederationMigration(activeSession: activeUserSession)
        }
    }

}

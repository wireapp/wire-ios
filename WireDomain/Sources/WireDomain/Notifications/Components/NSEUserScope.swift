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
import NeedleFoundation
import WireDataModel
import WireFoundation
import WireNetwork

protocol NSEUserScopeDependency: Dependency {

    var currentBuildNumber: String { get }
    var appContainerURL: URL { get }
    var accountDataURL: URL { get }
    var backendStore: BackendEnvironmentStore { get }
    var sharedUserDefaults: UserDefaults { get }
    var cookieEncryptionKey: Data { get }
    var minTLSVersion: WireNetwork.TLSVersion { get }
    var preferredAPIVersion: WireNetwork.APIVersion? { get }

}

/// The scope of user within the NSE flow.
///
/// Within this scope, validation for the user is performed
/// and the next scope is prepared: `NSEClientScope`.

final class NSEUserScope: Component<NSEUserScopeDependency> {

    enum Failure: Error {

        case mainAppRequired(message: String)
        case failedToFetchBackendEnvironment(any Error)
        case failedToFetchProxyCredentials(any Error)
        case failedToStoreMetadata(any Error)
        case persistenceStoresNotFound
        case failedToLoadPersistenceStack(any Error)
        case failedToFetchCookies(any Error)
        case userNotAuthenticated
        case buildIsBlacklisted(buildNumber: String)

    }

    public let account: Account
    public var accountID: UUID {
        account.userIdentifier
    }

    public var userAccountDataURL: URL {
        dependency.accountDataURL.appending(path: accountID.uuidString)
    }

    public var journal: Journal {
        shared {
            Journal(
                userID: accountID,
                storage: dependency.sharedUserDefaults
            )
        }
    }

    public var cookieStorage: CookieStorage {
        shared {
            CookieStorage(
                userID: accountID,
                cookieEncryptionKey: dependency.cookieEncryptionKey,
                keychain: Keychain()
            )
        }
    }

    private var coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManager {
        shared {
            CoreCryptoKeyMigrationManager(journal: journal)
        }
    }

    init(
        parent: any Scope,
        account: Account
    ) {
        self.account = account
        super.init(parent: parent)
    }

    func processPayload(
        eventID: UUID,
        contentHandler: @escaping (UNNotificationContent) -> Void
    ) async throws {
        // Set up network stack.
        guard let environment = try fetchBackendEnvironment() else {
            throw Failure.mainAppRequired(message: "no stored backend for account")
        }

        var proxyCredentials: WireNetwork.ProxyCredentials?
        if let config = environment.config.proxyConfig {
            proxyCredentials = try await fetchProxyCredentials(for: config)
        }

        let networkStack = NetworkStack(
            backendEnvironment: environment,
            minTLSVersion: dependency.minTLSVersion,
            preferredAPIVersion: dependency.preferredAPIVersion,
            proxyCredentials: proxyCredentials
        )

        let metadata = try await resolveBackendMetadata(with: networkStack)
        let networkServices = try await networkStack.networkServices

        // Set up persistence stack.
        let coreDataStack = try await setupPersistenceStack(
            localDomain: metadata.domain,
            isFederationEnabled: metadata.isFederationEnabled
        )

        // Return early if needed.
        guard await !isBuildBlacklisted(networkService: networkServices.blacklist) else {
            throw Failure.buildIsBlacklisted(buildNumber: dependency.currentBuildNumber)
        }

        guard journal[.isSyncV2Enabled] else {
            throw Failure.mainAppRequired(message: "sync v2 should be enabled")
        }

        guard try await isAuthenticated() else {
            throw Failure.userNotAuthenticated
        }

        guard !coreCryptoKeyMigrationManager.isAnyMigrationRequired else {
            throw Failure.mainAppRequired(message: "core crypto key migration required")
        }

        // TODO: [WPB-19778] guard no app version migration needed.

        let context = coreDataStack.syncContext
        guard let clientID = await context.perform({ [context] in
            let selfUser = ZMUser.selfUser(in: context)
            return selfUser.selfClient()?.remoteIdentifier
        }) else {
            throw Failure.mainAppRequired(message: "no self client id")
        }
        
        let earService = await EARService(
            accountID: accountID,
            databaseContexts: [], // TODO: Do we need db contexts ?
            coreDataStack: coreDataStack,
            sharedUserDefaults: dependency.sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: LAContextStorage())
        )

        // Continue with client.
        let clientScope = clientScope(
            clientID: clientID,
            restNetworkService: networkServices.rest,
            webSocketNetworkService: networkServices.webSocket,
            apiVersion: metadata.apiVersion,
            localDomain: metadata.domain,
            isFederationEnabled: metadata.isFederationEnabled,
            coreDataStack: coreDataStack,
            earService: earService
        )

        try await clientScope.processPayload(
            eventID: eventID,
            contentHandler: contentHandler
        )
    }

    private func fetchBackendEnvironment() throws -> BackendEnvironment2? {
        do {
            return try dependency.backendStore.fetchBackendEnvironment(accountID: accountID)
        } catch {
            throw Failure.failedToFetchBackendEnvironment(error)
        }
    }

    private func fetchProxyCredentials(for config: BackendEnvironment2.ProxyConfig) async throws -> WireNetwork
        .ProxyCredentials? {
        guard config.needsAuthentication else {
            return nil
        }

        let proxyCredentialStore = ProxyCredentialStore()

        do {
            guard let (username, password) = try await proxyCredentialStore.fetchCredentials(
                host: config.host,
                port: config.port
            ) else {
                return nil
            }

            return ProxyCredentials(
                username: username,
                password: password
            )
        } catch {
            throw Failure.failedToFetchProxyCredentials(error)
        }
    }

    private func resolveBackendMetadata(with networkStack: NetworkStack) async throws -> ResolvedBackendMetadata {
        // Get the last known metadata.
        guard let prevMetadata = try dependency.backendStore.fetchBackendMetadata(accountID: accountID)  else {
            throw Failure.mainAppRequired(message: "no previous backend metadata")
        }

        // Get new metadata.
        let newMetadata = try await networkStack.resolvedBackendMetadata()

        // TODO: [WPB-19777] deduplicate
        if !prevMetadata.isFederationEnabled, newMetadata.isFederationEnabled {
            // Now that federation is enabled we'll start storing domains
            // on entities in the database. We'll therefore need to add
            // the local domain to all existing entities so they're
            // fully qualified.
            journal[.isFederationMigrationRequired] = true
        }

        // Store new metadata.
        do {
            try dependency.backendStore.storeBackendMetadata(
                newMetadata,
                for: accountID
            )
        } catch {
            throw Failure.failedToStoreMetadata(error)
        }

        return newMetadata
    }

    private func isBuildBlacklisted(networkService: NetworkService) async -> Bool {
        let api = BlacklistAPIBuilder(networkService: networkService).makeAPI()
        let useCase = IsBuildBlacklistedUseCaseImpl(
            currentBuildNumber: dependency.currentBuildNumber,
            api: api
        )

        return await useCase.invoke()
    }

    // TODO: [WPB-19777] deduplicate
    private func setupPersistenceStack(
        localDomain: String?,
        isFederationEnabled: Bool,
    ) async throws -> CoreDataStack {
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: dependency.appContainerURL,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )

        guard coreDataStack.storesExists else {
            throw Failure.persistenceStoresNotFound
        }

        guard !coreDataStack.needsMigration  else {
            throw Failure.mainAppRequired(message: "database migration required")
        }

        do {
            try await coreDataStack.load()
        } catch {
            throw Failure.failedToLoadPersistenceStack(error)
        }

        return coreDataStack
    }

    private func isAuthenticated() async throws -> Bool {
        let cookies: [HTTPCookie]
        do {
            cookies = try await cookieStorage.fetchCookies()
        } catch {
            throw Failure.failedToFetchCookies(error)
        }

        for cookie in cookies where cookie.name == "zuid" {
            if let cookieExpirationDate = cookie.expiresDate {
                return cookieExpirationDate > .now
            } else {
                return false
            }
        }

        // no cookies found
        return false
    }

    // MARK: - Children

    private func clientScope(
        clientID: String,
        restNetworkService: NetworkService,
        webSocketNetworkService: NetworkService,
        apiVersion: WireNetwork.APIVersion,
        localDomain: String,
        isFederationEnabled: Bool,
        coreDataStack: CoreDataStack,
        earService: EARServiceInterface
    ) -> NSEClientScope {
        NSEClientScope(
            parent: self,
            clientID: clientID,
            restNetworkService: restNetworkService,
            webSocketNetworkService: webSocketNetworkService,
            apiVersion: apiVersion,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled,
            coreDataStack: coreDataStack,
            earService: earService
        )
    }

}

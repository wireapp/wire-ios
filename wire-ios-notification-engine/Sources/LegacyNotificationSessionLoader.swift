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
import WireDataModel
import WireDomain
import WireFoundation
import WireNetwork

public struct LegacyNotificationSessionLoader {

    public enum Failure: Error {

        case mainAppRequired(message: String)
        case shouldBeUsingNewNSE
        case failedToFetchBackendEnvironment(any Error)
        case failedToFetchProxyCredentials(any Error)
        case persistenceStoresNotFound
        case failedToStoreMetadata(any Error)
        case failedToLoadPersistenceStack(any Error)
        case buildIsBlacklisted(buildNumber: String)
        case missingAPIVersion(message: String)
    }

    private let account: Account
    private let appContainerURL: URL
    private let accountDataURL: URL
    private let appGroupID: String
    private let buildNumber: String
    private let sharedUserDefaults: UserDefaults
    private let minTLSVersion: String?

    private let accountID: UUID
    private let backendStore: BackendEnvironmentStore
    private let journal: Journal

    public init(
        account: Account,
        appContainerURL: URL,
        appGroupID: String,
        buildNumber: String,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String?
    ) throws {
        self.account = account
        self.appContainerURL = appContainerURL
        self.appGroupID = appGroupID
        self.buildNumber = buildNumber
        self.sharedUserDefaults = sharedUserDefaults
        self.minTLSVersion = minTLSVersion

        self.accountID = account.userIdentifier
        self.accountDataURL = AccountURLs(root: appContainerURL).accountData
        self.backendStore = try BackendEnvironmentStore(directory: accountDataURL)
        self.journal = Journal(
            userID: accountID,
            storage: sharedUserDefaults
        )
    }

    public func load() async throws -> NotificationSession {
        // Get the stored environment for this account.
        let backendEnvironment = try fetchBackendEnvironment()

        // Retrieve proxy credentials if needed.
        var proxyCredentials: WireNetwork.ProxyCredentials?
        if let config = backendEnvironment.config.proxyConfig {
            proxyCredentials = try await fetchProxyCredentials(for: config)
        }

        // Set up network stack.
        let preferredAPIVersion = BackendInfo.preferredAPIVersion.flatMap {
            WireNetwork.APIVersion(rawValue: UInt($0.rawValue))
        }

        let networkStack = NetworkStack(
            backendEnvironment: backendEnvironment,
            minTLSVersion: .minVersionFrom(minTLSVersion),
            preferredAPIVersion: preferredAPIVersion,
            proxyCredentials: proxyCredentials
        )

        let networkServices = try await networkStack.networkServices

        let metadata = try await resolveBackendMetadata(with: networkStack)

        // Set up persistence stack.
        let coreDataStack = try await setupPersistenceStack(
            localDomain: metadata.domain,
            isFederationEnabled: metadata.isFederationEnabled
        )

        // Return early if needed.
        guard await !isBuildBlacklisted(networkService: networkServices.blacklist) else {
            throw Failure.buildIsBlacklisted(buildNumber: buildNumber)
        }

        guard !journal[.isSyncV2Enabled] else {
            throw Failure.shouldBeUsingNewNSE
        }

        guard let selfClientID = await coreDataStack.syncContext.perform({
            let selfUser = ZMUser.selfUser(in: coreDataStack.syncContext)
            return selfUser.selfClient()?.remoteIdentifier
        }) else {
            throw Failure.mainAppRequired(message: "no self client id")
        }

        return try await makeNotificationSession(
            selfClientID: selfClientID,
            environment: backendEnvironment,
            proxyCredentials: proxyCredentials,
            restNetworkService: networkServices.rest,
            webSocketNetworkService: networkServices.webSocket,
            backendMetadata: metadata,
            coreDataStack: coreDataStack,
            apiVersion: metadata.apiVersion
        )
    }

    private func fetchBackendEnvironment() throws -> BackendEnvironment2 {
        do {
            guard let environment = try backendStore.fetchBackendEnvironment(accountID: accountID) else {
                throw Failure.mainAppRequired(message: "no backend environment")
            }

            return environment
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
        guard let prevMetadata = try backendStore.fetchBackendMetadata(accountID: accountID) else {
            throw Failure.mainAppRequired(message: "no previous backend metadata")
        }

        // Get new metadata.
        let newMetadata = try await networkStack.resolvedBackendMetadata()

        // TODO: [WPB-17732] de-duplicate when implementing NSE
        if !prevMetadata.isFederationEnabled, newMetadata.isFederationEnabled {
            // TODO: [WPB-14630] mark federation migration needed
        }

        if prevMetadata.apiVersion < .v3, newMetadata.apiVersion >= .v3 {
            // TODO: [WPB-14630] mark access token migration needed
        }

        // Store new metadata.
        do {
            try backendStore.storeBackendMetadata(
                newMetadata,
                for: accountID
            )
        } catch {
            throw Failure.failedToStoreMetadata(error)
        }

        return newMetadata
    }

    private func setupPersistenceStack(
        localDomain: String?,
        isFederationEnabled: Bool
    ) async throws -> CoreDataStack {
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: appContainerURL,
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

    private func isBuildBlacklisted(networkService: NetworkService) async -> Bool {
        let api = BlacklistAPIBuilder(networkService: networkService).makeAPI()
        let useCase = IsBuildBlacklistedUseCaseImpl(
            currentBuildNumber: buildNumber,
            api: api
        )

        return await useCase.invoke()
    }

    private func makeNotificationSession(
        selfClientID: String,
        environment: BackendEnvironment2,
        proxyCredentials: WireNetwork.ProxyCredentials?,
        restNetworkService: NetworkService,
        webSocketNetworkService: NetworkService,
        backendMetadata: ResolvedBackendMetadata,
        coreDataStack: CoreDataStack,
        apiVersion: WireNetwork.APIVersion
    ) async throws -> NotificationSession {
        let legacyEnvironment = BackendEnvironment(environment)
        // Don't cache the cookie because if the user logs out and back in again in the main app
        // process, then the cached cookie will be invalid.
        let legacyCookieStorage = ZMPersistentCookieStorage(
            forServerName: legacyEnvironment.backendURL.host!,
            userIdentifier: accountID,
            useCache: false
        )
        guard legacyCookieStorage.hasAuthenticationCookie else {
            throw Failure.mainAppRequired(message: "no authentication cookie")
        }
        let transportSession = ZMTransportSession(
            environment: legacyEnvironment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            cookieStorage: legacyCookieStorage,
            reachability: legacyEnvironment.reachability,
            initialAccessToken: nil,
            applicationGroupIdentifier: appGroupID,
            applicationVersion: buildNumber,
            minTLSVersion: minTLSVersion,
            selfClientID: selfClientID,
            // This flag only concerns the push channel which isn't relevant
            // in the sharing session.
            isSyncV2Enabled: false
        )
        let cachesDirectory = FileManager.default.cachesURLForAccount(with: accountID, in: appContainerURL)
        let userAccountDataURL = accountDataURL.appending(path: accountID.uuidString)
        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: userAccountDataURL)
        let lastEventIDRepository = LastEventIDRepository(
            userID: accountID,
            sharedUserDefaults: sharedUserDefaults
        )
        let applicationStatusDirectory = ApplicationStatusDirectory(
            syncContext: coreDataStack.syncContext,
            transportSession: transportSession,
            lastEventIDRepository: lastEventIDRepository
        )
        let pushNotificationStrategy = PushNotificationStrategy(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
            lastEventIDRepository: lastEventIDRepository
        )

        guard let transportAPIVersion = WireTransport.APIVersion(rawValue: Int32(apiVersion.rawValue)) else {
            // we need to call tearDown before these objects are deallocated
            legacyEnvironment.reachability.tearDown()
            transportSession.tearDown()

            throw Failure.missingAPIVersion(message: "unexpected api version \(apiVersion)")
        }

        let requestGeneratorStore = RequestGeneratorStore(
            strategies: [pushNotificationStrategy],
            apiVersion: transportAPIVersion
        )
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
        let earService = EARService(
            accountID: accountID,
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: LAContextStorage())
        )
        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: accountID,
            sharedContainerURL: appContainerURL,
            accountDirectory: userAccountDataURL,
            sharedUserDefaults: sharedUserDefaults,
            syncContext: coreDataStack.syncContext,
            coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManager(journal: journal),
            allowCreation: false,
            localDomain: backendMetadata.domain
        )
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.syncContext)
        let mlsActionExecutor = MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: featureRepository
        )
        let proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)
        let mlsDecryptionService = MLSDecryptionService(
            context: coreDataStack.syncContext,
            mlsActionExecutor: mlsActionExecutor
        )
        return try NotificationSession(
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            accountIdentifier: accountID,
            pushNotificationStrategy: pushNotificationStrategy,
            earService: earService,
            proteusService: proteusService,
            mlsDecryptionService: mlsDecryptionService,
            lastEventIDRepository: lastEventIDRepository
        )
    }
}

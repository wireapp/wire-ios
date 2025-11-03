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
import WireDomain
import WireFoundation
import WireLegacyLogging
import WireNetwork

protocol UserSessionLoaderDelegate: AnyObject {

    func userSessionLoaderWillPerformMigration() async

}

final class UserSessionLoader {

    private let account: Account
    private let accountManager: AccountManager
    private let sharedContainerURL: URL
    private let legacyEnvironment: WireTransport.BackendEnvironment
    private let minTLSVersion: String?
    private let dispatchGroup: ZMSDispatchGroup
    private let sharedUserDefaults: UserDefaults
    private let application: ZMApplication
    private let appVersion: String
    private let buildNumber: String
    private let mediaManager: MediaManagerType
    private let flowManager: FlowManagerType
    private let logFilesProvider: LogFilesProviding
    private let isDeveloperModeEnabled: Bool

    private let accountID: UUID
    private let backendStore: BackendEnvironmentStore
    private let journal: Journal

    weak var delegate: UserSessionLoaderDelegate?

    init(
        account: Account,
        accountManager: AccountManager,
        sharedContainerURL: URL,
        legacyEnvironment: WireTransport.BackendEnvironment,
        minTLSVersion: String?,
        dispatchGroup: ZMSDispatchGroup,
        sharedUserDefaults: UserDefaults,
        application: ZMApplication,
        appVersion: String,
        buildNumber: String,
        mediaManager: MediaManagerType,
        flowManager: FlowManagerType,
        logFilesProvider: LogFilesProviding,
        isDeveloperModeEnabled: Bool
    ) throws {
        self.account = account
        self.accountManager = accountManager
        self.sharedContainerURL = sharedContainerURL
        self.legacyEnvironment = legacyEnvironment
        self.minTLSVersion = minTLSVersion
        self.dispatchGroup = dispatchGroup
        self.sharedUserDefaults = sharedUserDefaults
        self.application = application
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.mediaManager = mediaManager
        self.flowManager = flowManager
        self.logFilesProvider = logFilesProvider
        self.isDeveloperModeEnabled = isDeveloperModeEnabled

        self.accountID = account.userIdentifier
        let accountDataURL = AccountURLs(root: sharedContainerURL).accountData
        self.backendStore = try BackendEnvironmentStore(directory: accountDataURL)
        self.journal = Journal(
            userID: accountID,
            storage: sharedUserDefaults
        )
    }

    @MainActor
    func load(newEnvironment: NewEnvironment?) async throws -> ZMUserSession {
        // Persist the new environment and metadata
        if let newEnvironment {
            try await storeNewEnvironment(newEnvironment)
            try backendStore.storeBackendMetadata(newEnvironment.metadata, for: accountID)
        }

        // Get the environment for this account.
        let backendEnvironment: BackendEnvironment2 = if let environment = newEnvironment?.backendEnvironment {
            environment
        } else {
            try fetchBackendEnvironment()
        }

        // Update account metadata.
        if backendEnvironment.environmentType != .default {
            account.backendName = backendEnvironment.title
            accountManager.addOrUpdate(account)
        }

        // Retrieve proxy credentials if needed.
        var proxyCredentials: WireNetwork.ProxyCredentials?
        if let config = backendEnvironment.config.proxyConfig {
            proxyCredentials = try await fetchProxyCredentials(for: config)
        }

        // Resolve backend metadata.
        let preferredAPIVersion = BackendInfo.preferredAPIVersion.map {
            WireNetwork.APIVersion($0)
        }

        let networkStack = NetworkStack(
            backendEnvironment: backendEnvironment,
            minTLSVersion: .minVersionFrom(minTLSVersion),
            preferredAPIVersion: preferredAPIVersion,
            proxyCredentials: proxyCredentials
        )

        let metadata: ResolvedBackendMetadata = if let newMetadata = newEnvironment?.metadata {
            newMetadata
        } else {
            try await resolveBackendMetadata(with: networkStack)
        }

        // Load persistence stack.
        let coreDataStack = try await loadPersistenceStack(
            localDomain: metadata.domain,
            isFederationEnabled: metadata.isFederationEnabled
        )

        // Move to new sync if possible.
        try await enableSyncV2IfNeeded(
            metadata: metadata,
            eventContext: coreDataStack.eventContext
        )

        // Load network stack.
        // TODO: [WPB-20310] require proxy credentials if missing
        let networkServices = try await networkStack.networkServices

        // Store any new cookies.
        let cookieStorage = CookieStorage(
            userID: accountID,
            cookieEncryptionKey: UserDefaults.cookiesKey(),
            keychain: Keychain()
        )

        if let cookies = newEnvironment?.cookies {
            try await cookieStorage.storeCookies(cookies)
        }

        // Check if this backend supports MLS.
        let isBackendMLSEnabled = try await isBackendMLSEnabled(
            networkService: networkServices.rest,
            cookieStorage: cookieStorage,
            apiVersion: metadata.apiVersion
        )
        journal[.isBackendMLSEnabled] = isBackendMLSEnabled

        // Create user session.
        let userSession = await createUserSession(
            environment: backendEnvironment,
            proxyCredentials: proxyCredentials,
            restNetworkService: networkServices.rest,
            webSocketNetworkService: networkServices.webSocket,
            blacklistNetworkService: networkServices.blacklist,
            backendMetadata: metadata,
            coreDataStack: coreDataStack,
            cookieStorage: cookieStorage
        )

        // Check if this build is blacklisted.
        if try await isBuildBlacklisted(userSession: userSession) {
            await userSession.close(deleteCookie: false)
            throw Failure.buildIsBlacklisted
        }

        // Perform pending migrations.
        do {
            try await performPendingMigrations(
                userSession: userSession,
                localDomain: metadata.domain
            )
        } catch {
            await userSession.close(deleteCookie: false)
            throw error
        }

        return userSession
    }

    private func storeNewEnvironment(_ environment: NewEnvironment) async throws {
        do {
            try backendStore.storeBackendEnvironment(
                environment.backendEnvironment,
                for: accountID
            )

            if
                let proxyConfig = environment.backendEnvironment.config.proxyConfig,
                let credentials = environment.proxyCredentials {
                let store = ProxyCredentialStore()
                try await store.storeCredentials(
                    host: proxyConfig.host,
                    port: proxyConfig.port,
                    username: credentials.username,
                    password: credentials.password
                )
            }
        } catch {
            throw Failure.failedToStoreNewEnvironment(error)
        }
    }

    private func fetchBackendEnvironment() throws -> BackendEnvironment2 {
        do {
            if let environment = try backendStore.fetchBackendEnvironment(accountID: accountID) {
                return environment
            } else {
                // If there's nothing in the store then we're on the
                // update path. Fallback to legacy and store it.
                let environment = BackendEnvironment2(legacyEnvironment)
                try backendStore.storeBackendEnvironment(environment, for: accountID)
                return environment
            }
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
        var prevMetadata: ResolvedBackendMetadata?
        if let storedMetadata = try backendStore.fetchBackendMetadata(accountID: accountID) {
            prevMetadata = storedMetadata
        } else if
            let legacyAPIVersion = BackendInfo.apiVersion,
            let legacyDomain = BackendInfo.domain {
            // We're on the update path, use the legacy metadata.
            prevMetadata = ResolvedBackendMetadata(
                apiVersion: .init(legacyAPIVersion),
                domain: legacyDomain,
                isFederationEnabled: BackendInfo.isFederationEnabled
            )
        }

        // Get new metadata.
        let newMetadata: ResolvedBackendMetadata
        do {
            let metadata = try await networkStack.resolvedBackendMetadata()
            newMetadata = ResolvedBackendMetadata(
                apiVersion: metadata.apiVersion,
                domain: metadata.domain,
                isFederationEnabled: metadata.isFederationEnabled
            )
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            // To allow offline browsing fallback to previous metadata if possible.
            if let prevMetadata {
                newMetadata = prevMetadata
            } else {
                throw Failure.noResolvedBackendMetadataAvailable
            }
        }

        if let prevMetadata {
            if !prevMetadata.isFederationEnabled, newMetadata.isFederationEnabled {
                // Now that federation is enabled we'll start storing domains
                // on entities in the database. We'll therefore need to add
                // the local domain to all existing entities so they're
                // fully qualified.
                journal[.isFederationMigrationRequired] = true
            }
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

    private func loadPersistenceStack(
        localDomain: String?,
        isFederationEnabled: Bool
    ) async throws -> CoreDataStack {
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL,
            dispatchGroup: dispatchGroup,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )

        if coreDataStack.needsMigration {
            await delegate?.userSessionLoaderWillPerformMigration()
        }

        do {
            try await coreDataStack.load()
        } catch {
            throw Failure.failedToLoadPersistenceStack(error)
        }

        return coreDataStack
    }

    private func enableSyncV2IfNeeded(
        metadata: ResolvedBackendMetadata,
        eventContext: NSManagedObjectContext
    ) async throws {
        let isAvailable = metadata.apiVersion >= .minimumSyncV2CompatibleVersion
        let isAlreadyEnabled = journal[.isSyncV2Enabled]
        let shouldEnable = isAvailable && !isAlreadyEnabled

        guard shouldEnable else {
            return
        }

        let dao: UpdateEventMigratorDAOProtocol = if #available(iOS 17, *) {
            ActorBasedUpdateEventMigratorDAO(context: eventContext)
        } else {
            UpdateEventMigratorDAO(context: eventContext)
        }

        let migrator = UpdateEventMigrator(
            dao: dao,
            localDomain: metadata.domain
        )

        do {
            if try await migrator.isMigrationNeeded() {
                try await migrator.migrateLegacyUpdateEvents()
                // Since we only migrate some events, we require an
                // initial sync to ensure we didn't miss updates.
                journal[.isInitialSyncRequired] = true
            } else {
                WireLogger.sync.debug("no migration needed")
            }

            journal[.isSyncV2Enabled] = true

        } catch {
            WireLogger.sync.critical("failed to migrate update events: \(error)")
            throw Failure.failedToEnabledSyncV2(error)
        }
    }

    @MainActor
    private func createUserSession(
        environment: BackendEnvironment2,
        proxyCredentials: WireNetwork.ProxyCredentials?,
        restNetworkService: NetworkService,
        webSocketNetworkService: NetworkService,
        blacklistNetworkService: NetworkService,
        backendMetadata: ResolvedBackendMetadata,
        coreDataStack: CoreDataStack,
        cookieStorage: CookieStorage
    ) async -> ZMUserSession {
        let selfClientID = await coreDataStack.viewContext.perform {
            ZMUser.selfUser(in: coreDataStack.viewContext).selfClient()?.remoteIdentifier
        }
        let legacyEnvironment = BackendEnvironment(environment)
        let transportSession = ZMTransportSession(
            environment: legacyEnvironment,
            proxyUsername: proxyCredentials?.username,
            proxyPassword: proxyCredentials?.password,
            cookieStorage: legacyEnvironment.cookieStorage(for: account),
            reachability: legacyEnvironment.reachabilityWrapper(enabled: true),
            initialAccessToken: nil,
            applicationGroupIdentifier: nil,
            applicationVersion: buildNumber,
            minTLSVersion: minTLSVersion,
            selfClientID: selfClientID,
            isSyncV2Enabled: journal[.isSyncV2Enabled]
        )

        let cryptoboxMigrationManager = CryptoboxMigrationManager()
        let coreCryptoKeyMigrationManager = CoreCryptoKeyMigrationManager(journal: journal)

        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: account.userIdentifier,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: coreDataStack.accountContainer,
            sharedUserDefaults: sharedUserDefaults,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            coreCryptoKeyMigrationManager: coreCryptoKeyMigrationManager,
            localDomain: backendMetadata.domain
        )

        let lastEventIDRepository = LastEventIDRepository(
            userID: accountID,
            sharedUserDefaults: sharedUserDefaults
        )

        let selfUser = ZMUser.selfUser(in: coreDataStack.viewContext)

        let contextStorage = LAContextStorage()

        let appLock = AppLockController(
            userId: accountID,
            selfUser: selfUser,
            legacyConfig: nil,
            authenticationContext: AuthenticationContext(storage: contextStorage)
        )

        let applicationStatusDirectory = ApplicationStatusDirectory(
            withManagedObjectContext: coreDataStack.syncContext,
            cookieStorage: transportSession.cookieStorage,
            requestCancellation: transportSession,
            application: application,
            lastEventIDRepository: lastEventIDRepository,
            coreCryptoProvider: coreCryptoProvider,
            isSyncV2Enabled: journal[.isSyncV2Enabled],
            localDomain: backendMetadata.domain,
            isBackendMLSEnabled: journal[.isBackendMLSEnabled]
        )

        let e2eiActivationDateRepository = E2EIActivationDateRepository(
            userID: accountID,
            sharedUserDefaults: sharedUserDefaults
        )

        let earService = EARService(
            accountID: accountID,
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext,
                coreDataStack.searchContext
            ],
            canPerformKeyMigration: true,
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: contextStorage)
        )

        let lastE2EIdentityUpdateDateRepository = LastE2EIdentityUpdateDateRepository(
            userID: accountID,
            sharedUserDefaults: UserDefaults.standard
        )

        let mlsService = MLSService(
            context: coreDataStack.syncContext,
            notificationContext: coreDataStack.syncContext.notificationContext,
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: LegacyFeatureRepository(context: coreDataStack.syncContext),
            userDefaults: .standard,
            userID: accountID,
            localDomain: backendMetadata.domain
        )

        let proteusToMLSMigrationCoordinator = ProteusToMLSMigrationCoordinator(
            context: coreDataStack.syncContext,
            userID: accountID,
            apiVersion: WireTransport.APIVersion(rawValue: Int32(backendMetadata.apiVersion.rawValue))
        )
        let recurringActionService = RecurringActionService(
            storage: sharedUserDefaults,
            dateProvider: .system
        )

        let cacheLocation = FileManager.default.cachesURLForAccount(
            with: accountID,
            in: sharedContainerURL
        )

        let relocator = CacheFileRelocator()
        relocator.moveCachesIfNeededForAccount(
            with: accountID,
            in: sharedContainerURL
        )

        let dependencies = UserSessionDependencies(
            caches: .init(
                fileAssets: FileAssetCache(location: cacheLocation),
                userImages: UserImageLocalCache(location: cacheLocation),
                searchUsers: NSCache()
            )
        )

        let userSession = ZMUserSession(
            userId: accountID,
            restNetworkService: restNetworkService,
            websocketNetworkService: webSocketNetworkService,
            blacklistNetworkService: blacklistNetworkService,
            backendMetadata: backendMetadata,
            transportSession: transportSession,
            mediaManager: mediaManager,
            flowManager: flowManager,
            application: application,
            currentAppVersion: appVersion,
            currentBuildNumber: buildNumber,
            coreDataStack: coreDataStack,
            earService: earService,
            mlsService: mlsService,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            proteusToMLSMigrationCoordinator: proteusToMLSMigrationCoordinator,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: sharedContainerURL,
            appLock: appLock,
            coreCryptoProvider: coreCryptoProvider,
            lastEventIDRepository: lastEventIDRepository,
            lastE2EIUpdateDateRepository: lastE2EIdentityUpdateDateRepository,
            e2eiActivationDateRepository: e2eiActivationDateRepository,
            applicationStatusDirectory: applicationStatusDirectory,
            contextStorage: contextStorage,
            recurringActionService: recurringActionService,
            dependencies: dependencies,
            journal: journal,
            logFilesProvider: logFilesProvider,
            cookieStorage: cookieStorage
        )

        userSession.setup(
            apiVersion: backendMetadata.apiVersion,
            eventProcessor: nil,
            strategyDirectory: nil,
            syncStrategy: nil,
            operationLoop: nil,
            configuration: .init(),
            isDeveloperModeEnabled: isDeveloperModeEnabled
        )

        userSession.startRequestLoopTracker()

        return userSession
    }

    private func isBackendMLSEnabled(
        networkService: NetworkService,
        cookieStorage: CookieStorage,
        apiVersion: WireNetwork.APIVersion
    ) async throws -> Bool {
        do {
            let authenticationManager = AuthenticationManager(
                clientID: nil,
                cookieStorage: cookieStorage,
                networkService: networkService,
                onAuthenticationFailure: {}
            )
            let apiService = APIService(
                networkService: networkService,
                authenticationManager: authenticationManager
            )
            let api = MLSAPIBuilder(apiService: apiService).makeAPI(for: apiVersion)
            let keys = try await api.getBackendMLSPublicKeys()
            return keys.removal.isValid
        } catch
        URLError.notConnectedToInternet,
            URLError.networkConnectionLost,
            MLSAPIError.unsupportedEndpointForAPIVersion,
            MLSAPIError.mlsNotEnabled {
            // Don't block session loading, we'll try again later.
            return false
        }
    }

    private func isBuildBlacklisted(userSession: ZMUserSession) async throws -> Bool {
        do {
            let useCase = userSession.userSessionComponent.makeIsBuildBlacklistedUseCase()
            return try await useCase.invoke()
        } catch URLError.notConnectedToInternet, URLError.networkConnectionLost {
            return false
        }
    }

    private func performPendingMigrations(
        userSession: ZMUserSession,
        localDomain: String
    ) async throws {
        if journal[.isFederationMigrationRequired] {
            WireLogger.session.info(
                "federation migration is required...",
                attributes: .safePublic
            )
            do {
                try await CoreDataStack.migrateLocalStorage(
                    accountIdentifier: accountID,
                    applicationContainer: sharedContainerURL,
                    migration: {
                        try $0.migrateToFederation(localDomain: localDomain)
                    }
                )
                journal[.isFederationMigrationRequired] = false
            } catch {
                WireLogger.session.error(
                    "failed to migrate to federation: \(String(describing: error))",
                )
                throw Failure.failedToMigrateToFederation(error)
            }
        }

        // Perform app version migrations.
        let migrationService = userSession.makeAppVersionMigrationService()
        if migrationService.isMigrationNeeded {
            await delegate?.userSessionLoaderWillPerformMigration()

            do {
                try await migrationService.performAppMigrations()
            } catch {
                WireLogger.session.error(
                    "Failed to perform app version migrations: \(String(describing: error))"
                )
                throw Failure.failedToPerformMigration(error)
            }
        }

        // Perform consumable notifications migration.
        var shouldTriggerSync = true
        do {
            try await userSession.migrateToConsumableNotificationsIfNeeded()
        } catch ZMUserSessionError.selfClientNotReady {
            // We skip trigger sync, because in this case (fresh login),
            // we don't have a registered client yet, so no consumable capability
            WireLogger.sync.warn("No consumable-notifications migrator available")
            shouldTriggerSync = false
        } catch {
            throw Failure.failedToMigrationToConsumableNotifications(error)
        }

        if shouldTriggerSync {
            await userSession.triggerSync()
        }
    }

    enum Failure: Error, SafeForLoggingStringConvertible {

        case failedToStoreNewEnvironment(any Error)
        case failedToFetchBackendEnvironment(any Error)
        case failedToFetchProxyCredentials(any Error)
        case noResolvedBackendMetadataAvailable
        case failedToStoreMetadata(any Error)
        case failedToLoadPersistenceStack(any Error)
        case failedToEnabledSyncV2(any Error)
        case buildIsBlacklisted
        case failedToPerformMigration(any Error)
        case failedToMigrateToFederation(any Error)
        case failedToMigrationToConsumableNotifications(any Error)

        var safeForLoggingDescription: String {
            switch self {
            case .failedToStoreNewEnvironment:
                "failed to store new environment"
            case .failedToFetchBackendEnvironment:
                "failed to fetch backend environment"
            case .failedToFetchProxyCredentials:
                "failed to fetch proxy credentials"
            case .noResolvedBackendMetadataAvailable:
                "no resolved backend metadata available"
            case .failedToStoreMetadata:
                "failed to store metadata"
            case .failedToLoadPersistenceStack:
                "failed to load persistence stack"
            case .failedToEnabledSyncV2:
                "failed to enable sync v2"
            case .buildIsBlacklisted:
                "build is blacklisted"
            case .failedToPerformMigration:
                "failed to perform migration"
            case .failedToMigrateToFederation:
                "failed to migrate to federation"
            case .failedToMigrationToConsumableNotifications:
                "failed to migrate to consumable notifications"
            }
        }

    }

}

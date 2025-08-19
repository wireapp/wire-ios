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
import WireLogging
import WireNetwork

protocol UserSessionLoaderDelegate: AnyObject {

    func userSessionLoaderWillPerformMigration() async

}

final class UserSessionLoader {

    private let account: Account
    private let sharedContainerURL: URL
    private let legacyEnvironment: WireTransport.BackendEnvironment
    private let minTLSVersion: String
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
        sharedContainerURL: URL,
        legacyEnvironment: WireTransport.BackendEnvironment,
        minTLSVersion: String,
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

        accountID = account.userIdentifier
        let accountDataURL = AccountURLs(root: sharedContainerURL).accountData
        backendStore = try BackendEnvironmentStore(directory: accountDataURL)
        journal = Journal(
            userID: accountID,
            storage: sharedUserDefaults
        )
    }

    @MainActor
    func load() async throws -> UserSession {
        // Get the stored environment for this account.
        let backendEnvironment = try fetchBackendEnvironment()

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

        let metadata = try await resolveBackendMetadata(with: networkStack)

        // Load persistence stack.
        let coreDataStack = try await loadPersistenceStack()

        // Move to new sync if possible.
        try await enableSyncV2IfNeeded(
            metadata: metadata,
            eventContext: coreDataStack.eventContext
        )

        // Load network stack.
        let networkServices = try networkStack.networkServices

        // Create user session.
        let userSession = await createUserSession(
            environment: backendEnvironment,
            proxyCredentials: proxyCredentials,
            restNetworkService: networkServices.rest,
            webSocketNetworkService: networkServices.webSocket,
            backendMetadata: metadata,
            coreDataStack: coreDataStack
        )

        // Perform pending migrations.

        fatalError()
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

    private func fetchProxyCredentials(for config: BackendEnvironment2.ProxyConfig) async throws -> WireNetwork.ProxyCredentials? {
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
            let legacyDomain = BackendInfo.domain
        {
            // We're on the update path, use the legacy metadata.
            // TODO: check... need isMLSEnabled too?
            prevMetadata = ResolvedBackendMetadata(
                apiVersion: .init(legacyAPIVersion),
                domain: legacyDomain,
                isFederationEnabled: BackendInfo.isFederationEnabled
            )
        }

        // Get new metadata.
        let newMetadata = try await networkStack.resolvedBackendMetadata()

        if let prevMetadata {
            if !prevMetadata.isFederationEnabled && newMetadata.isFederationEnabled {
                // TODO: [WPB-14630] mark federation migration needed
            }

            if prevMetadata.apiVersion < .v3 && newMetadata.apiVersion >= .v3 {
                // TODO: [WPB-14630] mark access token migration needed
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

    private func loadPersistenceStack() async throws -> CoreDataStack {
        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL,
            dispatchGroup: dispatchGroup
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
        let isAvailable = metadata.apiVersion >= .v8
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

    private func createUserSession(
        environment: BackendEnvironment2,
        proxyCredentials: WireNetwork.ProxyCredentials?,
        restNetworkService: NetworkService,
        webSocketNetworkService: NetworkService,
        backendMetadata: ResolvedBackendMetadata,
        coreDataStack: CoreDataStack,

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
            reachability: legacyEnvironment.reachabilityWrapper(),
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
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            coreCryptoKeyMigrationManager: coreCryptoKeyMigrationManager
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
            isSyncV2Enabled: journal[.isSyncV2Enabled]
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
            userID: accountID
        )

        let proteusToMLSMigrationCoordinator =  ProteusToMLSMigrationCoordinator(
            context: coreDataStack.syncContext,
            userID: accountID
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
            logFilesProvider: logFilesProvider
        )

        userSession.setup(
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

    private func performPendingMigrations(userSession: ZMUserSession) async throws {
        // TODO: [WPB-14630] perform metadata migrations

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

    enum Failure: Error {

        case failedToFetchBackendEnvironment(any Error)
        case failedToFetchProxyCredentials(any Error)
        case failedToStoreMetadata(any Error)
        case failedToLoadPersistenceStack(any Error)
        case failedToEnabledSyncV2(any Error)
        case failedToPerformMigration(any Error)
        case failedToMigrationToConsumableNotifications(any Error)

    }

}

private extension BackendEnvironment2 {

    init(_ legacyEnvironment: WireTransport.BackendEnvironment) {
        let environmentType: EnvironmentType
        switch legacyEnvironment.environmentType.value {
        case .default:
            environmentType = .default
        case .staging:
            environmentType = .staging
        case .anta:
            environmentType = .anta
        case .bella:
            environmentType = .bella
        case .chala:
            environmentType = .chala
        case .diya:
            environmentType = .diya
        case .elna:
            environmentType = .elna
        case .foma:
            environmentType = .foma
        case let .custom(url):
            environmentType = .custom(url: url)
        }

        let endpoints = Endpoints(
            restAPIURL: legacyEnvironment.backendURL,
            websocketURL: legacyEnvironment.backendWSURL,
            blacklistURL: legacyEnvironment.blackListURL,
            teamsURL: legacyEnvironment.teamsURL,
            accountsURL: legacyEnvironment.accountsURL,
            websiteURL: legacyEnvironment.websiteURL,
            countlyURL: legacyEnvironment.countlyURL
        )

        let pinnedKeys: [PinnedKey] = legacyEnvironment.trustData.map {
            PinnedKey(
                key: $0.certificateKey,
                rawKey: $0.rawCertificateKey,
                hosts: $0.hosts.map { host in
                    switch host.rule {
                    case .endsWith:
                        return .endsWith(host.value)
                    case .equals:
                        return .equals(host.value)
                    }
                }
            )
        }

        let proxyConfig = legacyEnvironment.proxy.map {
            ProxyConfig(
                host: $0.host,
                port: $0.port,
                needsAuthentication: $0.needsAuthentication
            )
        }

        let config = Config(
            endpoints: endpoints,
            pinnedKeys: pinnedKeys,
            proxyConfig: proxyConfig
        )

        self.init(
            title: legacyEnvironment.title,
            environmentType: environmentType,
            config: config
        )
    }

}

private struct ProxyCredentialStore {

    let keychain = Keychain()

    func fetchCredentials(
        host: String,
        port: Int
    ) async throws -> (username: String, password: String)? {
        let usernameData: Data? = try await keychain.fetchItem(query: [
            .itemClass(.genericPassword),
            .account("proxy-\(host):\(port)-username"),
            .returningData(true)
        ])

        let passwordData: Data? = try await keychain.fetchItem(query: [
            .itemClass(.genericPassword),
            .account("proxy-\(host):\(port)-password"),
            .returningData(true)
        ])

        guard
            let usernameData,
            let passwordData
        else {
            return nil
        }

        return (
            username: String(decoding: usernameData, as: UTF8.self),
            password: String(decoding: passwordData, as: UTF8.self)
        )
    }

}

private extension WireNetwork.APIVersion {

    init(_ legacyVersion: WireTransport.APIVersion) {
        switch legacyVersion {
        case .v0:
            self = .v0
        case .v1:
            self = .v1
        case .v2:
            self = .v2
        case .v3:
            self = .v3
        case .v4:
            self = .v4
        case .v5:
            self = .v5
        case .v6:
            self = .v6
        case .v7:
            self = .v7
        case .v8:
            self = .v8
        case .v9:
            self = .v9
        case .v10:
            self = .v10
        }
    }

}

extension WireTransport.BackendEnvironment {

    convenience init(_ backendEnvironment: BackendEnvironment2) {
        let trustData: [TrustData] = backendEnvironment.config.pinnedKeys.map { pinnedKey in
                TrustData(
                    certificateKey: pinnedKey.key,
                    rawCertificateKey: pinnedKey.rawKey,
                    hosts: pinnedKey.hosts.map { host in
                        switch host {
                        case let .endsWith(value):
                            TrustData.Host(
                                rule: .endsWith,
                                value: value
                            )
                        case let .equals(value):
                            TrustData.Host(
                                rule: .equals,
                                value: value
                            )
                        }
                    }
                )
        }

        let environmentType: EnvironmentType
        switch backendEnvironment.environmentType {
        case .default:
            environmentType = .default
        case .staging:
            environmentType = .staging
        case .anta:
            environmentType = .anta
        case .bella:
            environmentType = .bella
        case .chala:
            environmentType = .chala
        case .diya:
            environmentType = .diya
        case .elna:
            environmentType = .elna
        case .foma:
            environmentType = .foma
        case let .custom(url):
            environmentType = .custom(url: url)
        }

        let endpoints = BackendEndpoints(
            backendURL: backendEnvironment.config.endpoints.restAPIURL,
            backendWSURL: backendEnvironment.config.endpoints.websocketURL,
            blackListURL: backendEnvironment.config.endpoints.blacklistURL,
            teamsURL: backendEnvironment.config.endpoints.teamsURL,
            accountsURL: backendEnvironment.config.endpoints.accountsURL,
            websiteURL: backendEnvironment.config.endpoints.websiteURL,
            countlyURL: backendEnvironment.config.endpoints.countlyURL
        )

        var proxySettings: WireTransport.ProxySettings?
        if let proxyConfig = backendEnvironment.config.proxyConfig {
            proxySettings = WireTransport.ProxySettings(
                host: proxyConfig.host,
                port: proxyConfig.port,
                needsAuthentication: proxyConfig.needsAuthentication
            )
        }

        let certificateTrust = ServerCertificateTrust(
            trustData: trustData,
            currentDateProvider: .system
        )

        self.init(
            title: backendEnvironment.title,
            trustData: trustData,
            environmentType: environmentType,
            endpoints: endpoints,
            proxySettings: proxySettings,
            certificateTrust: certificateTrust
        )
    }

}

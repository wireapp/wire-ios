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
import WireDataModel
import WireDomain
import WireFoundation
import WireNetwork
import WireRequestStrategy

public struct SharingSessionLoader {

    public enum Failure: Error {

        case mainAppRequired(message: String)
        case failedToFetchBackendEnvironment(any Error)
        case failedToFetchProxyCredentials(any Error)
        case persistenceStoresNotFound
        case failedToStoreMetadata(any Error)
        case failedToLoadPersistenceStack(any Error)
        case buildIsBlacklisted(buildNumber: String)

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
    private let coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManager

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
        self.coreCryptoKeyMigrationManager = CoreCryptoKeyMigrationManager(journal: journal)
    }

    public func load() async throws -> SharingSession {
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
            throw Failure.mainAppRequired(message: "sync v2 should be enabled")
        }

        guard !coreCryptoKeyMigrationManager.isAnyMigrationRequired else {
            throw Failure.mainAppRequired(message: "core crypto key migration is required")
        }

        // TODO: [WPB-19778] guard no app version migration needed.

        let context = coreDataStack.syncContext
        guard let selfClientID = await context.perform({ [context] in
            let selfUser = ZMUser.selfUser(in: context)
            return selfUser.selfClient()?.remoteIdentifier
        }) else {
            throw Failure.mainAppRequired(message: "no self client id")
        }

        // Create sharing session.
        return try await makeSharingSession(
            selfClientID: selfClientID,
            environment: backendEnvironment,
            proxyCredentials: proxyCredentials,
            restNetworkService: networkServices.rest,
            webSocketNetworkService: networkServices.webSocket,
            blacklistNetworkService: networkServices.blacklist,
            backendMetadata: metadata,
            coreDataStack: coreDataStack
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
            // Now that federation is enabled we'll start storing domains
            // on entities in the database. We'll therefore need to add
            // the local domain to all existing entities so they're
            // fully qualified.
            journal[.isFederationMigrationRequired] = true
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

    private func makeSharingSession(
        selfClientID: String,
        environment: BackendEnvironment2,
        proxyCredentials: WireNetwork.ProxyCredentials?,
        restNetworkService: NetworkService,
        webSocketNetworkService: NetworkService,
        blacklistNetworkService: NetworkService,
        backendMetadata: ResolvedBackendMetadata,
        coreDataStack: CoreDataStack
    ) async throws -> SharingSession {
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
        let analyticsEventPersistence = ShareExtensionAnalyticsPersistence(accountContainer: userAccountDataURL)
        let applicationStatusDirectory = ApplicationStatusDirectory(
            syncContext: coreDataStack.syncContext,
            transportSession: transportSession
        )
        let linkPreviewPreprocessor = LinkPreviewPreprocessor(
            linkPreviewDetector: applicationStatusDirectory.linkPreviewDetector,
            managedObjectContext: coreDataStack.syncContext
        )
        let strategyFactory = StrategyFactory(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            linkPreviewPreprocessor: linkPreviewPreprocessor,
            transportSession: transportSession,
            initiateResetMLSConversationUseCase: NullInitiateResetMLSConversationUseCase(),
            apiVersion: .init(rawValue: Int32(backendMetadata.apiVersion.rawValue)),
            localDomain: backendMetadata.domain
        )
        let requestGeneratorStore = RequestGeneratorStore(
            strategies: strategyFactory.strategies,
            apiVersion: .init(rawValue: Int32(backendMetadata.apiVersion.rawValue))
        )
        let operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )
        let contextStorage = LAContextStorage()
        let earService = EARService(
            accountID: accountID,
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext
            ],
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: contextStorage)
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
        let mlsService = MLSService(
            context: coreDataStack.syncContext,
            notificationContext: coreDataStack.syncContext.notificationContext,
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: LegacyFeatureRepository(context: coreDataStack.syncContext),
            userDefaults: .standard,
            userID: accountID,
            localDomain: backendMetadata.domain
        )
        let cookieStorage = CookieStorage(
            userID: accountID,
            cookieEncryptionKey: UserDefaults.cookiesKey(),
            keychain: Keychain()
        )
        let userSessionComponent = UserSessionComponent(
            currentBuildNumber: buildNumber,
            selfUserID: accountID,
            cookieStorage: cookieStorage,
            restNetworkService: restNetworkService,
            websocketNetworkService: webSocketNetworkService,
            blacklistNetworkService: blacklistNetworkService,
            backendMetaData: backendMetadata,
            isMLSEnabled: journal[.isBackendMLSEnabled],
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: nil, // the container is not used in this case
            syncContext: coreDataStack.syncContext,
            eventContext: coreDataStack.eventContext,
            mlsService: mlsService,
            // TODO: check why does the sharing session needs mlsService, shouldn't it be just the encryption part
            proteusService: proteusService,
            coreCryptoProvider: coreCryptoProvider,
            faultyMLSRemovalKeysByDomain: [:] // not relevant
        )
        let completionHandlers = ClientSessionComponent.CompletionHandlers(
            onProcessedCallEvent: { _ in },
            onSelfClientInvalidated: {},
            onAuthenticationFailure: {},
            onProcessedTypingUsers: { _ in }
        )
        let clientUserSessionComponent = userSessionComponent.clientSessionComponent(
            clientID: selfClientID,
            completionHandlers: completionHandlers
        )
        coreCryptoProvider.registerMlsTransport(clientUserSessionComponent.mlsTransport)
        return try await SharingSession(
            accountIdentifier: accountID,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            analyticsEventPersistence: analyticsEventPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory,
            appLockConfig: nil,
            earService: earService,
            contextStorage: contextStorage,
            proteusService: proteusService,
            mlsService: mlsService,
            mlsDecryptionService: mlsDecryptionService,
            sharedUserDefaults: sharedUserDefaults
        )
    }
}

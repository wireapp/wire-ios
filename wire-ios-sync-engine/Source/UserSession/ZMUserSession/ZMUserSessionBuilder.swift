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
import WireLogging
import WireNetwork
import WireRequestStrategy
import WireUtilities

@available(*, deprecated, message: "See UserSessionLoader instead.")
struct ZMUserSessionBuilder {

    // MARK: - Properties

    private var backendEnvironment: WireTransport.BackendEnvironment?
    private var wireAPIBackendEnvironment: WireNetwork.BackendEnvironment?
    private var currentAppVersion: String?
    private var currentBuildNumber: String?
    private var appLock: (any AppLockType)?
    private var application: (any ZMApplication)?
    private var applicationStatusDirectory: ApplicationStatusDirectory?
    private var contextStorage: (any LAContextStorable)?
    private var coreCryptoProvider: (any CoreCryptoProviderProtocol)?
    private var coreDataStack: CoreDataStack?
    private var dependencies: UserSessionDependencies?
    private var e2eiActivationDateRepository: (any E2EIActivationDateRepositoryProtocol)?
    private var earService: (any EARServiceInterface)?
    private var flowManager: (any FlowManagerType)?
    private var lastE2EIUpdateDateRepository: (any LastE2EIdentityUpdateDateRepositoryInterface)?
    private var lastEventIDRepository: (any LastEventIDRepositoryInterface)?
    private var mediaManager: (any MediaManagerType)?
    private var mlsService: (any MLSServiceInterface)?
    private var proteusToMLSMigrationCoordinator: (any ProteusToMLSMigrationCoordinating)?
    private var recurringActionService: (any RecurringActionServiceInterface)?
    private var sharedUserDefaults: UserDefaults?
    private var sharedContainerURL: URL?
    private var transportSession: (any TransportSessionType)?
    private var userId: UUID?
    private var minTLSVersion: String?
    private var apiVersion: WireNetwork.APIVersion?
    private var journal: Journal?
    private var logFilesProvider: LogFilesProviding?
    private var faultyMLSRemovalKeysByDomain: [String: [String]]?

    // MARK: - Initialize

    init() {}

    // MARK: - Build

    func build() -> ZMUserSession {
        guard
            let currentAppVersion,
            let currentBuildNumber,
            let appLock,
            let application,
            let applicationStatusDirectory,
            let contextStorage,
            let coreCryptoProvider,
            let coreDataStack,
            let e2eiActivationDateRepository,
            let dependencies,
            let earService,
            let flowManager,
            let lastE2EIUpdateDateRepository,
            let lastEventIDRepository,
            let mediaManager,
            let mlsService,
            let proteusToMLSMigrationCoordinator,
            let recurringActionService,
            let sharedUserDefaults,
            let sharedContainerURL,
            let transportSession,
            let userId,
            let wireAPIBackendEnvironment,
            let apiVersion,
            let journal,
            let logFilesProvider
        else {
            fatalError("cannot build 'ZMUserSession' without required dependencies")
        }

        let keychain = WireFoundation.Keychain()
        let cookieStorage = CookieStorage(
            userID: userId,
            cookieEncryptionKey: UserDefaults.cookiesKey(),
            keychain: keychain
        )

        let serverTrustValidator = ServerTrustValidator(
            pinnedKeys: wireAPIBackendEnvironment.pinnedKeys,
            currentDateProvider: .system
        )

        let urlSessionConfigurationFactory = URLSessionConfigurationFactory(
            minTLSVersion: .minVersionFrom(minTLSVersion),
            proxySettings: wireAPIBackendEnvironment.proxySettings
        )

        let restNetworkService = NetworkService(
            baseURL: wireAPIBackendEnvironment.url,
            serverTrustValidator: serverTrustValidator
        )
        let restConfig = urlSessionConfigurationFactory.makeRESTAPISessionConfiguration()
        let restSession = URLSession(
            configuration: restConfig,
            delegate: restNetworkService,
            delegateQueue: nil
        )
        restNetworkService.configure(with: restSession)

        let webSocketNetworkService = NetworkService(
            baseURL: wireAPIBackendEnvironment.webSocketURL,
            serverTrustValidator: serverTrustValidator
        )
        let webSocketConfig = urlSessionConfigurationFactory.makeWebSocketSessionConfiguration()
        let webSocketSession = URLSession(
            configuration: webSocketConfig,
            delegate: webSocketNetworkService,
            delegateQueue: nil
        )
        webSocketNetworkService.configure(with: webSocketSession)

        let blacklistNetworkService = NetworkService(
            baseURL: wireAPIBackendEnvironment.blacklistURL,
            serverTrustValidator: serverTrustValidator
        )
        let blacklistConfig = urlSessionConfigurationFactory.makeBlacklistSessionConfiguration()
        let blacklistSession = URLSession(
            configuration: blacklistConfig,
            delegate: blacklistNetworkService,
            delegateQueue: nil
        )
        blacklistNetworkService.configure(with: blacklistSession)

        let backendMetadata = ResolvedBackendMetadata(
            apiVersion: .init(rawValue: UInt(apiVersion.rawValue))!,
            domain: BackendInfo.domain!,
            isFederationEnabled: BackendInfo.isFederationEnabled
        )

        return ZMUserSession(
            userId: userId,
            restNetworkService: restNetworkService,
            websocketNetworkService: webSocketNetworkService,
            blacklistNetworkService: blacklistNetworkService,
            backendMetadata: backendMetadata,
            transportSession: transportSession,
            mediaManager: mediaManager,
            flowManager: flowManager,
            application: application,
            currentAppVersion: currentAppVersion,
            currentBuildNumber: currentBuildNumber,
            coreDataStack: coreDataStack,
            earService: earService,
            mlsService: mlsService,
            proteusToMLSMigrationCoordinator: proteusToMLSMigrationCoordinator,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: sharedContainerURL,
            appLock: appLock,
            coreCryptoProvider: coreCryptoProvider,
            lastEventIDRepository: lastEventIDRepository,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository,
            e2eiActivationDateRepository: e2eiActivationDateRepository,
            applicationStatusDirectory: applicationStatusDirectory,
            contextStorage: contextStorage,
            recurringActionService: recurringActionService,
            dependencies: dependencies,
            journal: journal,
            logFilesProvider: logFilesProvider,
            cookieStorage: cookieStorage,
            faultyMLSRemovalKeysByDomain: faultyMLSRemovalKeysByDomain ?? [:]
        )
    }

    // MARK: - Setup Dependencies

    mutating func withAllDependencies(
        backendEnvironment: WireTransport.BackendEnvironment,
        wireAPIBackendEnvironment: WireNetwork.BackendEnvironment,
        currentAppVersion: String,
        currentBuildNumber: String,
        application: any ZMApplication,
        coreDataStack: CoreDataStack,
        coreCryptoProvider: CoreCryptoProviderProtocol,
        configuration: ZMUserSession.Configuration,
        contextStorage: any LAContextStorable,
        earService: (any EARServiceInterface)?,
        flowManager: any FlowManagerType,
        mediaManager: any MediaManagerType,
        mlsService: (any MLSServiceInterface)?,
        proteusToMLSMigrationCoordinator: (any ProteusToMLSMigrationCoordinating)?,
        recurringActionService: (any RecurringActionServiceInterface)?,
        sharedUserDefaults: UserDefaults,
        sharedContainerURL: URL,
        transportSession: any TransportSessionType,
        userId: UUID,
        minTLSVersion: String?,
        journal: Journal,
        logFilesProvider: LogFilesProviding,
        faultyMLSRemovalKeysByDomain: [String: [String]]
    ) {
        // reused dependencies

        let lastEventIDRepository = LastEventIDRepository(
            userID: userId,
            sharedUserDefaults: sharedUserDefaults
        )

        // other dependencies

        let selfUser = ZMUser.selfUser(in: coreDataStack.viewContext)

        let appLock = AppLockController(
            userId: userId,
            selfUser: selfUser,
            legacyConfig: configuration.appLockConfig,
            authenticationContext: AuthenticationContext(storage: contextStorage)
        )
        let applicationStatusDirectory = ApplicationStatusDirectory(
            withManagedObjectContext: coreDataStack.syncContext,
            cookieStorage: transportSession.cookieStorage,
            requestCancellation: transportSession,
            application: application,
            coreCryptoProvider: coreCryptoProvider,
            isSyncV2Enabled: journal[.isSyncV2Enabled],
            localDomain: BackendInfo.domain,
            isBackendMLSEnabled: BackendInfo.isMLSEnabled
        )
        let e2eiActivationDateRepository = E2EIActivationDateRepository(
            userID: userId,
            sharedUserDefaults: sharedUserDefaults
        )
        let earService = earService ?? EARService(
            accountID: coreDataStack.account.userIdentifier,
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext
            ],
            coreDataStack: coreDataStack,
            canPerformKeyMigration: true,
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: contextStorage)
        )
        let lastE2EIdentityUpdateDateRepository = LastE2EIdentityUpdateDateRepository(
            userID: userId,
            sharedUserDefaults: UserDefaults.standard
        )
        let mlsService = mlsService ?? MLSService(
            context: coreDataStack.syncContext,
            notificationContext: coreDataStack.syncContext.notificationContext,
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: LegacyFeatureRepository(context: coreDataStack.syncContext),
            userDefaults: .standard,
            userID: coreDataStack.account.userIdentifier,
            localDomain: BackendInfo.domain
        )
        let proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator ?? ProteusToMLSMigrationCoordinator(
            context: coreDataStack.syncContext,
            userID: userId,
            apiVersion: BackendInfo.apiVersion
        )
        let recurringActionService = recurringActionService ?? RecurringActionService(
            storage: sharedUserDefaults,
            dateProvider: .system
        )

        if
            let wireTransportAPIVersion = WireTransport.BackendInfo.apiVersion,
            let apiVersion = WireNetwork.APIVersion(rawValue: UInt(wireTransportAPIVersion.rawValue)) {
            self.apiVersion = apiVersion
        }

        // setup builder

        self.currentAppVersion = currentAppVersion
        self.currentBuildNumber = currentBuildNumber
        self.appLock = appLock
        self.application = application
        self.applicationStatusDirectory = applicationStatusDirectory
        self.contextStorage = contextStorage
        self.coreCryptoProvider = coreCryptoProvider
        self.coreDataStack = coreDataStack
        dependencies = buildUserSessionDependencies(coreDataStack: coreDataStack)
        self.e2eiActivationDateRepository = e2eiActivationDateRepository
        self.earService = earService
        self.flowManager = flowManager
        lastE2EIUpdateDateRepository = lastE2EIdentityUpdateDateRepository
        self.lastEventIDRepository = lastEventIDRepository
        self.mediaManager = mediaManager
        self.mlsService = mlsService
        self.proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator
        self.recurringActionService = recurringActionService
        self.sharedUserDefaults = sharedUserDefaults
        self.sharedContainerURL = sharedContainerURL
        self.transportSession = transportSession
        self.userId = userId
        self.minTLSVersion = minTLSVersion
        self.wireAPIBackendEnvironment = wireAPIBackendEnvironment
        self.journal = journal
        self.logFilesProvider = logFilesProvider
        self.faultyMLSRemovalKeysByDomain = faultyMLSRemovalKeysByDomain
    }

    // MARK: UserSesssionDependencies

    private func buildUserSessionDependencies(coreDataStack: CoreDataStack) -> UserSessionDependencies {
        UserSessionDependencies(
            caches: buildCaches(coreDataStack: coreDataStack)
        )
    }

    private func buildCaches(coreDataStack: CoreDataStack) -> UserSessionDependencies.Caches {
        let cacheLocation = FileManager.default.cachesURLForAccount(
            with: coreDataStack.account.userIdentifier,
            in: coreDataStack.applicationContainer
        )

        let relocator = CacheFileRelocator()
        relocator.moveCachesIfNeededForAccount(
            with: coreDataStack.account.userIdentifier,
            in: coreDataStack.applicationContainer
        )

        return UserSessionDependencies.Caches(
            fileAssets: FileAssetCache(location: cacheLocation),
            userImages: UserImageLocalCache(location: cacheLocation),
            searchUsers: NSCache()
        )
    }
}

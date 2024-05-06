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
import WireDataModel
import WireRequestStrategy
import WireUtilities

struct ZMUserSessionBuilder {

    // MARK: - Properties

    private var analytics: (any AnalyticsType)?
    private var appVersion: String?
    private var appLock: (any AppLockType)?
    private var application: (any ZMApplication)?
    private var applicationStatusDirectory: ApplicationStatusDirectory?
    private var contextStorage: (any LAContextStorable)?
    private var coreCryptoProvider: (any CoreCryptoProviderProtocol)?
    private var coreDataStack: CoreDataStack?
    private var cryptoboxMigrationManager: (any CryptoboxMigrationManagerInterface)?
    private var dependencies: UserSessionDependencies?
    private var e2eiActivationDateRepository: (any E2EIActivationDateRepositoryProtocol)?
    private var earService: (any EARServiceInterface)?
    private var flowManager: (any FlowManagerType)?
    private var lastE2EIUpdateDateRepository: (any LastE2EIdentityUpdateDateRepositoryInterface)?
    private var lastEventIDRepository: (any LastEventIDRepositoryInterface)?
    private var mediaManager: (any MediaManagerType)?
    private var mlsConversationVerificationStatusUpdater: (any MLSConversationVerificationStatusUpdating)?
    private var mlsService: (any MLSServiceInterface)?
    private var observeMLSGroupVerificationStatusUseCase: (any ObserveMLSGroupVerificationStatusUseCaseProtocol)?
    private var proteusToMLSMigrationCoordinator: (any ProteusToMLSMigrationCoordinating)?
    private var recurringActionService: (any RecurringActionServiceInterface)?
    private var sharedUserDefaults: UserDefaults?
    private var transportSession: (any TransportSessionType)?
    private var updateMLSGroupVerificationStatusUseCase: (any UpdateMLSGroupVerificationStatusUseCaseProtocol)?
    private var useCaseFactory: (any UseCaseFactoryProtocol)?
    private var userId: UUID?

    // MARK: - Initialize

    init() { }

    // MARK: - Build

    func build() -> ZMUserSession {
        guard
            let appVersion,
            let appLock,
            let application,
            let applicationStatusDirectory,
            let contextStorage,
            let coreCryptoProvider,
            let coreDataStack,
            let cryptoboxMigrationManager,
            let e2eiActivationDateRepository,
            let dependencies,
            let earService,
            let flowManager,
            let lastE2EIUpdateDateRepository,
            let lastEventIDRepository,
            let mediaManager,
            let mlsConversationVerificationStatusUpdater,
            let mlsService,
            let observeMLSGroupVerificationStatusUseCase,
            let proteusToMLSMigrationCoordinator,
            let recurringActionService,
            let sharedUserDefaults,
            let transportSession,
            let updateMLSGroupVerificationStatusUseCase,
            let useCaseFactory,
            let userId
        else {
            fatalError("cannot build 'ZMUserSession' without required dependencies")
        }

        return ZMUserSession(
            userId: userId,
            transportSession: transportSession,
            mediaManager: mediaManager,
            flowManager: flowManager,
            analytics: analytics,
            application: application,
            appVersion: appVersion,
            coreDataStack: coreDataStack,
            earService: earService,
            mlsService: mlsService,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            proteusToMLSMigrationCoordinator: proteusToMLSMigrationCoordinator,
            sharedUserDefaults: sharedUserDefaults,
            useCaseFactory: useCaseFactory,
            observeMLSGroupVerificationStatusUseCase: observeMLSGroupVerificationStatusUseCase,
            appLock: appLock,
            coreCryptoProvider: coreCryptoProvider,
            lastEventIDRepository: lastEventIDRepository,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository,
            e2eiActivationDateRepository: e2eiActivationDateRepository,
            applicationStatusDirectory: applicationStatusDirectory,
            updateMLSGroupVerificationStatusUseCase: updateMLSGroupVerificationStatusUseCase,
            mlsConversationVerificationStatusUpdater: mlsConversationVerificationStatusUpdater,
            contextStorage: contextStorage,
            recurringActionService: recurringActionService,
            dependencies: dependencies
        )
    }

    // MARK: - Setup Dependencies

    mutating func withAllDependencies(
        analytics: (any AnalyticsType)?,
        appVersion: String,
        application: any ZMApplication,
        cryptoboxMigrationManager: any CryptoboxMigrationManagerInterface,
        coreDataStack: CoreDataStack,
        configuration: ZMUserSession.Configuration,
        contextStorage: any LAContextStorable,
        earService: (any EARServiceInterface)?,
        flowManager: any FlowManagerType,
        mediaManager: any MediaManagerType,
        mlsService: (any MLSServiceInterface)?,
        observeMLSGroupVerificationStatus: (any ObserveMLSGroupVerificationStatusUseCaseProtocol)?,
        proteusToMLSMigrationCoordinator: (any ProteusToMLSMigrationCoordinating)?,
        recurringActionService: (any RecurringActionServiceInterface)?,
        sharedUserDefaults: UserDefaults,
        transportSession: any TransportSessionType,
        useCaseFactory: (any UseCaseFactoryProtocol)?,
        userId: UUID
    ) {
        // reused dependencies

        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: userId,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: coreDataStack.accountContainer,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: cryptoboxMigrationManager
        )
        let e2eiVerificationStatusService = E2EIVerificationStatusService(coreCryptoProvider: coreCryptoProvider)
        let lastEventIDRepository = LastEventIDRepository(
            userID: userId,
            sharedUserDefaults: sharedUserDefaults
        )
        let updateMLSGroupVerificationStatus = UpdateMLSGroupVerificationStatusUseCase(
            e2eIVerificationStatusService: e2eiVerificationStatusService,
            context: coreDataStack.syncContext,
            featureRepository: FeatureRepository(context: coreDataStack.syncContext)
        )

        // other dependencies

        let appLock = AppLockController(
            userId: userId,
            selfUser: .selfUser(in: coreDataStack.viewContext),
            legacyConfig: configuration.appLockConfig,
            authenticationContext: AuthenticationContext(storage: contextStorage)
        )
        let applicationStatusDirectory = ApplicationStatusDirectory(
            withManagedObjectContext: coreDataStack.syncContext,
            cookieStorage: transportSession.cookieStorage,
            requestCancellation: transportSession,
            application: application,
            lastEventIDRepository: lastEventIDRepository,
            coreCryptoProvider: coreCryptoProvider,
            analytics: analytics
        )
        let e2eiActivationDateRepository = E2EIActivationDateRepository(
            userID: userId,
            sharedUserDefaults: sharedUserDefaults
        )
        let earService = earService ?? EARService(
            accountID: coreDataStack.account.userIdentifier,
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
            userID: userId,
            sharedUserDefaults: UserDefaults.standard
        )
        let mlsConversationVerificationStatusUpdater = MLSConversationVerificationStatusUpdater(
            updateMLSGroupVerificationStatus: updateMLSGroupVerificationStatus,
            syncContext: coreDataStack.syncContext
        )
        let mlsService = mlsService ?? MLSService(
            context: coreDataStack.syncContext,
            coreCryptoProvider: coreCryptoProvider,
            conversationEventProcessor: ConversationEventProcessor(context: coreDataStack.syncContext),
            featureRepository: FeatureRepository(context: coreDataStack.syncContext),
            userDefaults: .standard,
            syncStatus: applicationStatusDirectory.syncStatus,
            userID: coreDataStack.account.userIdentifier
        )
        let observeMLSGroupVerificationStatusUseCase = observeMLSGroupVerificationStatus ?? ObserveMLSGroupVerificationStatusUseCase(
            mlsService: mlsService,
            updateMLSGroupVerificationStatusUseCase: updateMLSGroupVerificationStatus,
            syncContext: coreDataStack.syncContext
        )
        let proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator ?? ProteusToMLSMigrationCoordinator(
            context: coreDataStack.syncContext,
            userID: userId
        )
        let recurringActionService = recurringActionService ?? RecurringActionService(storage: sharedUserDefaults, dateProvider: .system)
        let useCaseFactory = useCaseFactory ?? UseCaseFactory(
            context: coreDataStack.syncContext,
            supportedProtocolService: SupportedProtocolsService(context: coreDataStack.syncContext),
            oneOnOneResolver: OneOnOneResolver(migrator: OneOnOneMigrator(mlsService: mlsService))
        )

        // setup builder

        self.analytics = analytics
        self.appVersion = appVersion
        self.appLock = appLock
        self.application = application
        self.applicationStatusDirectory = applicationStatusDirectory
        self.contextStorage = contextStorage
        self.coreCryptoProvider = coreCryptoProvider
        self.coreDataStack = coreDataStack
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
        self.dependencies = buildUserSessionDependencies(coreDataStack: coreDataStack)
        self.e2eiActivationDateRepository = e2eiActivationDateRepository
        self.earService = earService
        self.flowManager = flowManager
        self.lastE2EIUpdateDateRepository = lastE2EIdentityUpdateDateRepository
        self.lastEventIDRepository = lastEventIDRepository
        self.mediaManager = mediaManager
        self.mlsConversationVerificationStatusUpdater = mlsConversationVerificationStatusUpdater
        self.mlsService = mlsService
        self.observeMLSGroupVerificationStatusUseCase = observeMLSGroupVerificationStatusUseCase
        self.proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator
        self.recurringActionService = recurringActionService
        self.sharedUserDefaults = sharedUserDefaults
        self.transportSession = transportSession
        self.updateMLSGroupVerificationStatusUseCase = updateMLSGroupVerificationStatus
        self.useCaseFactory = useCaseFactory
        self.userId = userId
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

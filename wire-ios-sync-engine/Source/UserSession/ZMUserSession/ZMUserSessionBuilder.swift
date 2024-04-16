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

struct ZMUserSessionBuilder {

    private var analytics: AnalyticsType?
    private var appVersion: String?
    private var appLock: (any AppLockType)?
    private var application: ZMApplication?
    private var applicationStatusDirectory: ApplicationStatusDirectory?
    private var configuration: ZMUserSession.Configuration?
    private var contextStorage: LAContextStorable?
    private var coreCryptoProvider: (any CoreCryptoProviderProtocol)?
    private var coreDataStack: CoreDataStack?
    private var cryptoboxMigrationManager: CryptoboxMigrationManagerInterface?
    private var debugCommands: [String: DebugCommand]?
    private var e2eiActivationDateRepository: (any E2EIActivationDateRepositoryProtocol)?
    private var earService: EARServiceInterface?
    private var flowManager: FlowManagerType?
    private var lastE2EIUpdateDateRepository: (any LastE2EIdentityUpdateDateRepositoryInterface)?
    private var lastEventIDRepository: (any LastEventIDRepositoryInterface)?
    private var mediaManager: MediaManagerType?
    private var mlsConversationVerificationStatusUpdater: (any MLSConversationVerificationStatusUpdating)?
    private var mlsService: MLSServiceInterface?
    private var observeMLSGroupVerificationStatusUseCase: ObserveMLSGroupVerificationStatusUseCaseProtocol?
    private var operationLoop: ZMOperationLoop?
    private var proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating?
    private var sharedUserDefaults: UserDefaults?
    private var strategyDirectory: StrategyDirectoryProtocol?
    private var syncStrategy: ZMSyncStrategy?
    private var transportSession: TransportSessionType?
    private var updateMLSGroupVerificationStatusUseCase: (any UpdateMLSGroupVerificationStatusUseCaseProtocol)?
    private var useCaseFactory: UseCaseFactoryProtocol?
    private var userId: UUID?

    // MARK: - Initialize

    init() { }

    // MARK: - Build

    func build() -> ZMUserSession {
        assert(appVersion != nil, "expected 'appVersion' to be set!)")
        assert(appLock != nil, "expected 'appLock' to be set!)")
        assert(application != nil, "expected 'application' to be set!)")
        assert(applicationStatusDirectory != nil, "expected 'applicationStatusDirectory' to be set!)")
        assert(configuration != nil, "expected 'configuration' to be set!)")
        assert(contextStorage != nil, "expected 'contextStorage' to be set!)")
        assert(coreCryptoProvider != nil, "expected 'coreCryptoProvider' to be set!)")
        assert(coreDataStack != nil, "expected 'coreDataStack' to be set!)")
        assert(cryptoboxMigrationManager != nil, "expected 'cryptoboxMigrationManager' to be set!)")
        assert(debugCommands != nil, "expected 'debugCommands' to be set!)")
        assert(e2eiActivationDateRepository != nil, "expected 'e2eiActivationDateRepository' to be set!)")
        assert(earService != nil, "expected 'earService' to be set!)")
        assert(flowManager != nil, "expected 'flowManager' to be set!)")
        assert(lastE2EIUpdateDateRepository != nil, "expected 'lastE2EIUpdateDateRepository' to be set!)")
        assert(lastEventIDRepository != nil, "expected 'lastEventIDRepository' to be set!)")
        assert(mediaManager != nil, "expected 'mediaManager' to be set!)")
        assert(mlsConversationVerificationStatusUpdater != nil, "expected 'mlsConversationVerificationStatusUpdater' to be set!)")
        assert(mlsService != nil, "expected 'mlsService' to be set!)")
        assert(observeMLSGroupVerificationStatusUseCase != nil, "expected 'observeMLSGroupVerificationStatusUseCase' to be set!)")
        assert(operationLoop != nil, "expected 'operationLoop' to be set!)")
        assert(proteusToMLSMigrationCoordinator != nil, "expected 'proteusToMLSMigrationCoordinator' to be set!)")
        assert(sharedUserDefaults != nil, "expected 'sharedUserDefaults' to be set!)")
        assert(strategyDirectory != nil, "expected 'strategyDirectory' to be set!)")
        assert(syncStrategy != nil, "expected 'syncStrategy' to be set!)")
        assert(transportSession != nil, "expected 'transportSession' to be set!)")
        assert(updateMLSGroupVerificationStatusUseCase != nil, "expected 'updateMLSGroupVerificationStatusUseCase' to be set!)")
        assert(useCaseFactory != nil, "expected 'useCaseFactory' to be set!)")
        assert(userId != nil, "expected 'userId' to be set!)")

        // TODO: should core data preperation happen somewhere else?
        let coreDataStack = coreDataStack!
        coreDataStack.syncContext.performGroupedBlockAndWait {
            coreDataStack.syncContext.analytics = analytics
            coreDataStack.syncContext.zm_userInterface = coreDataStack.viewContext
        }
        coreDataStack.viewContext.zm_sync = coreDataStack.syncContext

        let userSession = ZMUserSession(
            userId: userId!,
            transportSession: transportSession!,
            mediaManager: mediaManager!,
            flowManager: flowManager!,
            analytics: analytics,
            application: application!,
            appVersion: appVersion!,
            coreDataStack: coreDataStack,
            earService: earService!,
            mlsService: mlsService!,
            cryptoboxMigrationManager: cryptoboxMigrationManager!,
            proteusToMLSMigrationCoordinator: proteusToMLSMigrationCoordinator!,
            sharedUserDefaults: sharedUserDefaults!,
            useCaseFactory: useCaseFactory!,
            observeMLSGroupVerificationStatusUseCase: observeMLSGroupVerificationStatusUseCase!,
            debugCommands: debugCommands!,
            appLock: appLock!,
            coreCryptoProvider: coreCryptoProvider!,
            lastEventIDRepository: lastEventIDRepository!,
            lastE2EIUpdateDateRepository: lastE2EIUpdateDateRepository!,
            e2eiActivationDateRepository: e2eiActivationDateRepository!,
            applicationStatusDirectory: applicationStatusDirectory!,
            updateMLSGroupVerificationStatusUseCase: updateMLSGroupVerificationStatusUseCase!,
            mlsConversationVerificationStatusUpdater: mlsConversationVerificationStatusUpdater!,
            contextStorage: contextStorage!
        )

//        let cacheLocation = FileManager.default.cachesURLForAccount(with: coreDataStack.account.userIdentifier, in: coreDataStack.applicationContainer)
//        ZMUserSession.moveCachesIfNeededForAccount(with: coreDataStack.account.userIdentifier, in: coreDataStack.applicationContainer)
//
//        let assetCache = FileAssetCache(location: cacheLocation)
//
//        userSession.setup(
//            eventProcessor: T##(any UpdateEventProcessor)?,
//            strategyDirectory: T##(any StrategyDirectoryProtocol)?,
//            syncStrategy: T##ZMSyncStrategy?,
//            operationLoop: T##ZMOperationLoop?,
//            fileAssetCache: T##FileAssetCache,
//            userImageLocalCache: T##UserImageLocalCache,
//            configuration: T##ZMUserSession.Configuration
//        )

        return userSession
    }

    // MARK: - Setup Dependencies

    mutating func withAllDependencies(
        analytics: AnalyticsType?,
        appVersion: String,
        application: ZMApplication,
        cryptoboxMigrationManager: CryptoboxMigrationManagerInterface,
        coreDataStack: CoreDataStack,
        configuration: ZMUserSession.Configuration,
        contextStorage: LAContextStorable,
        earService: EARServiceInterface?,
        flowManager: FlowManagerType,
        mediaManager: MediaManagerType,
        mlsService: MLSServiceInterface?,
        observeMLSGroupVerificationStatus: ObserveMLSGroupVerificationStatusUseCaseProtocol?,
        operationLoop: ZMOperationLoop?,
        proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating?,
        sharedUserDefaults: UserDefaults,
        strategyDirectory: StrategyDirectoryProtocol?,
        syncStrategy: ZMSyncStrategy?,
        transportSession: TransportSessionType,
        useCaseFactory: UseCaseFactoryProtocol?,
        userId: UUID
    ) {

        // first reused dependencies

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

        // second other dependencies

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
        let useCaseFactory = useCaseFactory ?? UseCaseFactory(
            context: coreDataStack.syncContext,
            supportedProtocolService: SupportedProtocolsService(context: coreDataStack.syncContext),
            oneOnOneResolver: OneOnOneResolver(migrator: OneOnOneMigrator(mlsService: mlsService))
        )

        // third set all dependencies

        withAnalytics(analytics)
        withAppVersion(appVersion)
        withAppLock(appLock)
        withApplication(application)
        withApplicationStatusDirectory(applicationStatusDirectory)
        withConfiguration(configuration)
        withContextStorage(contextStorage)
        withCoreCryptoProvider(coreCryptoProvider)
        withCoreDataStack(coreDataStack)
        withCryptoboxMigrationManager(cryptoboxMigrationManager)
        withDebugCommands(ZMUserSession.initDebugCommands())
        withE2EIActivationDateRepository(e2eiActivationDateRepository)
        withEARService(earService)
        withFlowManager(flowManager)
        withLastE2EIUpdateDateRepository(lastE2EIdentityUpdateDateRepository)
        withLastEventIDRepository(lastEventIDRepository)
        withMediaManager(mediaManager)
        withMLSConversationVerificationStatusUpdater(mlsConversationVerificationStatusUpdater)
        withMLSService(mlsService)
        withObserveMLSGroupVerificationStatusUseCase(observeMLSGroupVerificationStatusUseCase)
        withProteusToMLSMigrationCoordinator(proteusToMLSMigrationCoordinator)
        withSharedUserDefaults(sharedUserDefaults)
        withTransportSession(transportSession)
        withUpdateMLSGroupVerificationStatusUseCase(updateMLSGroupVerificationStatus)
        withUseCaseFactory(useCaseFactory)
        withUserID(userId)

        // builder = eventFactory
        // builder = withOperationLoop(operationLoop)
        // builder = withStrategyDirectory(strategyDirectory)
        // builder = withSyncStrategy(syncStrategy: syncStrategy)
    }

    mutating func withAnalytics(_ analytics: (any AnalyticsType)?) {
        self.analytics = analytics
    }

    mutating func withAppVersion(_ appVersion: String) {
        self.appVersion = appVersion
    }

    mutating func withAppLock(_ appLock: any AppLockType) {
        self.appLock = appLock
    }

    mutating func withApplication(_ application: ZMApplication) {
        self.application = application
    }

    mutating func withApplicationStatusDirectory(_ applicationStatusDirectory: ApplicationStatusDirectory) {
        self.applicationStatusDirectory = applicationStatusDirectory
    }

    mutating func withConfiguration(_ configuration: ZMUserSession.Configuration) {
        self.configuration = configuration
    }

    mutating func withContextStorage(_ contextStorage: LAContextStorable) {
        self.contextStorage = contextStorage
    }

    mutating func withCoreCryptoProvider(_ coreCryptoProvider: any CoreCryptoProviderProtocol) {
        self.coreCryptoProvider = coreCryptoProvider
    }

    mutating func withCoreDataStack(_ coreDataStack: CoreDataStack) {
        self.coreDataStack = coreDataStack
    }

    mutating func withCryptoboxMigrationManager(_ cryptoboxMigrationManager: CryptoboxMigrationManagerInterface) {
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
    }

    mutating func withE2EIActivationDateRepository(_ e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol) {
        self.e2eiActivationDateRepository = e2eiActivationDateRepository
    }

    mutating func withDebugCommands(_ debugCommands: [String: DebugCommand]) {
        self.debugCommands = debugCommands
    }

    mutating func withEARService(_ earService: EARServiceInterface) {
        self.earService = earService
    }

    mutating func withFlowManager(_ flowManager: FlowManagerType) {
        self.flowManager = flowManager
    }

    mutating func withLastE2EIUpdateDateRepository(_ lastE2EIUpdateDateRepository: any LastE2EIdentityUpdateDateRepositoryInterface) {
        self.lastE2EIUpdateDateRepository = lastE2EIUpdateDateRepository
    }

    mutating func withLastEventIDRepository(_ lastEventIDRepository: any LastEventIDRepositoryInterface) {
        self.lastEventIDRepository = lastEventIDRepository
    }

    mutating func withMediaManager(_ mediaManager: MediaManagerType) {
        self.mediaManager = mediaManager
    }

    mutating func withMLSConversationVerificationStatusUpdater(_ mlsConversationVerificationStatusUpdater: any MLSConversationVerificationStatusUpdating) {
        self.mlsConversationVerificationStatusUpdater = mlsConversationVerificationStatusUpdater
    }

    mutating func withMLSService(_ mlsService: MLSServiceInterface) {
        self.mlsService = mlsService
    }

    mutating func withObserveMLSGroupVerificationStatusUseCase(_ observeMLSGroupVerificationStatusUseCase: ObserveMLSGroupVerificationStatusUseCaseProtocol) {
        self.observeMLSGroupVerificationStatusUseCase = observeMLSGroupVerificationStatusUseCase
    }

    mutating func withOperationLoop(_ operationLoop: ZMOperationLoop) {
        self.operationLoop = operationLoop
    }

    mutating func withProteusToMLSMigrationCoordinator(_ proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating) {
        self.proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator
    }

    mutating func withSharedUserDefaults(_ sharedUserDefaults: UserDefaults) {
        self.sharedUserDefaults = sharedUserDefaults
    }

    mutating func withStrategyDirectory(_ strategyDirectory: StrategyDirectoryProtocol) {
        self.strategyDirectory = strategyDirectory
    }

    mutating func withSyncStrategy(syncStrategy: ZMSyncStrategy) {
        self.syncStrategy = syncStrategy
    }

    mutating func withTransportSession(_ transportSession: TransportSessionType) {
        self.transportSession = transportSession
    }

    mutating func withUpdateMLSGroupVerificationStatusUseCase(_ updateMLSGroupVerificationStatusUseCase: any UpdateMLSGroupVerificationStatusUseCaseProtocol) {
        self.updateMLSGroupVerificationStatusUseCase = updateMLSGroupVerificationStatusUseCase
    }

    mutating func withUseCaseFactory(_ useCaseFactory: UseCaseFactoryProtocol) {
        self.useCaseFactory = useCaseFactory
    }

    mutating func withUserID(_ userId: UUID) {
        self.userId = userId
    }
}

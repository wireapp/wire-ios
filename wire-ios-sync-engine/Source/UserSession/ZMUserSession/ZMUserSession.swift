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

public import WireFoundation

import Combine
import Foundation
import WireCoreCrypto
import WireDataModel
import WireDomain
import WireLogging
import WireNetwork
import WireRequestStrategy
import WireSystem

protocol UserSessionDelegate: AnyObject, UserSessionAppLockDelegate, UserSessionEncryptionAtRestDelegate,
    UserSessionLogoutDelegate, UserSessionSelfUserClientDelegate {

    func userSessionDidDiscoverBuildIsBlacklisted()

}

enum ZMUserSessionError: Error {
    case selfClientNotReady
}

@objcMembers
public final class ZMUserSession: NSObject {

    // MARK: Properties

    private let currentAppVersion: String
    private let currentBuildNumber: String
    public internal(set) var isBuildBlacklisted = false
    private var tokens: [Any] = []
    public private(set) var isTornDown = false

    private(set) var isNetworkOnline = true

    public private(set) var coreDataStack: CoreDataStack!

    let application: ZMApplication
    let flowManager: FlowManagerType
    private(set) var mediaManager: MediaManagerType
    public private(set) var transportSession: TransportSessionType
    let storedDidSaveNotifications: ContextDidSaveNotificationPersistence
    let userExpirationObserver: UserExpirationObserver
    private(set) var legacyUpdateEventProcessor: UpdateEventProcessor?
    private(set) var strategyDirectory: StrategyDirectoryProtocol?
    private(set) var syncStrategy: ZMSyncStrategy?
    private(set) var operationLoop: ZMOperationLoop?
    private(set) var notificationDispatcher: NotificationDispatcher
    private(set) var localNotificationDispatcher: LocalNotificationDispatcher?
    let applicationStatusDirectory: ApplicationStatusDirectory
    private(set) var callStateObserver: CallStateObserver?
    var messageReplyObserver: ManagedObjectContextChangeObserver?
    var likeMesssageObserver: ManagedObjectContextChangeObserver?
    private(set) var urlActionProcessors: [URLActionProcessor]?
    let debugCommands: [String: DebugCommand]
    let eventProcessingTracker: EventProcessingTracker = .init()

    var accessTokenRenewalObserver: AccessTokenRenewalObserver?

    var recurringActionService: any RecurringActionServiceInterface

    var cryptoboxMigrationManager: CryptoboxMigrationManagerInterface
    private(set) var coreCryptoProvider: CoreCryptoProviderProtocol
    private(set) var userId: UUID
    let proteusService: ProteusServiceInterface
    private(set) var mlsService: MLSServiceInterface
    private(set) var proteusProvider: ProteusProviding!
    let proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating

    public lazy var featureRepository = LegacyFeatureRepository(context: syncContext)

    let earService: EARServiceInterface

    public private(set) weak var analyticsEventTracker: (any AnalyticsEventTrackerProtocol)?
    private var pendingAnalyticsEvents = [AnalyticsEvent]()

    public internal(set) var appLockController: AppLockType
    private let contextStorage: LAContextStorable

    public let e2eiActivationDateRepository: E2EIActivationDateRepositoryProtocol

    let lastEventIDRepository: LastEventIDRepositoryInterface
    var conversationEventProcessor: ConversationEventProcessor!

    var syncAgent: SyncAgent?

    public var hasCompletedInitialSync: Bool {
        !journal[.isInitialSyncRequired]
    }

    public var topConversationsDirectory: TopConversationsDirectory

    public internal(set) var mlsGroupVerification: (any MLSGroupVerificationProtocol)?

    let analyiticsLogger: WireLogger
    let journal: Journal

    // MARK: Computed Properties

    public var isBackendMLSEnabled: Bool {
        if DeveloperFlag.multibackend.isOn {
            journal[.isBackendMLSEnabled]
        } else {
            BackendInfo.isMLSEnabled
        }
    }

    var isPerformingSync = true {
        willSet {
            notificationDispatcher.operationMode = newValue ? .economical : .normal
        }
    }

    public var syncStatus: SyncStatusProtocol {
        applicationStatusDirectory.syncStatus
    }

    public var fileSharingFeature: Feature.FileSharing {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchFileSharing()
    }

    public var selfDeletingMessagesFeature: Feature.SelfDeletingMessages {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchSelfDeletingMessages()
    }

    public var conversationGuestLinksFeature: Feature.ConversationGuestLinks {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchConversationGuestLinks()
    }

    public var classifiedDomainsFeature: Feature.ClassifiedDomains {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchClassifiedDomains()
    }

    public var e2eiFeature: Feature.E2EI {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchE2EI()
    }

    public var mlsFeature: Feature.MLS {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchMLS()
    }

    public var channelsFeature: Feature.Channels {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchChannels()
    }

    public var chatBubbleSimpleFeature: Feature.ChatBubblesSimple {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchChatBubblesSimple()
    }

    public var isChatBubbleSimpleEnabled: Bool {
        chatBubbleSimpleFeature.status == .enabled || DeveloperFlag.chatBubblesSimple.isOn
    }

    public var wireCellsFeature: Feature.Cells {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchCells()
    }

    public var isWireCellsEnabled: Bool {
        wireCellsFeature.status == .enabled
    }

    public var conferenceCallingFeature: Feature.ConferenceCalling {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchConferenceCalling()
    }

    public var isEnterpriseUser: Bool {
        conferenceCallingFeature.status == .enabled || DeveloperFlag.channelsHistory.isOn
    }

    public var gracePeriodEndDate: Date? {
        guard
            e2eiFeature.isEnabled,
            let e2eiActivatedAt = e2eiActivationDateRepository.e2eiActivatedAt
        else {
            return nil
        }

        let gracePeriod = TimeInterval(e2eiFeature.config.verificationExpiration)
        return e2eiActivatedAt.addingTimeInterval(gracePeriod)
    }

    public lazy var selfClientCertificateProvider: SelfClientCertificateProviderProtocol =
        SelfClientCertificateProvider(
            getE2eIdentityCertificatesUseCase: getE2eIdentityCertificates,
            context: syncContext,
            localDomain: resolvedBackendMetadata.domain
        )

    public lazy var snoozeCertificateEnrollmentUseCase: SnoozeCertificateEnrollmentUseCaseProtocol =
        SnoozeCertificateEnrollmentUseCase(
            featureRepository: featureRepository,
            featureRepositoryContext: syncContext,
            recurringActionService: recurringActionService,
            accountId: account.userIdentifier
        )

    public lazy var stopCertificateEnrollmentSnoozerUseCase: StopCertificateEnrollmentSnoozerUseCaseProtocol =
        StopCertificateEnrollmentSnoozerUseCase(
            recurringActionService: recurringActionService,
            accountId: account.userIdentifier
        )

    var cRLsChecker: CertificateRevocationListsChecker?
    var cRLsDistributionPointsObserver: CRLsDistributionPointsObserver?

    // swiftlint:disable:next todo_requires_jira_link
    public var managedObjectContext: NSManagedObjectContext { // TODO: jacob we don't want this to be public
        coreDataStack.viewContext
    }

    // swiftlint:disable:next todo_requires_jira_link
    public var syncManagedObjectContext: NSManagedObjectContext { // TODO: jacob we don't want this to be public
        coreDataStack.syncContext
    }

    // swiftlint:disable:next todo_requires_jira_link
    public var searchManagedObjectContext: NSManagedObjectContext { // TODO: jacob we don't want this to be public
        coreDataStack.searchContext
    }

    // swiftlint:disable:next todo_requires_jira_link
    public var sharedContainerURL: URL { // TODO: jacob we don't want this to be public
        coreDataStack.applicationContainer
    }

    // swiftlint:disable:next todo_requires_jira_link
    public var selfUserClient: WireDataModel.UserClient? { // TODO: jacob we don't want this to be public
        ZMUser.selfUser(in: managedObjectContext).selfClient()
    }

    public var userProfile: UserProfile {
        applicationStatusDirectory.userProfileUpdateStatus
    }

    public var userProfileImage: UserProfileImageUpdateProtocol {
        applicationStatusDirectory.userProfileImageUpdateStatus
    }

    public var conversationDirectory: ConversationDirectoryType {
        managedObjectContext.conversationListDirectory()
    }

    // To prevent too eagerly resolving all conversations.
    var didAlreadyResolveAllOneOnOnes = false

    private lazy var networkStateSubject: CurrentValueSubject<NetworkState, Never> = {
        CurrentValueSubject<NetworkState, Never>(networkState)
    }()
    
    public private(set) var networkState: NetworkState = .online {
        didSet {
            if oldValue != networkState {
                ZMNetworkAvailabilityChangeNotification.notify(
                    networkState: networkState,
                    notificationContext: managedObjectContext.notificationContext
                )
            }
            networkStateSubject.send(networkState)
        }
    }

    public var isNotificationContentHidden: Bool {
        get {
            guard let value = managedObjectContext
                .persistentStoreMetadata(
                    forKey: LocalNotificationDispatcher
                        .ZMShouldHideNotificationContentKey
                ) as? NSNumber else {
                return false
            }

            return value.boolValue
        }
        set {
            managedObjectContext.setPersistentStoreMetadata(
                NSNumber(value: newValue),
                key: LocalNotificationDispatcher.ZMShouldHideNotificationContentKey
            )
        }
    }

    /// - Note: this is safe if coredataStack and proteus are ready
    public var getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol {
        GetUserClientFingerprintUseCase(
            syncContext: coreDataStack.syncContext,
            transportSession: transportSession,
            proteusProvider: proteusProvider,
            metadata: resolvedBackendMetadata
        )
    }

    lazy var e2eiRepository: E2EIRepositoryInterface = {
        let acmeDiscoveryPath = e2eiFeature.config.acmeDiscoveryUrl ?? ""
        let acmeApi = AcmeAPI(acmeDiscoveryPath: acmeDiscoveryPath)
        let httpClient = HttpClientImpl(
            transportSession: transportSession,
            queue: syncContext
        )

        let apiProvider = APIProvider(httpClient: httpClient)
        let e2eiSetupService = E2EISetupService(
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: featureRepository
        )
        let onNewCRLsDistributionPointsSubject = PassthroughSubject<CRLsDistributionPoints, Never>()

        let keyRotator = E2EIKeyPackageRotator(
            coreCryptoProvider: coreCryptoProvider,
            context: syncContext,
            onNewCRLsDistributionPointsSubject: onNewCRLsDistributionPointsSubject,
            featureRepository: featureRepository
        )

        let e2eiRepository = E2EIRepository(
            acmeApi: acmeApi,
            apiProvider: apiProvider,
            e2eiSetupService: e2eiSetupService,
            keyRotator: keyRotator,
            coreCryptoProvider: coreCryptoProvider,
            onNewCRLsDistributionPointsSubject: onNewCRLsDistributionPointsSubject,
            apiVersion: resolvedBackendMetadata.apiVersion,
            localDomain: resolvedBackendMetadata.domain
        )

        assert(
            cRLsDistributionPointsObserver != nil,
            "requires to execute 'setupCertificateRevocationLists' first. this is a workaround and should be refactored."
        )
        cRLsDistributionPointsObserver?.startObservingNewCRLsDistributionPoints(
            from: onNewCRLsDistributionPointsSubject.eraseToAnyPublisher()
        )

        return e2eiRepository
    }()

    public lazy var enrollE2EICertificate: EnrollE2EICertificateUseCaseProtocol = EnrollE2EICertificateUseCase(
        e2eiRepository: e2eiRepository,
        context: syncContext
    )

    public private(set) var lastE2EIUpdateDateRepository: LastE2EIdentityUpdateDateRepositoryInterface?

    public private(set) lazy var getIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol =
        GetIsE2EIdentityEnabledUseCase(
            coreCryptoProvider: coreCryptoProvider,
            featureRespository: featureRepository
        )

    public private(set) lazy var getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol =
        GetE2eIdentityCertificatesUseCase(
            coreCryptoProvider: coreCryptoProvider,
            syncContext: syncContext
        )

    @MainActor
    public private(set) lazy var isE2EICertificateEnrollmentRequired: IsE2EICertificateEnrollmentRequiredProtocol =
        IsE2EICertificateEnrollmentRequiredUseCase(
            isE2EIdentityEnabled: e2eiFeature.isEnabled,
            selfClientCertificateProvider: selfClientCertificateProvider,
            gracePeriodEndDate: gracePeriodEndDate
        )

    public lazy var removeUserClient: RemoveUserClientUseCaseProtocol? = {
        let httpClient = HttpClientImpl(
            transportSession: transportSession,
            queue: syncContext
        )
        let apiProvider = APIProvider(httpClient: httpClient)
        guard let apiVersion = resolvedBackendMetadata.apiVersion else {
            WireLogger.backend.warn("apiVersion not resolved")

            return nil
        }

        return RemoveUserClientUseCase(
            userClientAPI: apiProvider.userClientAPI(apiVersion: apiVersion),
            syncContext: syncContext
        )
    }()

    public lazy var changeUsername: ChangeUsernameUseCaseProtocol =
        ChangeUsernameUseCase(userProfile: applicationStatusDirectory.userProfileUpdateStatus)

    public var createGroupConversationUseCase: (some CreateGroupConversationUseCaseProtocol)? {
        clientSessionComponent?.createGroupConversationUseCase()
    }

    public var createChannelUseCase: (some CreateChannelUseCaseProtocol)? {
        clientSessionComponent?.createChannelUseCase()
    }

    private lazy var mlsClientManager = MLSClientManager(
        coreCryptoProvider: coreCryptoProvider,
        mlsService: mlsService
    )

    let logFilesProvider: LogFilesProviding

    // MARK: Dependency Injection

    let dependencies: UserSessionDependencies

    // MARK: Delegates

    weak var delegate: UserSessionDelegate?

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: remove this property and move functionality to separate protocols under UserSessionDelegate
    public weak var sessionManager: SessionManagerType?

    var callStateObserverToken: AnyObject?

    private(set) var userSessionComponent: UserSessionComponent!
    public private(set) var clientSessionComponent: ClientSessionComponent?

    // MARK: - Initialize

    init(
        userId: UUID,
        restNetworkService: NetworkService,
        websocketNetworkService: NetworkService,
        blacklistNetworkService: NetworkService,
        backendMetadata: ResolvedBackendMetadata,
        transportSession: any TransportSessionType,
        mediaManager: any MediaManagerType,
        flowManager: any FlowManagerType,
        application: ZMApplication,
        currentAppVersion: String,
        currentBuildNumber: String,
        coreDataStack: CoreDataStack,
        earService: any EARServiceInterface,
        mlsService: any MLSServiceInterface,
        cryptoboxMigrationManager: any CryptoboxMigrationManagerInterface,
        proteusToMLSMigrationCoordinator: any ProteusToMLSMigrationCoordinating,
        sharedUserDefaults: UserDefaults,
        sharedContainerURL: URL,
        appLock: any AppLockType,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        lastEventIDRepository: any LastEventIDRepositoryInterface,
        lastE2EIUpdateDateRepository: any LastE2EIdentityUpdateDateRepositoryInterface,
        e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol,
        applicationStatusDirectory: ApplicationStatusDirectory,
        contextStorage: LAContextStorable,
        recurringActionService: any RecurringActionServiceInterface,
        dependencies: UserSessionDependencies,
        journal: Journal,
        logFilesProvider: LogFilesProviding,
        cookieStorage: any CookieStorageProtocol
    ) {
        self.application = application
        self.currentAppVersion = currentAppVersion
        self.currentBuildNumber = currentBuildNumber
        self.flowManager = flowManager
        self.mediaManager = mediaManager
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.notificationDispatcher = NotificationDispatcher(managedObjectContext: coreDataStack.viewContext)
        self.storedDidSaveNotifications = ContextDidSaveNotificationPersistence(
            accountContainer: coreDataStack.accountContainer
        )
        self.userExpirationObserver = UserExpirationObserver(managedObjectContext: coreDataStack.viewContext)
        self.topConversationsDirectory = TopConversationsDirectory(managedObjectContext: coreDataStack.viewContext)
        self.debugCommands = ZMUserSession.initDebugCommands()
        self.appLockController = appLock
        self.coreCryptoProvider = coreCryptoProvider
        self.lastEventIDRepository = lastEventIDRepository
        self.userId = userId
        self.lastE2EIUpdateDateRepository = lastE2EIUpdateDateRepository
        self.e2eiActivationDateRepository = e2eiActivationDateRepository
        self.applicationStatusDirectory = applicationStatusDirectory
        self.earService = earService
        self.mlsService = mlsService
        self.proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
        self.proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator
        self.contextStorage = contextStorage
        self.recurringActionService = recurringActionService
        self.dependencies = dependencies
        self.analyiticsLogger = .analytics
        self.journal = journal
        self.logFilesProvider = logFilesProvider

        super.init()

        self.userSessionComponent = UserSessionComponent(
            currentBuildNumber: currentBuildNumber,
            selfUserID: userId,
            cookieStorage: cookieStorage,
            restNetworkService: restNetworkService,
            websocketNetworkService: websocketNetworkService,
            blacklistNetworkService: blacklistNetworkService,
            backendMetaData: backendMetadata,
            isMLSEnabled: isBackendMLSEnabled,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: sharedContainerURL,
            syncContext: coreDataStack.syncContext,
            eventContext: coreDataStack.eventContext,
            mlsService: mlsService,
            mlsDecryptionService: mlsService,
            proteusService: proteusService,
            coreCryptoProvider: coreCryptoProvider
        )

        self.conversationEventProcessor = ConversationEventProcessor(
            context: coreDataStack.syncContext,
            localDomain: resolvedBackendMetadata.domain,
            isFederationEnabled: resolvedBackendMetadata.isFederationEnabled
        )
    }

    func trackAppOpenAnalyticEventWhenAppBecomesActive() {
        analyticsEventTracker?.trackEvent(.App.open)
    }

    func setup(
        apiVersion: WireNetwork.APIVersion?,
        eventProcessor: (any UpdateEventProcessor)?,
        strategyDirectory: (any StrategyDirectoryProtocol)?,
        syncStrategy: ZMSyncStrategy?,
        operationLoop: ZMOperationLoop?,
        configuration: Configuration,
        isDeveloperModeEnabled: Bool
    ) {
        coreDataStack.linkCaches(dependencies.caches)
        coreDataStack.linkContexts()

        // As we move the flag value from CoreData to UserDefaults, we set an initial value
        earService.setInitialEARFlagValue(viewContext.encryptMessagesAtRest)
        earService.delegate = self
        appLockController.delegate = self
        applicationStatusDirectory.clientRegistrationStatus.registrationStatusDelegate = self

        syncManagedObjectContext.performGroupedAndWait { [self] in
            localNotificationDispatcher = LocalNotificationDispatcher(in: coreDataStack.syncContext)
            configureTransportSession()

            // need to be before we create strategies since it is passed
            proteusProvider = ProteusProvider(
                proteusService: proteusService,
                keyStore: syncManagedObjectContext.zm_cryptKeyStore
            )

            self.strategyDirectory = strategyDirectory ?? createStrategyDirectory()
            legacyUpdateEventProcessor = eventProcessor ?? createUpdateEventProcessor()
            self.syncStrategy = syncStrategy ?? createSyncStrategy()
            self.operationLoop = operationLoop ?? createOperationLoop(
                apiVersion: apiVersion,
                isDeveloperModeEnabled: isDeveloperModeEnabled
            )
            urlActionProcessors = createURLActionProcessors()
            callStateObserver = CallStateObserver(
                localNotificationDispatcher: localNotificationDispatcher!,
                contextProvider: self,
                callNotificationStyleProvider: self
            )

            // FIXME: [WPB-5827] inject instead of storing on context - [jacob]
            syncManagedObjectContext.proteusService = proteusService
            syncManagedObjectContext.mlsService = mlsService

            applicationStatusDirectory.clientRegistrationStatus.prepareForClientRegistration()
            applicationStatusDirectory.clientUpdateStatus.determineInitialClientStatus()
            applicationStatusDirectory.clientRegistrationStatus.determineInitialRegistrationStatus()
        }

        setupMLSGroupVerification()
        setupCertificateRevocationLists()

        registerForCalculateBadgeCountNotification()
        registerForRegisteringPushTokenNotification()
        registerForBackgroundNotifications()

        enableBackgroundFetch()
        observeChangesOnShareExtension()
        startEphemeralTimers()
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
        restoreDebugCommandsState()
        configureRecurringActions()

        // Proactively keep the self user in sync, which helps add resilience
        // in cases where the self client may otherwise only have limited
        // one time opportunities to discover important changes.
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        selfUser.needsToBeUpdatedFromBackend = true

        // Proactively ensure we clean up invalid connection state.
        Task {
            do {
                let connectionValidator = ConnectionValidator(context: syncContext)
                try await connectionValidator.cleanUpAllInvalidConnections()
            } catch {
                WireLogger.session.error("failed to clean up invalid connections: \(String(describing: error))")
            }
        }

        if let selfUserClient {
            WireLogger.authentication.setClientID(selfUserClient.safeRemoteIdentifier.safeForLoggingDescription)

            // Create and perform sync if there is a self client.
            if let selfClientID = selfUserClient.remoteIdentifier {
                setUpSyncAgent(clientID: selfClientID)
            }
        }
    }

    func setUpSyncAgent(clientID: String) {
        let clientSessionComponent = userSessionComponent.clientSessionComponent(
            clientID: clientID,
            completionHandlers: .init(
                onProcessedCallEvent: { [weak self] in self?.onProcessedCallEvent(callEventInfo: $0) },
                onSelfClientInvalidated: { [weak self] in await self?.onSelfClientInvalidated() },
                onAuthenticationFailure: { [weak self] in self?.onAuthenticationFailure() },
                onProcessedTypingUsers: { [weak self] in self?.onProcessedTypingUsers(typingUsersInfo: $0) }
            )
        )
        self.clientSessionComponent = clientSessionComponent

        coreCryptoProvider.registerMlsTransport(clientSessionComponent.mlsTransport)

        let syncAgent = SyncAgent(
            journal: journal,
            lastUpdateEventIDRepository: lastEventIDRepository,
            coreCryptoProvider: coreCryptoProvider,
            initialSyncProvider: clientSessionComponent,
            incrementalSyncProvider: clientSessionComponent,
            legacySyncStatus: applicationStatusDirectory.syncStatus,
            featureConfigRepository: clientSessionComponent.featureConfigRepository,
            syncStateSubject: clientSessionComponent.syncStateSubject,
            pushChannelCoordinator: clientSessionComponent.mainAppPushChannelCoordinator,
            conversationUpdatesGenerator: clientSessionComponent.conversationUpdatesGenerator,
            networkStatePublisher: networkStateSubject.eraseToAnyPublisher()
        )
        applicationStatusDirectory.syncStatus.syncStateDelegate = syncAgent
        self.syncAgent = syncAgent
        syncAgent.delegate = self

        mlsService.setSyncDelegate(syncAgent)
        mlsService.setResetBrokenMLSConversationDelegate(clientSessionComponent.initiateResetMLSConversationUseCase)

        // Finish setting up the final strategies.
        if
            let strategyDirectory = strategyDirectory as? StrategyDirectory,
            let localNotificationDispatcher {
            let incrementalSyncObserver = IncrementalSyncObserver(
                syncAgent: syncAgent,
                notificationContext: notificationContext
            )
            strategyDirectory.makeClientRelatedStategies(
                applicationStatusDirectory: applicationStatusDirectory,
                syncContext: syncContext,
                transportSession: transportSession,
                pushMessageHandler: localNotificationDispatcher,
                flowManager: flowManager,
                incrementalSyncObserver: incrementalSyncObserver,
                metadata: resolvedBackendMetadata
            )
            syncStrategy?.updateClientContextChangeTrackers()
        }
        Task {
            await clientSessionComponent.workAgent.setAutoStartEnabled(true)
            await clientSessionComponent.workAgent.start()
        }
    }

    public func migrateToConsumableNotificationsIfNeeded() async throws {
        guard let clientSessionComponent else {
            throw ZMUserSessionError.selfClientNotReady
        }

        guard !journal[.isConsumableNotificationsEnabled] else { return }

        let migrator = clientSessionComponent.consumableNotificationsMigrator()
        do {
            try await migrator.migrate()
        } catch ConsumableNotificationsMigrator.Failure.apiVersionTooLow,
            ConsumableNotificationsMigrator.Failure.featureConfigNotEnabled {
            // ignore error
            WireLogger.session.info("skipping migration to consumable-notifications")
        } catch {
            WireLogger.session.error(
                "failed to migrate to consumable-notifications: \(String(describing: error))",
                attributes: .safePublic
            )
        }
    }

    // MARK: - Deinitalize

    deinit {
        userSessionComponent = nil
        require(isTornDown, "tearDown must be called before the ZMUserSession is deallocated")
    }

    public func tearDown() {
        guard !isTornDown else { return }

        Task {
            await clientSessionComponent?.workAgent.stop()
        }
        tearDownMLSGroupVerification()

        tokens.removeAll()
        application.unregisterObserverForStateChange(self)
        callStateObserver = nil
        syncStrategy?.tearDown()
        syncStrategy = nil
        operationLoop?.tearDown()
        operationLoop = nil
        transportSession.tearDown()
        notificationDispatcher.tearDown()
        callCenter?.tearDown()
        coreDataStack.close()
        contextStorage.clear()

        NotificationCenter.default.removeObserver(self)
        WireLogger.authentication.clearClientID()

        isTornDown = true
    }

    // MARK: - Methods

    public func makeAppVersionMigrationService() -> AppVersionMigrationService {
        let allMigrations = makeAppVersionMigrations()

        return AppVersionMigrationService(
            journal: journal,
            currentVersion: SemanticVersion(stringLiteral: currentAppVersion),
            allMigrations: allMigrations
        )
    }

    private func configureTransportSession() {
        transportSession.pushChannel.clientID = selfUserClient?.remoteIdentifier
        transportSession.setNetworkStateDelegate(self)
        transportSession.setAccessTokenRenewalFailureHandler { [weak self] response in
            self?.transportSessionAccessTokenDidFail(response: response)
        }
        transportSession.setAccessTokenRenewalSuccessHandler { [weak self]  _, _ in
            self?.transportSessionAccessTokenDidSucceed()
        }
    }

    private func createStrategyDirectory() -> StrategyDirectoryProtocol {
        StrategyDirectory(
            contextProvider: coreDataStack,
            applicationStatusDirectory: applicationStatusDirectory,
            cookieStorage: transportSession.cookieStorage,
            pushMessageHandler: localNotificationDispatcher!,
            flowManager: flowManager,
            updateEventProcessor: self,
            localNotificationDispatcher: localNotificationDispatcher!,
            lastEventIDRepository: lastEventIDRepository,
            transportSession: transportSession,
            proteusProvider: proteusProvider,
            mlsService: mlsService,
            coreCryptoProvider: coreCryptoProvider,
            pullSelfUserClientsFactory: { [weak self] context in
                guard let self else {
                    fatal("userSession not reachable")
                }
                return makePullSelfUserClients(context: context)
            },
            searchUsersCache: dependencies.caches.searchUsers,
            initiateResetMLSConversationUseCaseFactory: { [weak self] context in
                guard let self, let repo = clientSessionComponent?.conversationRepository else {
                    fatal("userSession not reachable")
                }
                // Passing useCase from WireDomain to WireRequestStrategy's MessageSender
                return makeInitiateResetMLSConversationUseCase(
                    context: context,
                    conversationRepository: repo
                )
            },
            metadata: resolvedBackendMetadata
        )
    }

    private func createUpdateEventProcessor() -> EventProcessor {
        EventProcessor(
            storeProvider: coreDataStack,
            eventProcessingTracker: eventProcessingTracker,
            earService: earService,
            lastEventIDRepository: lastEventIDRepository,
            strategyDirectory: strategyDirectory!,
            additionalEventConsumers: [conversationEventProcessor],
            isFederationEnabled: resolvedBackendMetadata.isFederationEnabled
        )
    }

    private func createURLActionProcessors() -> [URLActionProcessor] {
        [
            ImportEventsURLActionProcessor(
                eventProcessor: legacyUpdateEventProcessor!
            ),
            DeepLinkURLActionProcessor(
                contextProvider: coreDataStack,
                transportSession: transportSession,
                eventProcessor: conversationEventProcessor,
                metadata: resolvedBackendMetadata
            ),
            ConnectToBotURLActionProcessor(
                contextprovider: coreDataStack,
                transportSession: transportSession,
                eventProcessor: conversationEventProcessor,
                searchUsersCache: dependencies.caches.searchUsers,
                metadata: resolvedBackendMetadata
            )
        ]
    }

    private func createSyncStrategy() -> ZMSyncStrategy {
        ZMSyncStrategy(
            contextProvider: coreDataStack,
            notificationsDispatcher: notificationDispatcher,
            operationStatus: applicationStatusDirectory.operationStatus,
            application: application,
            strategyDirectory: strategyDirectory!,
            eventProcessingTracker: eventProcessingTracker
        )
    }

    private func createOperationLoop(
        apiVersion: WireNetwork.APIVersion?,
        isDeveloperModeEnabled: Bool
    ) -> ZMOperationLoop {
        ZMOperationLoop(
            transportSession: transportSession,
            requestStrategy: syncStrategy,
            updateEventProcessor: legacyUpdateEventProcessor!,
            operationStatus: applicationStatusDirectory.operationStatus,
            syncStatus: applicationStatusDirectory.syncStatus,
            pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
            uiMOC: managedObjectContext,
            syncMOC: syncManagedObjectContext,
            isDeveloperModeEnabled: isDeveloperModeEnabled,
            isSyncV2Enabled: journal[.isSyncV2Enabled],
            apiVersion: apiVersion.map { NSNumber(value: $0.rawValue) }
        )
    }

    private func configureRecurringActions() {
        recurringActionService.registerAction(refreshUsersMissingMetadataAction)
        recurringActionService.registerAction(refreshConversationsMissingMetadataAction)
        recurringActionService.registerAction(updateProteusToMLSMigrationStatusAction)
        recurringActionService.registerAction(refreshTeamMetadataAction)
        recurringActionService.registerAction(refreshFederationCertificatesAction)

        if DeveloperFlag.multibackend.isOn {
            recurringActionService.registerAction(checkBuildBlacklistAction)
        }
    }

    func startRequestLoopTracker() {
        transportSession.requestLoopDetectionCallback = { path in
            Logging.network.warn("Request loop happening at path: \(path)")

            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: .loggingRequestLoop,
                    object: nil,
                    userInfo: ["path": path]
                )
            }
        }
    }

    func setAnalyticsEventTracker(_ tracker: (any AnalyticsEventTrackerProtocol)?) {
        analyticsEventTracker = tracker

        // Track any events that were added before the service was configured.
        if let analyticsEventTracker {
            while !pendingAnalyticsEvents.isEmpty {
                let event = pendingAnalyticsEvents.removeFirst()
                analyticsEventTracker.trackEvent(event)
            }
            setupCallStateObserverForAnalytics()
        } else {
            callStateObserverToken = nil
        }
    }

    private func setupCallStateObserverForAnalytics() {
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(
            observer: self,
            contextProvider: contextProvider
        )
    }

    func trackAnalyticsEvent(_ event: AnalyticsEvent) {
        guard let analyticsEventTracker else {
            pendingAnalyticsEvents.append(event)
            return
        }

        analyticsEventTracker.trackEvent(event)
    }

    private func registerForCalculateBadgeCountNotification() {
        tokens
            .append(
                NotificationInContext
                    .addObserver(name: .calculateBadgeCount, context: notificationContext) { [weak self] _ in
                        self?.calculateBadgeCount()
                    }
            )
    }

    /// Count number of conversations with unread messages and update the application icon badge count.
    private func calculateBadgeCount() {
        let accountID = coreDataStack.account.userIdentifier
        let unreadCount = Int(ZMConversation.unreadConversationCount(in: syncManagedObjectContext))
        sessionManager?.updateAppIconBadge(accountID: accountID, unreadCount: unreadCount)
    }

    private func registerForBackgroundNotifications() {
        application.registerObserverForDidEnterBackground(self, selector: #selector(applicationDidEnterBackground(_:)))
        application.registerObserverForWillEnterForeground(
            self,
            selector: #selector(applicationWillEnterForeground(_:))
        )

    }

    private func enableBackgroundFetch() {
        // We enable background fetch by setting the minimum interval to something different from
        // UIApplicationBackgroundFetchIntervalNever
        application.setMinimumBackgroundFetchInterval(10.0 * 60.0 + Double.random(in: 0 ..< 300))
    }

    // MARK: - Trigger syncing

    /// Executes specific or regular sync after db migration
    func triggerSync() async {
        let (initialSync, resourcesSync) = await syncContext.perform { (
            self.syncContext.readMigrationNeedsSlowSyncFlag(),
            self.syncContext.readMigrationNeedsSyncResourcesFlag()
        ) }

        if initialSync || journal[.isInitialSyncRequired] {
            await triggerInitialSync()
        } else if resourcesSync {
            await triggerResourcesSync()
        } else if journal[.isConversationSyncRequired] {
            // as wanted this should not be blocking, see AppVersionMigration_4_1_1
            Task {
                let sync = clientSessionComponent?.pullAllConversationsSync
                try? await sync?.pull()
            }
        } else {
            syncAgent?.resume()
        }
    }

    public func triggerInitialSync() async {
        do {
            await syncAgent?.suspend()
            try await syncAgent?.performInitialSync()
        } catch {
            WireLogger.sync.error(
                "failed to perform initial sync: \(String(describing: error))",
                attributes: .initialSync
            )
        }
    }

    public func triggerResourcesSync() async {
        do {
            await syncAgent?.suspend()
            try await syncAgent?.performResourceSync()
        } catch {
            WireLogger.sync.error(
                "failed to perform resource sync: \(String(describing: error))",
                attributes: .initialSync
            )
        }
    }

    // Only used for testing
    public func triggerIncrementalSync() {
        Task {
            do {
                try await syncAgent?.performIncrementalSync()
            } catch {
                WireLogger.sync.error(
                    "failed to perform incremental sync: \(String(describing: error))",
                    attributes: .incrementalSync
                )
            }
        }
    }

    // MARK: Progress Events

    // temporary function to simplify call to ConversationEventProcessor
    // might be replaced by something more elegant
    public func processConversationEvents(_ events: [ZMUpdateEvent], completion: (() -> Void)?) {
        WaitingGroupTask(context: syncContext) { [weak self] in
            guard let self else {
                completion?()
                return
            }
            await conversationEventProcessor.processAndSaveConversationEvents(events)
            completion?()
        }
    }

    // MARK: Access Token

    private func renewAccessTokenIfNeeded(for userClient: WireDataModel.UserClient) {
        guard
            let apiVersion = resolvedBackendMetadata.apiVersion,
            apiVersion > .v2,
            let clientID = userClient.remoteIdentifier
        else { return }

        renewAccessToken(with: clientID)
    }

    // MARK: Perform changes

    public func saveOrRollbackChanges() {
        managedObjectContext.saveOrRollback()
    }

    @objc(performChanges:)
    public func perform(_ changes: @escaping () -> Void) {
        managedObjectContext.performGroupedAndWait { [weak self] in
            changes()
            self?.saveOrRollbackChanges()
        }
    }

    @objc(enqueueChanges:)
    public func enqueue(_ changes: @escaping () -> Void) {
        enqueue(changes, completionHandler: nil)
    }

    @objc(enqueueChanges:completionHandler:)
    public func enqueue(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        managedObjectContext.performGroupedBlock { [weak self] in
            changes()
            self?.saveOrRollbackChanges()
            completionHandler?()
        }
    }

    @objc(enqueueDelayedChanges:completionHandler:)
    public func enqueueDelayed(_ changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        managedObjectContext.performGroupedBlock { [weak self] in
            changes()
            self?.saveOrRollbackChanges()

            let group = ZMSDispatchGroup(label: "enqueueDelayedChanges")
            self?.managedObjectContext.enqueueDelayedSave(with: group)

            group.notify(on: DispatchQueue.global(qos: .background), block: {
                self?.managedObjectContext.performGroupedBlock {
                    completionHandler?()
                }
            })
        }
    }

    // MARK: Account

    public func initiateUserDeletion() {
        syncManagedObjectContext.performGroupedBlock {
            self.syncManagedObjectContext.setPersistentStoreMetadata(
                NSNumber(value: true),
                key: DeleteAccountRequestStrategy.userDeletionInitiatedKey
            )
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

    // MARK: Caches

    func purgeTemporaryAssets() throws {
        try dependencies.caches.fileAssets.purgeTemporaryAssets()
    }

}

// MARK: - ZMNetworkStateDelegate

extension ZMUserSession: ZMNetworkStateDelegate {

    public func didReceiveData() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isNetworkOnline = true
            self?.updateNetworkState()
        }
    }

    public func didGoOffline() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isNetworkOnline = false
            self?.updateNetworkState()
            self?.saveOrRollbackChanges()

        }
    }

    func updateNetworkState() {
        networkState = switch (isNetworkOnline, isPerformingSync) {
        case (true, true):
            .onlineSynchronizing
        case (true, false):
            .online
        case (false, _):
            .offline
        }
    }
}

// MARK: - UpdateEventProcessor

// TODO: [WPB-9089] find another way of providing the event processor to ZMissingEventTranscoder
extension ZMUserSession: UpdateEventProcessor {
    public func bufferEvents(_ events: [WireTransport.ZMUpdateEvent]) async {
        await legacyUpdateEventProcessor?.bufferEvents(events)
    }

    public func processEvents(_ events: [WireTransport.ZMUpdateEvent]) async throws {
        try await legacyUpdateEventProcessor?.processEvents(events)
    }

    public func processLiveEvents(_ events: [WireTransport.ZMUpdateEvent]) async throws {
        assertionFailure("should not be used")
    }

    public func processBufferedEvents() async throws {
        try await legacyUpdateEventProcessor?.processBufferedEvents()
    }
}

// MARK: - SyncAgent delegate

extension ZMUserSession: SyncAgentDelegate {

    func syncAgentDidStartInitialSync(_ syncAgent: SyncAgent) {
        didStartInitialSync()
    }

    func syncAgentDidFinishInitialSync(_ syncAgent: SyncAgent) {
        didFinishInitialSync()
    }

    func syncAgentDidStartIncrementalSync(_ syncAgent: SyncAgent) {
        didStartIncrementalSync()
    }

    func syncAgentDidFinishIncrementalSync(
        _ syncAgent: SyncAgent,
        isRecovering: Bool
    ) {
        didFinishIncrementalSync(isRecovering: isRecovering)
    }

    func syncAgentDidStartLegacyInitialSync(_ syncAgent: SyncAgent) {
        didStartInitialSync()
    }

    func syncAgentDidFinishLegacyInitialSync(_ syncAgent: SyncAgent) {
        didFinishInitialSync()
    }

    func syncAgentDidStartLegacyIncrementalSync(_ syncAgent: SyncAgent) {
        didStartIncrementalSync()
    }

    func syncAgentDidFinishLegacyIncrementalSync(
        _ syncAgent: SyncAgent,
        isRecovering: Bool
    ) {
        didFinishIncrementalSync(isRecovering: isRecovering)
    }

    func syncAgentDidFailSyncing(_ syncAgent: SyncAgent, error: any Error) {
        if Bundle.developerModeEnabled { // Only show sync error alert for debugging
            let onRetry: () -> Void = { [weak self] in
                self?.managedObjectContext.performGroupedBlock {
                    self?.isPerformingSync = true
                    self?.updateNetworkState()
                }

                syncAgent.resume()
            }

            delegate?.clientDidFailSyncing(
                error: error,
                retryHandler: onRetry
            )
        }

        WireLogger.sync.error("failed to perform sync: \(String(describing: error))")

        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = false
            self?.updateNetworkState()
        }
    }

    func didStartInitialSync() {
        if !journal[.isSyncV2Enabled], !journal[.isInitialSyncRequired] {
            // in legacy, we need to set this flag here
            journal[.isInitialSyncRequired] = true
        }
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.notificationDispatcher.isEnabled = false
            self?.updateNetworkState()
        }
    }

    func didFinishInitialSync() {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self else { return }

            managedObjectContext.resetMigrationNeedsSlowSyncFlagIfNeeded()
            managedObjectContext.resetMigrationNeedsSyncResoucesFlagIfNeeded()
            if !journal[.isSyncV2Enabled] {
                // in legacy, we need to reset this flag here
                journal[.isInitialSyncRequired] = false
            }
            notificationDispatcher.isEnabled = true
            delegate?.clientCompletedInitialSync(accountId: account.userIdentifier)

            NotificationInContext(
                name: .initialSync,
                context: notificationContext
            ).post()
        }

        syncContext.perform { [weak self] in
            guard let self else { return }
            let selfClient = ZMUser.selfUser(in: syncContext).selfClient()

            if selfClient?.hasRegisteredMLSClient == true {
                Task {
                    do {
                        try await self.mlsService.repairOutOfSyncConversations()
                    } catch {
                        WireLogger.mls.error("Repairing out of sync conversations failed: \(error)")
                    }
                }
            }
        }
    }

    func didStartIncrementalSync() {
        WireLogger.sync.debug("did start incremental sync", attributes: .incrementalSync)
        Task {
            await showSyncBar(true)
        }
    }

    @MainActor
    private func showSyncBar(_ show: Bool) {
        isPerformingSync = show
        updateNetworkState()
    }

    func didFinishIncrementalSync(isRecovering: Bool) {
        WireLogger.sync.debug(
            "did finish incremental sync (isRecovering: \(isRecovering))",
            attributes: .incrementalSync
        )

        Task {
            await showSyncBar(false)
        }

        WaitingGroupTask(context: syncContext) { [weak self] in
            guard let self else { return }
            await fetchBackendMLSPublicKeys()
            await fetchAndStoreFeatureConfig()

            let (qualifiedSelfClientID, hasRegisteredMLSClient) = await syncContext.perform {
                let selfClient = ZMUser.selfUser(in: self.syncContext).selfClient()
                let hasRegisteredMLSClient = selfClient?.hasRegisteredMLSClient == true
                return (selfClient?.qualifiedClientID, hasRegisteredMLSClient)
            }

            if let qualifiedSelfClientID {
                await mlsClientManager.initializeMLSClientIfNeeded(
                    for: qualifiedSelfClientID,
                    hasRegisteredMLSClient: hasRegisteredMLSClient,
                    mlsFeature: mlsFeature,
                    isBackendMLSEnabled: isBackendMLSEnabled
                )
            } else {
                WireLogger.mls.warn("`qualifiedClientID` is missing for selfClient")
            }

            if !isRecovering, mlsFeature.isEnabled {
                Task.detached { [mlsService] in
                    // we don't need to wait for this, as it can take a while to finish
                    await mlsService.commitPendingProposalsIfNeeded()
                }
            }

            await calculateSelfSupportedProtocolsIfNeeded()
            await resolveOneOnOneConversationsIfNeeded()

            // TODO: [WPB-18175] Port MLS client creation and related MLS operations from here to the InitialSync

            await recurringActionService.performActionsIfNeeded()
        }

        performPostQuickSyncE2EIActions()
    }

    /// Calculate supported protocols for self user in case they are empty
    /// - note: Supported protocols are calculated only during slow sync
    /// or while resolving 1-1 conversations (MLS enabled).
    /// It fixes users that updates to latest version without having a supported-protocol.
    /// This could be removed once MLS is enabled.
    private func calculateSelfSupportedProtocolsIfNeeded() async {
        await syncContext.perform { [syncContext] in
            let service = LegacySupportedProtocolsService(context: syncContext)
            let selfUser = ZMUser.selfUser(in: syncContext)
            if selfUser.supportedProtocols.isEmpty {
                WireLogger.supportedProtocols.warn("no supported protocols found")
                selfUser.supportedProtocols = service.calculateSupportedProtocols()
                syncContext.saveOrRollback()
            }
        }
    }

    /// Note: this method is used only for legacy sync
    private func makeResolveOneOnOneConversationsUseCase(context: NSManagedObjectContext)
        -> any LegacyResolveOneOnOneConversationsUseCaseProtocol {
        let supportedProtocolService = LegacySupportedProtocolsService(context: context)

        let resolver = LegacyOneOnOneResolver(
            migrator: OneOnOneMigrator(mlsService: mlsService),
            isMLSEnabled: mlsFeature.isEnabled
        )

        return LegacyResolveOneOnOneConversationsUseCase(
            context: context,
            supportedProtocolService: supportedProtocolService,
            resolver: resolver,
            pullSelfUserClientsFactory: makePullSelfUserClients
        )
    }

    private func makeInitiateResetMLSConversationUseCase(
        context: NSManagedObjectContext,
        conversationRepository: ConversationRepositoryProtocol
    ) -> WireRequestStrategy.InitiateResetMLSConversationUseCaseProtocol {
        guard let clientSessionComponent else {
            fatalError()
        }

        return InitiateResetMLSConversationUseCase(
            api: clientSessionComponent.mlsAPI,
            mlsService: mlsService,
            conversationLocalStore: clientSessionComponent.conversationLocalStore,
            conversationRepository: clientSessionComponent.conversationRepository,
            lockRepository: ResetMLSConversationLockRepository(
                userID: userId
            )
        )
    }

    private func makePullSelfUserClients(context: NSManagedObjectContext) -> PullSelfUserClientsSyncProtocol {
        guard let clientSessionComponent else {
            fatalError()
        }

        return PullSelfUserClientsSync(
            api: clientSessionComponent.userClientsAPI,
            store: clientSessionComponent.userClientsLocalStore
        )
    }

    private func resolveOneOnOneConversationsIfNeeded() async {
        guard mlsFeature.isEnabled, !didAlreadyResolveAllOneOnOnes else { return }

        let resolveOneOnOneUseCase = makeResolveOneOnOneConversationsUseCase(context: syncContext)
        do {
            let didResolve = try await resolveOneOnOneUseCase.invoke()
            didAlreadyResolveAllOneOnOnes = didResolve
        } catch {
            WireLogger.mls.error("Failed to resolve one on one conversations: \(String(reflecting: error))")
        }
    }

    private func performPostQuickSyncE2EIActions() {
        guard mlsFeature.isEnabled else { return }

        checkExpiredCertificateRevocationLists()
        checkE2EICertificateExpiryStatus()
    }

    private func fetchAndStoreFeatureConfig() async {
        do {
            try await clientSessionComponent?.featureConfigRepository.pullFeatureConfigs()
        } catch {
            WireLogger.featureConfigs.error("Failed getFeatureConfigAction: \(String(reflecting: error))")
        }
    }

    private func fetchBackendMLSPublicKeys() async {
        guard !DeveloperFlag.multibackend.isOn else {
            // fetching done on UserSessionLoader
            return
        }
        do {
            var getBackendMLSPublicKeysAction = FetchBackendMLSPublicKeysAction()
            let backendPublicKeys = try await getBackendMLSPublicKeysAction.perform(in: notificationContext)
            let hasValidKeys = backendPublicKeys.removal.hasValidKeys()
            BackendInfo.isMLSEnabled = hasValidKeys
        } catch {
            WireLogger.mls.info("Backend doesn't have MLS public keys: \(String(reflecting: error))")
        }
    }

    func processLegacyEvents() {
        guard !journal[.isSyncV2Enabled] else {
            return
        }

        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.updateNetworkState()
        }

        let groups = syncContext.enterAllGroupsExceptSecondary()
        Task {
            var processingInterrupted = false
            do {
                try await legacyUpdateEventProcessor?.processBufferedEvents()
            } catch {
                processingInterrupted = true
            }

            let isSyncing = await syncContext.perform { self.applicationStatusDirectory.syncStatus.isSyncing }

            await managedObjectContext.perform { [weak self] in
                self?.isPerformingSync = isSyncing || processingInterrupted
                self?.updateNetworkState()
            }
            self.syncContext.leaveAllGroups(groups)
        }
    }

    func processPendingCallEvents() async {
        if journal[.isSyncV2Enabled] {
            WireLogger.sync.debug(
                "process pending call events",
                attributes: .incrementalSync
            )

            syncAgent?.resume()
        } else {
            WireLogger.updateEvent.info("process pending call events")
            do {
                // TODO: [WPB-15391] why not processing only the call events (should be stored here?)
                try await legacyUpdateEventProcessor!.processBufferedEvents()
            } catch {
                WireLogger.updateEvent.error("Failed to process pending call events: \(String(reflecting: error))")
            }
        }
    }

    func notifyAuthenticationInvalidated(_ error: Error) {
        WireLogger.authentication.debug("notifying authentication invalidated")
        managedObjectContext.performGroupedBlock {  [weak self] in
            guard
                let context = self?.managedObjectContext,
                let accountId = ZMUser.selfUser(in: context).remoteIdentifier
            else {
                return
            }

            self?.delegate?.authenticationInvalidated(error as NSError, accountId: accountId)
        }
    }

    func checkE2EICertificateExpiryStatus() {
        Task {
            let isE2EIFeatureEnabled = await managedObjectContext.perform { self.e2eiFeature.isEnabled }
            if isE2EIFeatureEnabled {
                NotificationCenter.default.post(name: .checkForE2EICertificateExpiryStatus, object: nil)
            }
        }
    }
}

// MARK: - ZMClientRegistrationStatusDelegate

extension ZMUserSession: ZMClientRegistrationStatusDelegate {

    public func didRegisterSelfUserClient(_ userClient: WireDataModel.UserClient) {
        // If during registration user allowed notifications,
        // The push token can only be registered after client registration
        transportSession.pushChannel.clientID = userClient.remoteIdentifier
        registerCurrentPushToken()
        renewAccessTokenIfNeeded(for: userClient)

        managedObjectContext.performGroupedBlock { [weak self] in
            guard
                let context = self?.managedObjectContext,
                let accountId = ZMUser.selfUser(in: context).remoteIdentifier
            else {
                return
            }

            self?.delegate?.clientRegistrationDidSucceed(accountId: accountId)
        }

        let clientID = userClient.safeRemoteIdentifier.safeForLoggingDescription
        WireLogger.authentication.setClientID(clientID)

        // The client was just registered and still needs to perform the
        // initial sync.
        if let selfClientID = userClient.remoteIdentifier {
            setUpSyncAgent(clientID: selfClientID)
            // no migration needed from last sync system as it's a new client
            if userClient.isConsumableNotificationsCapable {
                // activate new sync with consumable notifications
                journal[.isConsumableNotificationsEnabled] = true
            }
            // this is a fresh client so we need an initialSync
            journal[.isInitialSyncRequired] = true
            Task {
                WireLogger.sync.debug("Triggering initial sync after client registration")
                await triggerSync()
            }
        }
    }

    public func didFailToRegisterSelfUserClient(error: Error) {
        managedObjectContext.performGroupedBlock {  [weak self] in
            guard
                let context = self?.managedObjectContext,
                let accountId = ZMUser.selfUser(in: context).remoteIdentifier
            else {
                return
            }

            self?.delegate?.clientRegistrationDidFail(error as NSError, accountId: accountId)
        }
    }

    public func didDeleteSelfUserClient(error: Error) {
        notifyAuthenticationInvalidated(error)
    }

}

// MARK: - URLActionProcessor

extension ZMUserSession: URLActionProcessor {
    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        urlActionProcessors?.forEach { $0.process(urlAction: urlAction, delegate: delegate) }
    }
}

// MARK: - ContextProvider

extension ZMUserSession: ContextProvider {

    public var account: Account {
        coreDataStack.account
    }

    public var viewContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    public func newBackgroundContext() -> NSManagedObjectContext {
        coreDataStack.newBackgroundContext()
    }

    public var syncContext: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    public var searchContext: NSManagedObjectContext {
        coreDataStack.searchContext
    }

    public var eventContext: NSManagedObjectContext {
        coreDataStack.eventContext
    }
}

// MARK: - NotificationName + LoggingRequestLoopNotificationName

public extension Notification.Name {
    static let loggingRequestLoop = Self("LoggingRequestLoopNotificationName")
}

// MARK: - Callbacks from WireDomain

extension ZMUserSession {

    @Sendable
    public func onAuthenticationFailure() {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self else { return }

            let selfUser = ZMUser.selfUser(in: managedObjectContext)

            notifyAuthenticationInvalidated(
                NSError.userSessionError(
                    code: .accessTokenExpired,
                    userInfo: selfUser.loginCredentials.dictionaryRepresentation
                )
            )
        }
    }

    private func onProcessedTypingUsers(
        typingUsersInfo: [ConversationTypingUsersInfo]
    ) {

        viewContext.performGroupedBlock { [viewContext] in
            for typingUserInfo in typingUsersInfo {
                let conversationID = typingUserInfo.conversationID
                let usersID = typingUserInfo.users

                if let conversation = viewContext.object(with: conversationID) as? ZMConversation {

                    let users = usersID.compactMap {
                        viewContext.object(with: $0) as? ZMUser
                    }

                    viewContext.typingUsers?.update(
                        typingUsers: Set(users),
                        in: conversation
                    )

                    conversation.notifyTyping(typingUsers: Set(users))
                }
            }
        }
    }

    func onSelfClientInvalidated() async {
        await syncContext.perform { [self] in
            syncContext.tearDownCryptoStack()

            let clientRegistrationStatus = applicationStatusDirectory.clientRegistrationStatus
            let clientUpdateStatus = applicationStatusDirectory.clientUpdateStatus

            clientRegistrationStatus.emailCredentials = nil
            clientRegistrationStatus.cookieProvider.deleteKeychainItems()

            let selfUser = ZMUser.selfUser(in: syncContext)
            let clientDeletedRemotelyError = NSError.userSessionError(
                code: .clientDeletedRemotely,
                userInfo: selfUser.loginCredentials.dictionaryRepresentation
            )

            didDeleteSelfUserClient(error: clientDeletedRemotelyError)

            clientUpdateStatus.needsToVerifySelfClient = false
        }
    }

    private func onProcessedCallEvent(callEventInfo: CallEventInfo) {
        let serverTimeDelta = syncContext.performAndWait {
            syncContext.serverTimeDelta // serverTimeDelta can only be accessed on the sync context
        }

        viewContext.perform { [weak self] in // callCenter can only be accessed on the ui context
            guard let self, let callCenter else { return }
            guard !callEventInfo.isMuted else {
                callCenter.isMuted = true
                return
            }

            let conversationId = AVSIdentifier(
                identifier: callEventInfo.conversationID,
                domain: callEventInfo.conversationDomain,
                isFederationEnabled: resolvedBackendMetadata.isFederationEnabled
            )

            let userId = AVSIdentifier(
                identifier: callEventInfo.userID,
                domain: callEventInfo.userDomain,
                isFederationEnabled: resolvedBackendMetadata.isFederationEnabled
            )

            let callEvent = CallEvent(
                data: callEventInfo.data,
                currentTimestamp: Date.now.addingTimeInterval(serverTimeDelta),
                serverTimestamp: callEventInfo.eventTimestamp,
                conversationId: conversationId,
                userId: userId,
                clientId: callEventInfo.clientID
            )

            callCenter.processCallEvent(callEvent)
        }

    }
}

extension ZMUserSession {

    private func makeAppVersionMigrations() -> [any AppVersionMigration] {
        [
            AppVersionMigration_4_1_1(journal: journal, logFilesProvider: logFilesProvider),
            AppVersionMigration_4_2_0(
                appGroupIdentifier: Bundle.main.appGroupIdentifier,
                lastEventIDRepository: lastEventIDRepository,
                journal: journal,
                sessionManager: sessionManager
            ),
            AppVersionMigration_4_3_0(coreCryptoProvider: coreCryptoProvider),
            AppVersionMigration_4_10_0(journal: journal)
        ]
    }

}

extension InitiateResetMLSConversationUseCase: WireRequestStrategy.InitiateResetMLSConversationUseCaseProtocol {}

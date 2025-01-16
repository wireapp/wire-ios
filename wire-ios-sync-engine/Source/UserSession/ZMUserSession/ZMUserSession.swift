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

import Combine
import Foundation
import WireAnalytics
import WireAPI
import WireDataModel
import WireLogging
import WireRequestStrategy
import WireSystem

typealias UserSessionDelegate = UserSessionAppLockDelegate
    & UserSessionEncryptionAtRestDelegate
    & UserSessionLogoutDelegate
    & UserSessionSelfUserClientDelegate

public typealias APIServiceFactory = @Sendable (_ clientID: String, _ userID: UUID) -> APIServiceProtocol

@objcMembers
public final class ZMUserSession: NSObject {

    // MARK: Properties

    private let appVersion: String
    private var tokens: [Any] = []
    private var tornDown: Bool = false

    private(set) var isNetworkOnline = true

    private(set) var coreDataStack: CoreDataStack!
    private let apiServiceFactory: APIServiceFactory
    var apiService: APIServiceProtocol? {
        guard let clientId = selfUserClient?.remoteIdentifier else {
            return nil
        }
        return apiServiceFactory(clientId, userId)
    }

    let application: ZMApplication
    let flowManager: FlowManagerType
    private(set) var mediaManager: MediaManagerType
    private(set) var transportSession: TransportSessionType
    let storedDidSaveNotifications: ContextDidSaveNotificationPersistence
    let userExpirationObserver: UserExpirationObserver
    private(set) var updateEventProcessor: UpdateEventProcessor?
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
    let legacyHotFix: ZMHotFix

    var accessTokenRenewalObserver: AccessTokenRenewalObserver?

    var recurringActionService: any RecurringActionServiceInterface

    var cryptoboxMigrationManager: CryptoboxMigrationManagerInterface
    private(set) var coreCryptoProvider: CoreCryptoProviderProtocol
    private(set) var userId: UUID
    private(set) lazy var proteusService: ProteusServiceInterface =
        ProteusService(coreCryptoProvider: coreCryptoProvider)
    private(set) var mlsService: MLSServiceInterface
    private(set) var proteusProvider: ProteusProviding!
    let proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating

    public lazy var featureRepository = FeatureRepository(context: syncContext)

    let earService: EARServiceInterface

    public private(set) weak var analyticsEventTracker: (any AnalyticsEventTracker)?
    private var pendingAnalyticsEvents = [AnalyticsEvent]()

    public internal(set) var appLockController: AppLockType
    private let contextStorage: LAContextStorable

    public let e2eiActivationDateRepository: E2EIActivationDateRepositoryProtocol

    let lastEventIDRepository: LastEventIDRepositoryInterface
    let conversationEventProcessor: ConversationEventProcessor

    public var hasCompletedInitialSync: Bool = false

    public var topConversationsDirectory: TopConversationsDirectory

    public internal(set) var mlsGroupVerification: (any MLSGroupVerificationProtocol)?

    // MARK: Computed Properties

    var isPerformingSync = true {
        willSet {
            notificationDispatcher.operationMode = newValue ? .economical : .normal
        }
    }

    public var syncStatus: SyncStatusProtocol {
        applicationStatusDirectory.syncStatus
    }

    public var fileSharingFeature: Feature.FileSharing {
        let featureRepository = FeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchFileSharing()
    }

    public var selfDeletingMessagesFeature: Feature.SelfDeletingMessages {
        let featureRepository = FeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchSelfDeletingMesssages()
    }

    public var conversationGuestLinksFeature: Feature.ConversationGuestLinks {
        let featureRepository = FeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchConversationGuestLinks()
    }

    public var classifiedDomainsFeature: Feature.ClassifiedDomains {
        let featureRepository = FeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchClassifiedDomains()
    }

    public var e2eiFeature: Feature.E2EI {
        let featureRepository = FeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchE2EI()
    }

    public var mlsFeature: Feature.MLS {
        let featureRepository = FeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchMLS()
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
            context: syncContext
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

    public private(set) var networkState: NetworkState = .online {
        didSet {
            if oldValue != networkState {
                ZMNetworkAvailabilityChangeNotification.notify(
                    networkState: networkState,
                    notificationContext: managedObjectContext.notificationContext
                )
            }
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
            proteusProvider: proteusProvider
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
            conversationEventProcessor: conversationEventProcessor,
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
            onNewCRLsDistributionPointsSubject: onNewCRLsDistributionPointsSubject
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
        guard let apiVersion = BackendInfo.apiVersion else {
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

    private lazy var  mlsClientManager = MLSClientManager(
        coreCryptoProvider: coreCryptoProvider,
        mlsService: mlsService
    )

    // MARK: Dependency Injection

    let dependencies: UserSessionDependencies

    // MARK: Delegates

    weak var delegate: UserSessionDelegate?

    // swiftlint:disable:next todo_requires_jira_link
    // TODO: remove this property and move functionality to separate protocols under UserSessionDelegate
    public weak var sessionManager: SessionManagerType?

    var callStateObserverToken: Any?

    // MARK: - Initialize

    init(
        userId: UUID,
        transportSession: any TransportSessionType,
        mediaManager: any MediaManagerType,
        flowManager: any FlowManagerType,
        apiServiceFactory: @escaping @Sendable (_ clientID: String, _ userID: UUID) -> APIServiceProtocol,
        application: ZMApplication,
        appVersion: String,
        coreDataStack: CoreDataStack,
        earService: any EARServiceInterface,
        mlsService: any MLSServiceInterface,
        cryptoboxMigrationManager: any CryptoboxMigrationManagerInterface,
        proteusToMLSMigrationCoordinator: any ProteusToMLSMigrationCoordinating,
        sharedUserDefaults: UserDefaults,
        appLock: any AppLockType,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        lastEventIDRepository: any LastEventIDRepositoryInterface,
        lastE2EIUpdateDateRepository: any LastE2EIdentityUpdateDateRepositoryInterface,
        e2eiActivationDateRepository: any E2EIActivationDateRepositoryProtocol,
        applicationStatusDirectory: ApplicationStatusDirectory,
        contextStorage: LAContextStorable,
        recurringActionService: any RecurringActionServiceInterface,
        dependencies: UserSessionDependencies
    ) {
        self.apiServiceFactory = apiServiceFactory
        self.application = application
        self.appVersion = appVersion
        self.flowManager = flowManager
        self.mediaManager = mediaManager
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.notificationDispatcher = NotificationDispatcher(managedObjectContext: coreDataStack.viewContext)
        self
            .storedDidSaveNotifications = ContextDidSaveNotificationPersistence(
                accountContainer: coreDataStack
                    .accountContainer
            )
        self.userExpirationObserver = UserExpirationObserver(managedObjectContext: coreDataStack.viewContext)
        self.topConversationsDirectory = TopConversationsDirectory(managedObjectContext: coreDataStack.viewContext)
        self.debugCommands = ZMUserSession.initDebugCommands()
        self.legacyHotFix = ZMHotFix(syncMOC: coreDataStack.syncContext)
        self.appLockController = appLock
        self.coreCryptoProvider = coreCryptoProvider
        self.lastEventIDRepository = lastEventIDRepository
        self.userId = userId
        self.lastE2EIUpdateDateRepository = lastE2EIUpdateDateRepository
        self.e2eiActivationDateRepository = e2eiActivationDateRepository
        self.applicationStatusDirectory = applicationStatusDirectory
        self.earService = earService
        self.mlsService = mlsService
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
        self.conversationEventProcessor = ConversationEventProcessor(context: coreDataStack.syncContext)
        self.proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator
        self.contextStorage = contextStorage
        self.recurringActionService = recurringActionService
        self.dependencies = dependencies

        super.init()
    }

    func trackAppOpenAnalyticEventWhenAppBecomesActive() {
        analyticsEventTracker?.trackEvent(.App.open)
    }

    func setup(
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
        applicationStatusDirectory.syncStatus.syncStateDelegate = self
        applicationStatusDirectory.clientRegistrationStatus.registrationStatusDelegate = self

        syncManagedObjectContext.performGroupedAndWait { [self] in
            localNotificationDispatcher = LocalNotificationDispatcher(in: coreDataStack.syncContext)
            configureTransportSession()

            // need to be before we create strategies since it is passed
            proteusProvider = ProteusProvider(
                proteusService: proteusService,
                keyStore: syncManagedObjectContext.zm_cryptKeyStore
            )

            self
                .strategyDirectory = strategyDirectory ??
                createStrategyDirectory(useLegacyPushNotifications: configuration.useLegacyPushNotifications)
            updateEventProcessor = eventProcessor ?? createUpdateEventProcessor()
            self.syncStrategy = syncStrategy ?? createSyncStrategy()
            self.operationLoop = operationLoop ?? createOperationLoop(isDeveloperModeEnabled: isDeveloperModeEnabled)
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
            applicationStatusDirectory.syncStatus.determineInitialSyncPhase()
            applicationStatusDirectory.clientUpdateStatus.determineInitialClientStatus()
            applicationStatusDirectory.clientRegistrationStatus.determineInitialRegistrationStatus()
            hasCompletedInitialSync = applicationStatusDirectory.syncStatus.isSlowSyncing == false
        }

        setupMLSGroupVerification()
        setupCertificateRevocationLists()

        registerForCalculateBadgeCountNotification()
        registerForRegisteringPushTokenNotification()
        registerForBackgroundNotifications()

        enableBackgroundFetch()
        observeChangesOnShareExtension()
        startEphemeralTimers()
        notifyUserAboutChangesInAvailabilityBehaviourIfNeeded()
        RequestAvailableNotification.notifyNewRequestsAvailable(self)
        restoreDebugCommandsState()
        configureRecurringActions()

        // Proactively keep the self user in sync, which helps add resilience
        // in cases where the self client may otherwise only have limited
        // one time opportunities to discover important changes.
        let selfUser = ZMUser.selfUser(in: managedObjectContext)
        selfUser.needsToBeUpdatedFromBackend = true

        if let clientId = selfUserClient?.safeRemoteIdentifier.safeForLoggingDescription {
            WireLogger.authentication.addTag(.selfClientId, value: clientId)
        }
    }

    // MARK: - Deinitalize

    deinit {
        require(tornDown, "tearDown must be called before the ZMUserSession is deallocated")
    }

    public func tearDown() {
        guard !tornDown else { return }

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
        WireLogger.authentication.addTag(.selfClientId, value: nil)

        tornDown = true
    }

    // MARK: - Methods

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

    private func createStrategyDirectory(useLegacyPushNotifications: Bool) -> StrategyDirectoryProtocol {
        StrategyDirectory(
            contextProvider: coreDataStack,
            applicationStatusDirectory: applicationStatusDirectory,
            cookieStorage: transportSession.cookieStorage,
            pushMessageHandler: localNotificationDispatcher!,
            flowManager: flowManager,
            updateEventProcessor: self,
            localNotificationDispatcher: localNotificationDispatcher!,
            useLegacyPushNotifications: useLegacyPushNotifications,
            lastEventIDRepository: lastEventIDRepository,
            transportSession: transportSession,
            proteusProvider: proteusProvider,
            mlsService: mlsService,
            coreCryptoProvider: coreCryptoProvider,
            searchUsersCache: dependencies.caches.searchUsers
        )
    }

    private func createUpdateEventProcessor() -> EventProcessor {
        EventProcessor(
            storeProvider: coreDataStack,
            eventProcessingTracker: eventProcessingTracker,
            earService: earService,
            eventConsumers: strategyDirectory?.eventConsumers ?? [],
            eventAsyncConsumers: (strategyDirectory?.eventAsyncConsumers ?? []) + [conversationEventProcessor],
            lastEventIDRepository: lastEventIDRepository
        )
    }

    private func createURLActionProcessors() -> [URLActionProcessor] {
        [
            ImportEventsURLActionProcessor(
                eventProcessor: updateEventProcessor!
            ),
            DeepLinkURLActionProcessor(
                contextProvider: coreDataStack,
                transportSession: transportSession,
                eventProcessor: conversationEventProcessor
            ),
            ConnectToBotURLActionProcessor(
                contextprovider: coreDataStack,
                transportSession: transportSession,
                eventProcessor: conversationEventProcessor,
                searchUsersCache: dependencies.caches.searchUsers
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

    private func createOperationLoop(isDeveloperModeEnabled: Bool) -> ZMOperationLoop {
        ZMOperationLoop(
            transportSession: transportSession,
            requestStrategy: syncStrategy,
            updateEventProcessor: updateEventProcessor!,
            operationStatus: applicationStatusDirectory.operationStatus,
            syncStatus: applicationStatusDirectory.syncStatus,
            pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
            callEventStatus: applicationStatusDirectory.callEventStatus,
            uiMOC: managedObjectContext,
            syncMOC: syncManagedObjectContext,
            isDeveloperModeEnabled: isDeveloperModeEnabled
        )
    }

    private func configureRecurringActions() {
        recurringActionService.registerAction(refreshUsersMissingMetadataAction)
        recurringActionService.registerAction(refreshConversationsMissingMetadataAction)
        recurringActionService.registerAction(updateProteusToMLSMigrationStatusAction)
        recurringActionService.registerAction(refreshTeamMetadataAction)
        recurringActionService.registerAction(refreshFederationCertificatesAction)
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

    func setAnalyticsEventTracker(_ tracker: (any AnalyticsEventTracker)?) {
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
        callStateObserverToken = WireCallCenterV3.addCallStateObserver(observer: self, userSession: self)
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
        Logging.push
            .safePublic(
                "Updating badge count for \(accountID) to \(SanitizedString(stringLiteral: String(unreadCount)))"
            )
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

    private func notifyUserAboutChangesInAvailabilityBehaviourIfNeeded() {
        syncManagedObjectContext.performGroupedBlock {
            self.localNotificationDispatcher?.notifyAvailabilityBehaviourChangedIfNeeded()
        }
    }

    // MARK: Progress Events

    // temporary function to simplify call to EventProcessor
    // might be replaced by something more elegant
    public func processUpdateEvents(_ events: [ZMUpdateEvent]) {
        WaitingGroupTask(context: syncContext) {
            try? await self.updateEventProcessor?.processEvents(events)
        }
    }

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

    // MARK: Network

    public func requestResyncResources() {
        applicationStatusDirectory.requestResyncResources()
    }

    // MARK: Access Token

    private func renewAccessTokenIfNeeded(for userClient: WireDataModel.UserClient) {
        guard
            let apiVersion = BackendInfo.apiVersion,
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
        let state: NetworkState = if isNetworkOnline {
            if isPerformingSync {
                .onlineSynchronizing
            } else {
                .online
            }
        } else {
            .offline
        }

        networkState = state
    }
}

// MARK: - UpdateEventProcessor

// TODO: [WPB-9089] find another way of providing the event processor to ZMissingEventTranscoder
extension ZMUserSession: UpdateEventProcessor {
    public func bufferEvents(_ events: [WireTransport.ZMUpdateEvent]) async {
        await updateEventProcessor?.bufferEvents(events)
    }

    public func processEvents(_ events: [WireTransport.ZMUpdateEvent]) async throws {
        try await updateEventProcessor?.processEvents(events)
    }

    public func processBufferedEvents() async throws {
        try await updateEventProcessor?.processBufferedEvents()
    }
}

// MARK: - ZMSyncStateDelegate

extension ZMUserSession: ZMSyncStateDelegate {

    public func didStartSlowSync() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.notificationDispatcher.isEnabled = false
            self?.updateNetworkState()
        }
    }

    public func didFinishSlowSync() {
        managedObjectContext.performGroupedBlock { [weak self] in
            guard let self else { return }

            managedObjectContext.resetMigrationNeedsSlowSyncFlagIfNeeded()
            managedObjectContext.resetMigrationNeedsSyncResoucesFlagIfNeeded()

            hasCompletedInitialSync = true
            notificationDispatcher.isEnabled = true
            delegate?.clientCompletedInitialSync(accountId: account.userIdentifier)

            NotificationInContext(
                name: .initialSync,
                context: notificationContext
            ).post()
        }

        let selfClient = ZMUser.selfUser(in: syncContext).selfClient()

        if selfClient?.hasRegisteredMLSClient == true {
            Task {
                do {
                    try await mlsService.repairOutOfSyncConversations()
                } catch {
                    WireLogger.mls.error("Repairing out of sync conversations failed: \(error)")
                }
            }
        }
    }

    public func didStartQuickSync() {
        WireLogger.sync.debug("did start quick sync")
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.updateNetworkState()
        }
    }

    public func didFinishQuickSync() {
        WireLogger.sync.debug("did finish quick sync")
        processEvents()

        NotificationInContext(
            name: .quickSyncCompletedNotification,
            context: notificationContext
        ).post()

        WaitingGroupTask(context: syncContext) { [self] in
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
                    mlsFeature: mlsFeature
                )
            } else {
                WireLogger.mls.warn("`qualifiedClientID` is missing for selfClient")
            }

            if mlsFeature.isEnabled {
                mlsService.commitPendingProposalsIfNeeded()
            }

            await calculateSelfSupportedProtocolsIfNeeded()
            await resolveOneOnOneConversationsIfNeeded()

            let useCase = PerformPostMembershipCleanUpUseCase(context: managedObjectContext, userID: nil)
            do {
                try await useCase.invoke()
            } catch {
                WireLogger.individualToTeamMigration.error("Error performing post membership cleanup")
            }
        }

        recurringActionService.performActionsIfNeeded()
        performPostQuickSyncE2EIActions()
    }

    /// Calculate supported protocols for self user in case they are empty
    /// - note: Supported protocols are calculated only during slow sync
    /// or while resolving 1-1 conversations (MLS enabled).
    /// It fixes users that updates to latest version without having a supported-protocol.
    /// This could be removed once MLS is enabled.
    private func calculateSelfSupportedProtocolsIfNeeded() async {
        await syncContext.perform { [syncContext] in
            let service = SupportedProtocolsService(context: syncContext)
            let selfUser = ZMUser.selfUser(in: syncContext)
            if selfUser.supportedProtocols.isEmpty {
                WireLogger.supportedProtocols.warn("no supported protocols found")
                selfUser.supportedProtocols = service.calculateSupportedProtocols()
                syncContext.saveOrRollback()
            }
        }
    }

    private func makeResolveOneOnOneConversationsUseCase(context: NSManagedObjectContext)
        -> any ResolveOneOnOneConversationsUseCaseProtocol {
        let supportedProtocolService = SupportedProtocolsService(context: context)
        let resolver = OneOnOneResolver(
            migrator: OneOnOneMigrator(mlsService: mlsService),
            isMLSEnabled: mlsFeature.isEnabled
        )

        return ResolveOneOnOneConversationsUseCase(
            context: context,
            supportedProtocolService: supportedProtocolService,
            resolver: resolver
        )
    }

    private func resolveOneOnOneConversationsIfNeeded() async {
        guard mlsFeature.isEnabled else { return }

        let resolveOneOnOneUseCase = makeResolveOneOnOneConversationsUseCase(context: syncContext)
        do {
            try await resolveOneOnOneUseCase.invoke()
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
            var getFeatureConfigAction = GetFeatureConfigsAction()
            try await getFeatureConfigAction.perform(in: notificationContext)
        } catch {
            WireLogger.featureConfigs.error("Failed getFeatureConfigAction: \(String(reflecting: error))")
        }
    }

    private func fetchBackendMLSPublicKeys() async {
        do {
            var getBackendMLSPublicKeysAction = FetchBackendMLSPublicKeysAction()
            let backendPublicKeys = try await getBackendMLSPublicKeysAction.perform(in: notificationContext)
            let hasValidKeys = backendPublicKeys.removal.hasValidKeys()
            BackendInfo.isMLSEnabled = hasValidKeys
        } catch {
            WireLogger.mls.info("Backend doesn't have MLS public keys: \(String(reflecting: error))")
        }
    }

    func processEvents() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.updateNetworkState()
        }

        let groups = syncContext.enterAllGroupsExceptSecondary()
        Task {
            var processingInterrupted = false
            do {
                try await updateEventProcessor?.processBufferedEvents()
            } catch {
                processingInterrupted = true
            }

            let isSyncing = await syncContext.perform { self.applicationStatusDirectory.syncStatus.isSyncing }

            if !processingInterrupted {
                await syncContext.perform {
                    self.legacyHotFix.applyPatches()
                    // When we move to the monorepo, uncomment hotFixApplicator applyPatches
                    // hotFixApplicator.applyPatches(HotfixPatch.self, in: syncContext)
                }
            }

            await managedObjectContext.perform { [weak self] in
                self?.isPerformingSync = isSyncing || processingInterrupted
                self?.updateNetworkState()
            }
            self.syncContext.leaveAllGroups(groups)
        }
    }

    func processPendingCallEvents(completionHandler: @escaping () -> Void) {
        WireLogger.updateEvent.info("process pending call events")
        Task {
            do {
                try await updateEventProcessor!.processBufferedEvents()
                await managedObjectContext.perform {
                    completionHandler()
                }
            } catch {
                WireLogger.mls.error("Failed to process pending call events: \(String(reflecting: error))")
            }
        }
    }

    public func didRegisterSelfUserClient(_ userClient: WireDataModel.UserClient) {
        // If during registration user allowed notifications,
        // The push token can only be registered after client registration
        transportSession.pushChannel.clientID = userClient.remoteIdentifier
        registerCurrentPushToken()
        renewAccessTokenIfNeeded(for: userClient)

        WireDataModel.UserClient.triggerSelfClientCapabilityUpdate(syncContext)

        managedObjectContext.performGroupedBlock { [weak self] in
            guard
                let context = self?.managedObjectContext,
                let accountId = ZMUser.selfUser(in: context).remoteIdentifier
            else {
                return
            }

            self?.delegate?.clientRegistrationDidSucceed(accountId: accountId)
        }

        if userClient.hasRegisteredMLSClient {
            // Before the client was registered as an MLS client,
            // They wouldn't have been able to migrate any conversations from Proteus to MLS.
            // So we perform a slow sync to sync the conversations. This will ensure that
            // the message protocol of each conversation is up-to-date.
            // The client will then join any MLS groups they haven't joined yet.
            syncStatus.forceSlowSync()
        }

        let clientId = userClient.safeRemoteIdentifier.safeForLoggingDescription
        WireLogger.authentication.addTag(.selfClientId, value: clientId)
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

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
import WireSystem

@objc(ZMThirdPartyServicesDelegate)
public protocol ThirdPartyServicesDelegate: NSObjectProtocol {

    /// This will get called at a convenient point in time when Hockey and Localytics should upload their data.
    /// We try not to have Hockey and Localytics use the network while we're sync'ing.
    @objc(userSessionIsReadyToUploadServicesData:)
    func userSessionIsReadyToUploadServicesData(userSession: ZMUserSession)

}

@objc(UserSessionSelfUserClientDelegate)
public protocol UserSessionSelfUserClientDelegate: NSObjectProtocol {
    /// Invoked when a client is successfully registered
    func clientRegistrationDidSucceed(accountId: UUID)

    /// Invoked when there was an error registering the client
    func clientRegistrationDidFail(_ error: NSError, accountId: UUID)
}

@objc(UserSessionLogoutDelegate)
public protocol UserSessionLogoutDelegate: NSObjectProtocol {
    /// Invoked when the user successfully logged out
    func userDidLogout(accountId: UUID)

    /// Invoked when the authentication has proven invalid
    func authenticationInvalidated(_ error: NSError, accountId: UUID)
}

typealias UserSessionDelegate = UserSessionEncryptionAtRestDelegate
    & UserSessionSelfUserClientDelegate
    & UserSessionLogoutDelegate
    & UserSessionAppLockDelegate

@objcMembers
public class ZMUserSession: NSObject {

    private let appVersion: String
    private var tokens: [Any] = []
    private var tornDown: Bool = false

    var isNetworkOnline: Bool = true
    var isPerformingSync: Bool = true {
        willSet {
            notificationDispatcher.operationMode = newValue ? .economical : .normal
        }
    }
    var hasNotifiedThirdPartyServices: Bool = false

    var coreDataStack: CoreDataStack!
    let application: ZMApplication
    let flowManager: FlowManagerType
    var mediaManager: MediaManagerType
    var analytics: AnalyticsType?
    var transportSession: TransportSessionType
    let storedDidSaveNotifications: ContextDidSaveNotificationPersistence
    let userExpirationObserver: UserExpirationObserver
    var updateEventProcessor: UpdateEventProcessor?
    var strategyDirectory: StrategyDirectoryProtocol?
    var syncStrategy: ZMSyncStrategy?
    var operationLoop: ZMOperationLoop?
    var notificationDispatcher: NotificationDispatcher
    var localNotificationDispatcher: LocalNotificationDispatcher?
    let applicationStatusDirectory: ApplicationStatusDirectory
    var callStateObserver: CallStateObserver?
    var messageReplyObserver: ManagedObjectContextChangeObserver?
    var likeMesssageObserver: ManagedObjectContextChangeObserver?
    var urlActionProcessors: [URLActionProcessor]?
    let debugCommands: [String: DebugCommand]
    let eventProcessingTracker: EventProcessingTracker = EventProcessingTracker()
    let legacyHotFix: ZMHotFix
    // When we move to the monorepo, uncomment hotFixApplicator
    // let hotFixApplicator = PatchApplicator<HotfixPatch>(lastRunVersionKey: "lastRunHotFixVersion")
    var accessTokenRenewalObserver: AccessTokenRenewalObserver?
    var recurringActionService = RecurringActionService(
        storage: .standard,
        dateProvider: .system
    ) as RecurringActionServiceInterface

    var cryptoboxMigrationManager: CryptoboxMigrationManagerInterface
    var coreCryptoProvider: CoreCryptoProvider
    lazy var proteusService: ProteusServiceInterface = ProteusService(coreCryptoProvider: coreCryptoProvider)
    var mlsService: MLSServiceInterface
    var proteusProvider: ProteusProviding!
    let proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating

    public var syncStatus: SyncStatusProtocol {
        return applicationStatusDirectory.syncStatus
    }

    public lazy var featureRepository = FeatureRepository(context: syncContext)

    let earService: EARServiceInterface

    public var appLockController: AppLockType

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

    public var hasCompletedInitialSync: Bool = false

    public var topConversationsDirectory: TopConversationsDirectory

    public var managedObjectContext: NSManagedObjectContext { // TODO jacob we don't want this to be public
        return coreDataStack.viewContext
    }

    public var syncManagedObjectContext: NSManagedObjectContext { // TODO jacob we don't want this to be public
        return coreDataStack.syncContext
    }

    public var searchManagedObjectContext: NSManagedObjectContext { // TODO jacob we don't want this to be public
        return coreDataStack.searchContext
    }

    public var sharedContainerURL: URL { // TODO jacob we don't want this to be public
        return coreDataStack.applicationContainer
    }

    public var selfUserClient: UserClient? { // TODO jacob we don't want this to be public
        return ZMUser.selfUser(in: managedObjectContext).selfClient()
    }

    public var userProfile: UserProfile {
        return applicationStatusDirectory.userProfileUpdateStatus
    }

    public var userProfileImage: UserProfileImageUpdateProtocol {
        return applicationStatusDirectory.userProfileImageUpdateStatus
    }

    public var conversationDirectory: ConversationDirectoryType {
        return managedObjectContext.conversationListDirectory()
    }

    public private(set) var networkState: ZMNetworkState = .online {
        didSet {
            if oldValue != networkState {
                ZMNetworkAvailabilityChangeNotification.notify(networkState: networkState, userSession: self)
            }
        }
    }

    // temporary function to simplify call to EventProcessor
    // might be replaced by something more elegant
    public func processUpdateEvents(_ events: [ZMUpdateEvent]) {
        WaitingGroupTask(context: self.syncContext) {
            try? await self.updateEventProcessor?.processEvents(events)
        }
    }

    // temporary function to simplify call to ConversationEventProcessor
    // might be replaced by something more elegant
    public func processConversationEvents(_ events: [ZMUpdateEvent]) {
        WaitingGroupTask(context: self.syncContext) {
            await self.conversationEventProcessor.processConversationEvents(events)
        }
    }

    public var isNotificationContentHidden: Bool {
        get {
            guard let value = managedObjectContext.persistentStoreMetadata(forKey: LocalNotificationDispatcher.ZMShouldHideNotificationContentKey) as? NSNumber else {
                return false
            }

            return value.boolValue
        }
        set {
            managedObjectContext.setPersistentStoreMetadata(NSNumber(value: newValue), key: LocalNotificationDispatcher.ZMShouldHideNotificationContentKey)
        }
    }

    weak var delegate: UserSessionDelegate?

    // TODO remove this property and move functionality to separate protocols under UserSessionDelegate
    public weak var sessionManager: SessionManagerType?

    public weak var thirdPartyServicesDelegate: ThirdPartyServicesDelegate?

    // MARK: - Tear down

    deinit {
        require(tornDown, "tearDown must be called before the ZMUserSession is deallocated")
    }

    public func tearDown() {
        guard !tornDown else { return }

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

        // Wait for all sync operations to finish
        syncManagedObjectContext.performGroupedBlockAndWait { }

        let uiMOC = coreDataStack.viewContext
        coreDataStack = nil

        let shouldWaitOnUIMoc = !(OperationQueue.current == OperationQueue.main && uiMOC.concurrencyType == .mainQueueConcurrencyType)
        if shouldWaitOnUIMoc {
            uiMOC.performAndWait {
                // warning: this will hang if the uiMoc queue is same as self.requestQueue (typically uiMoc queue is the main queue)
            }
        }

        NotificationCenter.default.removeObserver(self)

        tornDown = true
    }

    /// - Note: this is safe if coredataStack and proteus are ready
    public lazy var getUserClientFingerprint: GetUserClientFingerprintUseCaseProtocol = {
        GetUserClientFingerprintUseCase(syncContext: coreDataStack.syncContext,
                                        transportSession: transportSession,
                                        proteusProvider: proteusProvider)
    }()

    public lazy var enrollE2eICertificate: EnrollE2eICertificateUseCaseInterface? = {
        guard let acmeDiscoveryPath = e2eiFeature.config.acmeDiscoveryUrl else {
            return nil
        }
        let acmeApi = AcmeAPI(acmeDiscoveryPath: acmeDiscoveryPath)
        let httpClient = HttpClientImpl(
            transportSession: transportSession,
            queue: syncContext
        )

        let apiProvider = APIProvider(httpClient: httpClient)

        let e2eiSetupService = E2eISetupService(coreCryptoProvider: coreCryptoProvider)

        let keyRotator = E2eIKeyPackageRotator(
            coreCryptoProvider: coreCryptoProvider,
            conversationEventProcessor: conversationEventProcessor,
            context: syncContext
        )

        let e2eiRepository = E2eIRepository(
            acmeApi: acmeApi,
            apiProvider: apiProvider,
            e2eiSetupService: e2eiSetupService,
            keyRotator: keyRotator,
            coreCryptoProvider: coreCryptoProvider
        )

        return EnrollE2eICertificateUseCase(e2eiRepository: e2eiRepository)
    }()

    public private(set) lazy var getIsE2eIdentityEnabled: GetIsE2EIdentityEnabledUseCaseProtocol =  {
        return GetIsE2EIdentityEnabledUseCase(coreCryptoProvider: coreCryptoProvider)
    }()

    public private(set) lazy var getE2eIdentityCertificates: GetE2eIdentityCertificatesUseCaseProtocol = {
        return GetE2eIdentityCertificatesUseCase(coreCryptoProvider: coreCryptoProvider)
    }()

    lazy var mlsConversationVerificationManager: MLSConversationVerificationManager = {
        let verificationStatusService = E2eIVerificationStatusService(coreCryptoProvider: coreCryptoProvider)
        let verificationStatusProvider = MLSConversationVerificationStatusProvider(
            e2eIVerificationStatusService: verificationStatusService,
            syncContext: syncContext)

        return MLSConversationVerificationManager(
            mlsService: mlsService,
            mlsConversationVerificationStatusProvider: verificationStatusProvider)
    }()

    public lazy var changeUsername: ChangeUsernameUseCaseProtocol = {
        ChangeUsernameUseCase(userProfile: applicationStatusDirectory.userProfileUpdateStatus)
    }()

    let lastEventIDRepository: LastEventIDRepositoryInterface
    let conversationEventProcessor: ConversationEventProcessor

    public init(
        userId: UUID,
        transportSession: TransportSessionType,
        mediaManager: MediaManagerType,
        flowManager: FlowManagerType,
        analytics: AnalyticsType?,
        eventProcessor: UpdateEventProcessor? = nil,
        strategyDirectory: StrategyDirectoryProtocol? = nil,
        syncStrategy: ZMSyncStrategy? = nil,
        operationLoop: ZMOperationLoop? = nil,
        application: ZMApplication,
        appVersion: String,
        coreDataStack: CoreDataStack,
        configuration: Configuration,
        earService: EARServiceInterface? = nil,
        mlsService: MLSServiceInterface? = nil,
        cryptoboxMigrationManager: CryptoboxMigrationManagerInterface,
        proteusToMLSMigrationCoordinator: ProteusToMLSMigrationCoordinating? = nil,
        sharedUserDefaults: UserDefaults
    ) {
        coreDataStack.syncContext.performGroupedBlockAndWait {
            coreDataStack.syncContext.analytics = analytics
            coreDataStack.syncContext.zm_userInterface = coreDataStack.viewContext
        }

        coreDataStack.viewContext.zm_sync = coreDataStack.syncContext

        self.application = application
        self.appVersion = appVersion
        self.flowManager = flowManager
        self.mediaManager = mediaManager
        self.analytics = analytics
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.notificationDispatcher = NotificationDispatcher(managedObjectContext: coreDataStack.viewContext)
        self.storedDidSaveNotifications = ContextDidSaveNotificationPersistence(accountContainer: coreDataStack.accountContainer)
        self.userExpirationObserver = UserExpirationObserver(managedObjectContext: coreDataStack.viewContext)
        self.topConversationsDirectory = TopConversationsDirectory(managedObjectContext: coreDataStack.viewContext)
        self.debugCommands = ZMUserSession.initDebugCommands()
        self.legacyHotFix = ZMHotFix(syncMOC: coreDataStack.syncContext)
        self.appLockController = AppLockController(userId: userId, selfUser: .selfUser(in: coreDataStack.viewContext), legacyConfig: configuration.appLockConfig)
        self.coreCryptoProvider = CoreCryptoProvider(
            selfUserID: userId,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: coreDataStack.accountContainer,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: cryptoboxMigrationManager)
        self.lastEventIDRepository = LastEventIDRepository(
            userID: userId,
            sharedUserDefaults: sharedUserDefaults
        )
        self.applicationStatusDirectory = ApplicationStatusDirectory(
            withManagedObjectContext: self.coreDataStack.syncContext,
            cookieStorage: transportSession.cookieStorage,
            requestCancellation: transportSession,
            application: application,
            lastEventIDRepository: lastEventIDRepository,
            analytics: analytics
        )
        self.earService = earService ?? EARService(
            accountID: coreDataStack.account.userIdentifier,
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext,
                coreDataStack.searchContext
            ],
            canPerformKeyMigration: true,
            sharedUserDefaults: sharedUserDefaults
        )
        self.mlsService = mlsService ?? MLSService(
            context: coreDataStack.syncContext,
            coreCryptoProvider: coreCryptoProvider,
            conversationEventProcessor: ConversationEventProcessor(context: coreDataStack.syncContext),
            userDefaults: .standard,
            syncStatus: applicationStatusDirectory.syncStatus,
            userID: coreDataStack.account.userIdentifier)
        self.cryptoboxMigrationManager = cryptoboxMigrationManager
        self.conversationEventProcessor = ConversationEventProcessor(context: coreDataStack.syncContext)

        self.proteusToMLSMigrationCoordinator = proteusToMLSMigrationCoordinator ?? ProteusToMLSMigrationCoordinator(
            context: coreDataStack.syncContext,
            userID: userId
        )

        super.init()

        // As we move the flag value from CoreData to UserDefaults, we set an initial value
        self.earService.setInitialEARFlagValue(viewContext.encryptMessagesAtRest)
        self.earService.delegate = self
        appLockController.delegate = self
        applicationStatusDirectory.syncStatus.syncStateDelegate = self
        applicationStatusDirectory.clientRegistrationStatus.registrationStatusDelegate = self

        configureCaches()

        syncManagedObjectContext.performGroupedBlockAndWait { [self] in
            self.localNotificationDispatcher = LocalNotificationDispatcher(in: coreDataStack.syncContext)
            self.configureTransportSession()

            // need to be before we create strategies since it is passed
            self.proteusProvider = ProteusProvider(proteusService: self.proteusService,
                                                   keyStore: self.syncManagedObjectContext.zm_cryptKeyStore)

            self.strategyDirectory = strategyDirectory ?? self.createStrategyDirectory(useLegacyPushNotifications: configuration.useLegacyPushNotifications)
            self.updateEventProcessor = eventProcessor ?? self.createUpdateEventProcessor()
            self.syncStrategy = syncStrategy ?? self.createSyncStrategy()
            self.operationLoop = operationLoop ?? self.createOperationLoop()
            self.urlActionProcessors = self.createURLActionProcessors()
            self.callStateObserver = CallStateObserver(localNotificationDispatcher: self.localNotificationDispatcher!,
                                                       contextProvider: self,
                                                       callNotificationStyleProvider: self)

            // FIXME: [WPB-5827] inject instead of storing on context - [jacob]
            self.syncManagedObjectContext.proteusService = self.proteusService
            self.syncManagedObjectContext.mlsService = self.mlsService

            applicationStatusDirectory.clientRegistrationStatus.prepareForClientRegistration()
            self.applicationStatusDirectory.syncStatus.determineInitialSyncPhase()
            self.applicationStatusDirectory.clientUpdateStatus.determineInitialClientStatus()
            self.applicationStatusDirectory.clientRegistrationStatus.determineInitialRegistrationStatus()
            self.hasCompletedInitialSync = self.applicationStatusDirectory.syncStatus.isSlowSyncing == false

            createMLSClientIfNeeded()

            if e2eiFeature.isEnabled {
                mlsConversationVerificationManager.startObservingMLSConversationVerificationStatus()
            }
        }

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
        updateSupportedProtocolsIfNeeded()
    }

    private func updateSupportedProtocolsIfNeeded() {
        let recurringAction = RecurringAction(
            id: "\(account.userIdentifier).updateSupportedProtocols",
            interval: .oneDay
        ) { [weak self] in
            guard let context = self?.syncContext else { return }

            context.perform {
                let service = SupportedProtocolsService(context: context)
                service.updateSupportedProtocols()
            }
        }

        recurringActionService.registerAction(recurringAction)
    }

    private func configureTransportSession() {
        transportSession.pushChannel.clientID = selfUserClient?.remoteIdentifier
        transportSession.setNetworkStateDelegate(self)
        transportSession.setAccessTokenRenewalFailureHandler { [weak self] (response) in
            self?.transportSessionAccessTokenDidFail(response: response)
        }
        transportSession.setAccessTokenRenewalSuccessHandler { [weak self]  _, _ in
            self?.transportSessionAccessTokenDidSucceed()
        }
    }

    private func configureCaches() {
        let cacheLocation = FileManager.default.cachesURLForAccount(with: coreDataStack.account.userIdentifier, in: coreDataStack.applicationContainer)
        ZMUserSession.moveCachesIfNeededForAccount(with: coreDataStack.account.userIdentifier, in: coreDataStack.applicationContainer)

        let userImageCache = UserImageLocalCache(location: cacheLocation)
        let fileAssetCache = FileAssetCache(location: cacheLocation)

        managedObjectContext.zm_userImageCache = userImageCache
        managedObjectContext.zm_fileAssetCache = fileAssetCache
        managedObjectContext.zm_searchUserCache = NSCache()

        syncManagedObjectContext.performGroupedBlockAndWait {
            self.syncManagedObjectContext.zm_userImageCache = userImageCache
            self.syncManagedObjectContext.zm_fileAssetCache = fileAssetCache
        }

    }

    private func createStrategyDirectory(useLegacyPushNotifications: Bool) -> StrategyDirectoryProtocol {
        return StrategyDirectory(
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
            proteusProvider: self.proteusProvider,
            mlsService: mlsService,
            coreCryptoProvider: coreCryptoProvider
        )
    }

    private func createUpdateEventProcessor() -> EventProcessor {
        return EventProcessor(
            storeProvider: self.coreDataStack,
            eventProcessingTracker: eventProcessingTracker,
            earService: earService,
            eventConsumers: strategyDirectory?.eventConsumers ?? [],
            eventAsyncConsumers: (strategyDirectory?.eventAsyncConsumers ?? []) + [conversationEventProcessor]
        )
    }

    private func createURLActionProcessors() -> [URLActionProcessor] {
        return [
            DeepLinkURLActionProcessor(contextProvider: coreDataStack,
                                       transportSession: transportSession,
                                       eventProcessor: updateEventProcessor!),
            ConnectToBotURLActionProcessor(contextprovider: coreDataStack,
                                           transportSession: transportSession,
                                           eventProcessor: updateEventProcessor!)
        ]
    }

    private func createSyncStrategy() -> ZMSyncStrategy {
        return ZMSyncStrategy(contextProvider: coreDataStack,
                              notificationsDispatcher: notificationDispatcher,
                              applicationStatusDirectory: applicationStatusDirectory,
                              application: application,
                              strategyDirectory: strategyDirectory!,
                              eventProcessingTracker: eventProcessingTracker)
    }

    private func createOperationLoop() -> ZMOperationLoop {
        return ZMOperationLoop(transportSession: transportSession,
                               requestStrategy: syncStrategy,
                               updateEventProcessor: updateEventProcessor!,
                               applicationStatusDirectory: applicationStatusDirectory,
                               uiMOC: managedObjectContext,
                               syncMOC: syncManagedObjectContext)
    }

    private func configureRecurringActions() {
        recurringActionService.registerAction(refreshUsersMissingMetadataAction)
        recurringActionService.registerAction(refreshConversationsMissingMetadataAction)
        recurringActionService.registerAction(updateProteusToMLSMigrationStatusAction)
        recurringActionService.registerAction(refreshTeamMetadataAction)
    }

    func startRequestLoopTracker() {
        transportSession.requestLoopDetectionCallback = { path in
            guard !path.hasSuffix("/typing") else { return }

            Logging.network.warn("Request loop happening at path: \(path)")

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name(rawValue: ZMLoggingRequestLoopNotificationName),
                                                object: nil,
                                                userInfo: ["path": path])
            }
        }
    }

    private func registerForCalculateBadgeCountNotification() {
        tokens.append(NotificationInContext.addObserver(name: .calculateBadgeCount, context: managedObjectContext.notificationContext) { [weak self] (_) in
            self?.calculateBadgeCount()
        })
    }

    /// Count number of conversations with unread messages and update the application icon badge count.
    private func calculateBadgeCount() {
        let accountID = coreDataStack.account.userIdentifier
        let unreadCount = Int(ZMConversation.unreadConversationCount(in: self.syncManagedObjectContext))
        Logging.push.safePublic("Updating badge count for \(accountID) to \(SanitizedString(stringLiteral: String(unreadCount)))")
        self.sessionManager?.updateAppIconBadge(accountID: accountID, unreadCount: unreadCount)
    }

    private func registerForBackgroundNotifications() {
        application.registerObserverForDidEnterBackground(self, selector: #selector(applicationDidEnterBackground(_:)))
        application.registerObserverForWillEnterForeground(self, selector: #selector(applicationWillEnterForeground(_:)))

    }

    private func enableBackgroundFetch() {
        // We enable background fetch by setting the minimum interval to something different from UIApplicationBackgroundFetchIntervalNever
        application.setMinimumBackgroundFetchInterval(10.0 * 60.0 + Double.random(in: 0..<300))
    }

    private func notifyUserAboutChangesInAvailabilityBehaviourIfNeeded() {
        syncManagedObjectContext.performGroupedBlock {
            self.localNotificationDispatcher?.notifyAvailabilityBehaviourChangedIfNeeded()
        }
    }

    func createMLSClientIfNeeded() {
        // TODO: [WPB-6198] refactor out - [jacob]
        if applicationStatusDirectory.clientRegistrationStatus.needsToRegisterMLSCLient {
            WaitingGroupTask(context: syncContext) { [self] in
                do {
                    // Make sure MLS client exists, mls public keys will be generated upon creation
                    _ = try await coreCryptoProvider.coreCrypto(requireMLS: true)
                } catch {
                    WireLogger.mls.error("Failed to create MLS client: \(error)")
                }
            }
        }
    }

    // MARK: - Network

    public func requestSlowSync() {
        applicationStatusDirectory.requestSlowSync()
    }

    // MARK: - Access Token

    private func renewAccessTokenIfNeeded(for userClient: UserClient) {
        guard
            let apiVersion = BackendInfo.apiVersion,
            apiVersion > .v2,
            let clientID = userClient.remoteIdentifier
        else { return }

        renewAccessToken(with: clientID)
    }

    // MARK: - Perform changes

    public func saveOrRollbackChanges() {
        managedObjectContext.saveOrRollback()
    }

    @objc(performChanges:)
    public func perform(_ changes: @escaping () -> Void) {
        managedObjectContext.performGroupedBlockAndWait { [weak self] in
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

            group?.notify(on: DispatchQueue.global(qos: .background), block: {
                self?.managedObjectContext.performGroupedBlock {
                    completionHandler?()
                }
            })
        }
    }

    // MARK: - Account

    public func initiateUserDeletion() {
        syncManagedObjectContext.performGroupedBlock {
            self.syncManagedObjectContext.setPersistentStoreMetadata(NSNumber(value: true), key: DeleteAccountRequestStrategy.userDeletionInitiatedKey)
            RequestAvailableNotification.notifyNewRequestsAvailable(self)
        }
    }

}

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
        let state: ZMNetworkState

        if isNetworkOnline {
            if isPerformingSync {
                state = .onlineSynchronizing
            } else {
                state = .online
            }
        } else {
            state = .offline
        }

        networkState = state
    }
}
// swiftlint:disable todo_requires_jira_link
// TODO: [jacob] find another way of providing the event processor to ZMissingEventTranscoder
// swiftlint:enable todo_requires_jira_link
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
            self?.hasCompletedInitialSync = true
            self?.notificationDispatcher.isEnabled = true

            if let context = self?.managedObjectContext {
                ZMUserSession.notifyInitialSyncCompleted(context: context)
            }
        }

        let selfClient = ZMUser.selfUser(in: syncContext).selfClient()
        if selfClient?.hasRegisteredMLSClient == true {
            Task {
                await mlsService.repairOutOfSyncConversations()
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
            context: syncContext.notificationContext
        ).post()

        let selfClient = ZMUser.selfUser(in: syncContext).selfClient()
        if selfClient?.hasRegisteredMLSClient == true {

            WaitingGroupTask(context: syncContext) { [self] in
                // these operations are not dependent and should not be executed in same do/catch
                do {
                    // rework implementation of following method - WPB-6053
                    try await mlsService.performPendingJoins()
                } catch {
                    Logging.mls.error("Failed to performPendingJoins: \(String(reflecting: error))")
                }

                do {
                    try await mlsService.commitPendingProposals()
                } catch {
                    Logging.mls.error("Failed to commit pending proposals: \(String(reflecting: error))")
                }
                await mlsService.uploadKeyPackagesIfNeeded()
                await mlsService.updateKeyMaterialForAllStaleGroupsIfNeeded()
            }
        }

        fetchFeatureConfigs()
        recurringActionService.performActionsIfNeeded()

        managedObjectContext.performGroupedBlock { [weak self] in
            self?.notifyThirdPartyServices()
        }
    }

    func processEvents() {
        managedObjectContext.performGroupedBlock { [weak self] in
            self?.isPerformingSync = true
            self?.updateNetworkState()
        }

        let groups = self.syncContext.enterAllGroupsExceptSecondary()
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

            await managedObjectContext.perform(schedule: .enqueued) { [weak self] in
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
                Logging.mls.error("Failed to process pending call events: \(String(reflecting: error))")
            }
        }
    }

    // swiftlint:disable todo_requires_jira_link
    // FIXME: [jacob] move commitPendingProposalsIfNeeded to MLSService?
    // swiftlint:enable todo_requires_jira_link
    private func commitPendingProposalsIfNeeded() {
        Task {
            do {
                try await mlsService.commitPendingProposals()
            } catch {
                Logging.mls.error("Failed to commit pending proposals: \(String(describing: error))")
            }
        }
    }

    private func fetchFeatureConfigs() {
        let action = GetFeatureConfigsAction { [weak self] result in
            switch result {
            case .success:
                guard let context = self?.syncContext else {
                    return
                }

                context.perform {
                    let service = SupportedProtocolsService(context: context)
                    service.updateSupportedProtocols()
                }

            case .failure(let reason):
                Logging.network.error("Failed to fetch feature configs: \(String(describing: reason))")
            }
        }

        action.send(in: syncContext.notificationContext)
    }

    public func didRegisterSelfUserClient(_ userClient: UserClient) {
        // If during registration user allowed notifications,
        // The push token can only be registered after client registration
        transportSession.pushChannel.clientID = userClient.remoteIdentifier
        registerCurrentPushToken()
        renewAccessTokenIfNeeded(for: userClient)

        UserClient.triggerSelfClientCapabilityUpdate(syncContext)

        managedObjectContext.performGroupedBlock { [weak self] in
            guard let accountId = self?.managedObjectContext.selfUserId else {
                return
            }

            self?.delegate?.clientRegistrationDidSucceed(accountId: accountId)
        }
    }

    public func didFailToRegisterSelfUserClient(error: Error) {
        managedObjectContext.performGroupedBlock {  [weak self] in
            guard let accountId = self?.managedObjectContext.selfUserId else {
                return
            }

            self?.delegate?.clientRegistrationDidFail(error as NSError, accountId: accountId)
        }
    }

    public func didDeleteSelfUserClient(error: Error) {
        notifyAuthenticationInvalidated(error)
    }

    public func notifyThirdPartyServices() {
        if !hasNotifiedThirdPartyServices {
            hasNotifiedThirdPartyServices = true
            thirdPartyServicesDelegate?.userSessionIsReadyToUploadServicesData(userSession: self)
        }
    }

    func notifyAuthenticationInvalidated(_ error: Error) {
        WireLogger.authentication.debug("notifying authentication invalidated")
        managedObjectContext.performGroupedBlock {  [weak self] in
            guard let accountId = self?.managedObjectContext.selfUserId else {
                return
            }

            self?.delegate?.authenticationInvalidated(error as NSError, accountId: accountId)
        }
    }
}

extension ZMUserSession: URLActionProcessor {
    func process(urlAction: URLAction, delegate: PresentationDelegate?) {
        urlActionProcessors?.forEach({ $0.process(urlAction: urlAction, delegate: delegate)})
    }
}

private extension NSManagedObjectContext {
    var selfUserId: UUID? {
        ZMUser.selfUser(in: self).remoteIdentifier
    }
}

extension ZMUserSession: ContextProvider {

    public var account: Account {
        return coreDataStack.account
    }

    public var viewContext: NSManagedObjectContext {
        return coreDataStack.viewContext
    }

    public var syncContext: NSManagedObjectContext {
        return coreDataStack.syncContext
    }

    public var searchContext: NSManagedObjectContext {
        return coreDataStack.searchContext
    }

    public var eventContext: NSManagedObjectContext {
        return coreDataStack.eventContext
    }

}

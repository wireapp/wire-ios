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
import WireLinkPreview
import WireRequestStrategy
import WireTransport

// MARK: - PushMessageHandlerDummy

final class PushMessageHandlerDummy: NSObject, PushMessageHandler {
    func didFailToSend(_: ZMMessage) {
        // nop
    }
}

// MARK: - ClientRegistrationStatus

final class ClientRegistrationStatus: NSObject, ClientRegistrationDelegate {
    // MARK: Lifecycle

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: Internal

    let context: NSManagedObjectContext

    var clientIsReadyForRequests: Bool {
        if let clientId = context
            .persistentStoreMetadata(forKey: ZMPersistedClientIdKey) as? String {
            // TODO: move constant into shared framework
            return !clientId.isEmpty
        }

        return false
    }

    func didDetectCurrentClientDeletion() {
        // nop
    }
}

// MARK: - AuthenticationStatus

final class AuthenticationStatus: AuthenticationStatusProvider {
    // MARK: Lifecycle

    init(transportSession: ZMTransportSession) {
        self.transportSession = transportSession
    }

    // MARK: Internal

    let transportSession: ZMTransportSession

    var state: AuthenticationState {
        isLoggedIn ? .authenticated : .unauthenticated
    }

    // MARK: Private

    private var isLoggedIn: Bool {
        transportSession.cookieStorage.hasAuthenticationCookie
    }
}

extension BackendEnvironmentProvider {
    func cookieStorage(for account: Account) -> ZMPersistentCookieStorage {
        let backendURL = backendURL.host!
        return ZMPersistentCookieStorage(
            forServerName: backendURL,
            userIdentifier: account.userIdentifier,
            useCache: false
        )
    }

    public func isAuthenticated(_ account: Account) -> Bool {
        cookieStorage(for: account).hasAuthenticationCookie
    }
}

// MARK: - ApplicationStatusDirectory

final class ApplicationStatusDirectory: ApplicationStatus {
    // MARK: Lifecycle

    public init(
        transportSession: ZMTransportSession,
        authenticationStatus: AuthenticationStatusProvider,
        clientRegistrationStatus: ClientRegistrationStatus,
        linkPreviewDetector: LinkPreviewDetectorType
    ) {
        self.transportSession = transportSession
        self.authenticationStatus = authenticationStatus
        self.clientRegistrationStatus = clientRegistrationStatus
        self.linkPreviewDetector = linkPreviewDetector
    }

    public convenience init(syncContext: NSManagedObjectContext, transportSession: ZMTransportSession) {
        let authenticationStatus = AuthenticationStatus(transportSession: transportSession)
        let clientRegistrationStatus = ClientRegistrationStatus(context: syncContext)
        let linkPreviewDetector = LinkPreviewDetector()
        self.init(
            transportSession: transportSession,
            authenticationStatus: authenticationStatus,
            clientRegistrationStatus: clientRegistrationStatus,
            linkPreviewDetector: linkPreviewDetector
        )
    }

    // MARK: Public

    /// The authentication status used to verify a user is authenticated
    public let authenticationStatus: AuthenticationStatusProvider

    /// The client registration status used to lookup if a user has registered a self client
    public let clientRegistrationStatus: ClientRegistrationDelegate

    public let linkPreviewDetector: LinkPreviewDetectorType

    public var synchronizationState: SynchronizationState {
        if clientRegistrationStatus.clientIsReadyForRequests {
            .online
        } else {
            .unauthenticated
        }
    }

    public var operationState: OperationState {
        .foreground
    }

    public var clientRegistrationDelegate: ClientRegistrationDelegate {
        clientRegistrationStatus
    }

    public var requestCancellation: ZMRequestCancellation {
        transportSession
    }

    // MARK: Internal

    let transportSession: ZMTransportSession

    func requestResyncResources() {
        // we don't resync Resources in the share engine
    }
}

// MARK: - SharingSession

/// A Wire session to share content from a share extension
/// - note: this is the entry point of this framework. Users of
/// the framework should create an instance as soon as possible in
/// the lifetime of the extension, and hold on to that session
/// for the entire lifetime.
/// - warning: creating multiple sessions in the same process
/// is not supported and will result in undefined behaviour
public final class SharingSession {
    // MARK: Lifecycle

    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown

    public convenience init(
        applicationGroupIdentifier: String,
        accountIdentifier: UUID,
        hostBundleIdentifier: String,
        environment: BackendEnvironmentProvider,
        appLockConfig: AppLockController.LegacyConfig?,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String?
    ) throws {
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)

        let coreDataStack = CoreDataStack(
            account: Account(userName: "", userIdentifier: accountIdentifier),
            applicationContainer: sharedContainerURL
        )

        guard coreDataStack.storesExists else {
            throw InitializationError.missingSharedContainer
        }

        guard !coreDataStack.needsMigration  else {
            throw InitializationError.needsMigration
        }

        var storeError: Error?
        coreDataStack.loadStores { _ in
            storeError = storeError
        }

        guard storeError == nil else {
            throw InitializationError.missingSharedContainer
        }

        // Don't cache the cookie because if the user logs out and back in again in the main app
        // process, then the cached cookie will be invalid.
        let cookieStorage = ZMPersistentCookieStorage(
            forServerName: environment.backendURL.host!,
            userIdentifier: accountIdentifier,
            useCache: false
        )
        let reachabilityGroup = ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Sharing session reachability")
        let serverNames = [environment.backendURL, environment.backendWSURL].compactMap(\.host)
        let reachability = ZMReachability(serverNames: serverNames, group: reachabilityGroup)

        let credentials = environment.proxy.flatMap { ProxyCredentials.retrieve(for: $0) }

        let transportSession = ZMTransportSession(
            environment: environment,
            proxyUsername: credentials?.username,
            proxyPassword: credentials?.password,
            cookieStorage: cookieStorage,
            reachability: reachability,
            initialAccessToken: nil,
            applicationGroupIdentifier: applicationGroupIdentifier,
            applicationVersion: "1.0.0",
            minTLSVersion: minTLSVersion
        )

        try self.init(
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: FileManager.default.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL),
            accountContainer: CoreDataStack.accountDataFolder(
                accountIdentifier: accountIdentifier,
                applicationContainer: sharedContainerURL
            ),
            appLockConfig: appLockConfig,
            sharedUserDefaults: sharedUserDefaults
        )
    }

    init(
        accountIdentifier: UUID,
        coreDataStack: CoreDataStack,
        transportSession: ZMTransportSession,
        cachesDirectory: URL,
        saveNotificationPersistence: ContextDidSaveNotificationPersistence,
        analyticsEventPersistence: ShareExtensionAnalyticsPersistence,
        applicationStatusDirectory: ApplicationStatusDirectory,
        operationLoop: RequestGeneratingOperationLoop,
        strategyFactory: StrategyFactory,
        appLockConfig: AppLockController.LegacyConfig?,
        cryptoboxMigrationManager: CryptoboxMigrationManagerInterface,
        earService: EARServiceInterface,
        contextStorage: LAContextStorable,
        proteusService: ProteusServiceInterface,
        mlsDecryptionService: MLSDecryptionServiceInterface,
        sharedUserDefaults: UserDefaults
    ) throws {
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.saveNotificationPersistence = saveNotificationPersistence
        self.analyticsEventPersistence = analyticsEventPersistence
        self.applicationStatusDirectory = applicationStatusDirectory
        self.operationLoop = operationLoop
        self.strategyFactory = strategyFactory

        self.earService = earService
        self.contextStorage = contextStorage

        let selfUser = ZMUser.selfUser(in: coreDataStack.viewContext)
        self.appLockController = AppLockController(
            userId: accountIdentifier,
            selfUser: selfUser,
            legacyConfig: appLockConfig,
            authenticationContext: AuthenticationContext(storage: contextStorage)
        )

        guard applicationStatusDirectory.authenticationStatus.state == .authenticated
        else {
            throw InitializationError.loggedOut
        }

        let accountDirectory = coreDataStack.accountContainer
        guard !cryptoboxMigrationManager.isMigrationNeeded(accountDirectory: accountDirectory) else {
            throw InitializationError.pendingCryptoboxMigration
        }

        coreDataStack.syncContext.performAndWait {
            if DeveloperFlag.proteusViaCoreCrypto.isOn, coreDataStack.syncContext.proteusService == nil {
                coreDataStack.syncContext.proteusService = proteusService
            }

            if DeveloperFlag.enableMLSSupport.isOn, coreDataStack.syncContext.mlsDecryptionService == nil {
                coreDataStack.syncContext.mlsDecryptionService = mlsDecryptionService
            }
        }

        setupCaches(at: cachesDirectory)
        setupObservers()
    }

    public convenience init(
        accountIdentifier: UUID,
        coreDataStack: CoreDataStack,
        transportSession: ZMTransportSession,
        cachesDirectory: URL,
        accountContainer: URL,
        appLockConfig: AppLockController.LegacyConfig?,
        sharedUserDefaults: UserDefaults
    ) throws {
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
            transportSession: transportSession
        )

        let requestGeneratorStore = RequestGeneratorStore(strategies: strategyFactory.strategies)

        let operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )

        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)
        let analyticsEventPersistence = ShareExtensionAnalyticsPersistence(accountContainer: accountContainer)

        let cryptoboxMigrationManager = CryptoboxMigrationManager()
        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: accountIdentifier,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: coreDataStack.accountContainer,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            allowCreation: false
        )
        let commitSender = CommitSender(
            coreCryptoProvider: coreCryptoProvider,
            notificationContext: coreDataStack.syncContext.notificationContext
        )
        let featureRepository = FeatureRepository(context: coreDataStack.syncContext)
        let mlsActionExecutor = MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            commitSender: commitSender,
            featureRepository: featureRepository
        )
        let contextStorage = LAContextStorage()
        let earService = EARService(
            accountID: accountIdentifier,
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext,
            ],
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: contextStorage)
        )
        let proteusService = ProteusService(coreCryptoProvider: coreCryptoProvider)
        let mlsDecryptionService = MLSDecryptionService(
            context: coreDataStack.syncContext,
            mlsActionExecutor: mlsActionExecutor
        )

        try self.init(
            accountIdentifier: accountIdentifier,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            analyticsEventPersistence: analyticsEventPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            strategyFactory: strategyFactory,
            appLockConfig: appLockConfig,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            earService: earService,
            contextStorage: contextStorage,
            proteusService: proteusService,
            mlsDecryptionService: mlsDecryptionService,
            sharedUserDefaults: sharedUserDefaults
        )
    }

    deinit {
        if let token = contextSaveObserverToken {
            NotificationCenter.default.removeObserver(token)
            contextSaveObserverToken = nil
        }
        transportSession.reachability.tearDown()
        transportSession.tearDown()
        strategyFactory.tearDown()
    }

    // MARK: Public

    /// The failure reason of a `SharingSession` initialization
    /// - NeedsMigration: The database needs a migration which is only done in the main app
    /// - LoggedOut: No user is logged in
    /// - missingSharedContainer: The shared container is missing
    public enum InitializationError: Error {
        case needsMigration, loggedOut, missingSharedContainer, pendingCryptoboxMigration
    }

    public let analyticsEventPersistence: ShareExtensionAnalyticsPersistence

    public let appLockController: AppLockType

    /// Whether all prerequsisties for sharing are met
    public var canShare: Bool {
        applicationStatusDirectory.authenticationStatus.state == .authenticated && applicationStatusDirectory
            .clientRegistrationStatus.clientIsReadyForRequests
    }

    /// List of non-archived conversations in which the user can write
    /// The list will be sorted by relevance
    public var writeableNonArchivedConversations: [Conversation] {
        directory.unarchivedConversations.writeableConversations
    }

    /// List of archived conversations in which the user can write
    public var writebleArchivedConversations: [Conversation] {
        directory.archivedConversations.writeableConversations
    }

    public var fileSharingFeature: Feature.FileSharing {
        let featureRepository = FeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchFileSharing()
    }

    public func enqueue(changes: @escaping () -> Void) {
        enqueue(changes: changes, completionHandler: nil)
    }

    public func enqueue(changes: @escaping () -> Void, completionHandler: (() -> Void)?) {
        userInterfaceContext.performGroupedBlock { [weak self] in
            changes()
            self?.userInterfaceContext.saveOrRollback()
            completionHandler?()
        }
    }

    // MARK: Internal

    let transportSession: ZMTransportSession

    let coreDataStack: CoreDataStack

    let earService: EARServiceInterface

    /// The `NSManagedObjectContext` used to retrieve the conversations
    var userInterfaceContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    // MARK: Private

    /// Directory of all application statuses
    private let applicationStatusDirectory: ApplicationStatusDirectory

    /// The list to which save notifications of the UI moc are appended and persistet
    private let saveNotificationPersistence: ContextDidSaveNotificationPersistence

    private var contextSaveObserverToken: NSObjectProtocol?

    private let operationLoop: RequestGeneratingOperationLoop

    private let strategyFactory: StrategyFactory

    private let contextStorage: LAContextStorable

    private var syncContext: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    /// The `ZMConversationListDirectory` containing all conversation lists
    private var directory: ZMConversationListDirectory {
        userInterfaceContext.conversationListDirectory()
    }

    private func setupCaches(at cachesDirectory: URL) {
        let userImageCache = UserImageLocalCache(location: cachesDirectory)
        userInterfaceContext.zm_userImageCache = userImageCache
        syncContext.zm_userImageCache = userImageCache

        let fileAssetcache = FileAssetCache(location: cachesDirectory)
        userInterfaceContext.zm_fileAssetCache = fileAssetcache
        syncContext.zm_fileAssetCache = fileAssetcache
    }

    private func setupObservers() {
        contextSaveObserverToken = NotificationCenter.default.addObserver(
            forName: contextWasMergedNotification,
            object: nil,
            queue: .main,
            using: { [weak self] note in
                self?.saveNotificationPersistence.add(note)
                DarwinNotification.shareExtDidSaveNote.post()
            }
        )
    }
}

// MARK: LinkPreviewDetectorType

extension SharingSession: LinkPreviewDetectorType {
    public func downloadLinkPreviews(
        inText text: String,
        excluding: [NSRange],
        completion: @escaping ([LinkMetadata]) -> Void
    ) {
        applicationStatusDirectory.linkPreviewDetector.downloadLinkPreviews(
            inText: text,
            excluding: excluding,
            completion: completion
        )
    }
}

// MARK: - Helper

extension ConversationList {
    fileprivate var writeableConversations: [Conversation] {
        items.filter { !$0.isReadOnly }
    }
}

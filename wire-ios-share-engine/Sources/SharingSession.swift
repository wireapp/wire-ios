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
import WireLinkPreview
import WireNetwork
import WireRequestStrategy
import WireTransport

/// A Wire session to share content from a share extension
/// - note: this is the entry point of this framework. Users of
/// the framework should create an instance as soon as possible in
/// the lifetime of the extension, and hold on to that session
/// for the entire lifetime.
/// - warning: creating multiple sessions in the same process
/// is not supported and will result in undefined behaviour
public final class SharingSession {

    /// The failure reason of a `SharingSession` initialization
    /// - NeedsMigration: The database needs a migration which is only done in the main app
    /// - LoggedOut: No user is logged in
    /// - missingSharedContainer: The shared container is missing
    public enum InitializationError: Error {
        case needsMigration
        case loggedOut
        case missingSharedContainer
        case pendingCryptoboxMigration
    }

    /// The `NSManagedObjectContext` used to retrieve the conversations
    var userInterfaceContext: NSManagedObjectContext {
        coreDataStack.viewContext
    }

    private var syncContext: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    /// Directory of all application statuses
    private let applicationStatusDirectory: ApplicationStatusDirectory

    /// The list to which save notifications of the UI moc are appended and persistet
    private let saveNotificationPersistence: ContextDidSaveNotificationPersistence

    public let analyticsEventPersistence: ShareExtensionAnalyticsPersistence

    private var contextSaveObserverToken: NSObjectProtocol?

    let transportSession: ZMTransportSession

    let coreDataStack: CoreDataStack

    /// The `ZMConversationListDirectory` containing all conversation lists
    private var directory: ZMConversationListDirectory {
        userInterfaceContext.conversationListDirectory()
    }

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

    private let operationLoop: RequestGeneratingOperationLoop

    private let strategyFactory: StrategyFactory

    public let appLockController: AppLockType

    private let contextStorage: LAContextStorable

    let earService: EARServiceInterface

    public var fileSharingFeature: Feature.FileSharing {
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.viewContext)
        return featureRepository.fetchFileSharing()
    }

    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.NeedsMigration` in case the local store needs to be
    /// migrated, which is currently only supported in the main application or `InitializationError.LoggedOut` if
    /// no user is currently logged in.
    /// - returns: The initialized session object if no error is thrown

    @MainActor
    public convenience init(
        applicationGroupIdentifier: String,
        accountIdentifier: UUID,
        hostBundleIdentifier: String,
        environment: WireTransport.BackendEnvironment,
        appLockConfig: AppLockController.LegacyConfig?,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String?,
        currentBuildNumber: String,
        localDomain: String?,
        isFederationEnabled: Bool
    ) async throws {

        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)

        let coreDataStack = CoreDataStack(
            account: Account(userName: "", userIdentifier: accountIdentifier),
            applicationContainer: sharedContainerURL,
            localDomain: localDomain,
            isFederationEnabled: isFederationEnabled
        )

        guard coreDataStack.storesExists else {
            throw InitializationError.missingSharedContainer
        }

        guard !coreDataStack.needsMigration  else {
            throw InitializationError.needsMigration
        }

        try await coreDataStack.load()

        // Don't cache the cookie because if the user logs out and back in again in the main app
        // process, then the cached cookie will be invalid.
        let cookieStorage = ZMPersistentCookieStorage(
            forServerName: environment.backendURL.host!,
            userIdentifier: accountIdentifier,
            useCache: false
        )

        let credentials = environment.proxy.flatMap { ProxyCredentials.retrieve(for: $0) }

        let selfClientID = coreDataStack.syncContext.performAndWait {
            ZMUser.selfUser(in: coreDataStack.syncContext).selfClient()?.remoteIdentifier
        }

        let transportSession = ZMTransportSession(
            environment: environment,
            proxyUsername: credentials?.username,
            proxyPassword: credentials?.password,
            cookieStorage: cookieStorage,
            reachability: environment.reachability,
            initialAccessToken: nil,
            applicationGroupIdentifier: applicationGroupIdentifier,
            applicationVersion: "1.0.0",
            minTLSVersion: minTLSVersion,
            selfClientID: selfClientID,
            // This flag only concerns the push channel which isn't relevant
            // in the sharing session.
            isSyncV2Enabled: false
        )

        let proxySettings: WireNetwork.ProxySettings? = {
            guard let proxy = environment.proxy else { return nil }

            if proxy.needsAuthentication {
                guard
                    let proxyUsername = credentials?.username,
                    let proxyPassword = credentials?.password else {
                    fatalInternal("Proxy needs authentication but credentials are missing")
                    return nil
                }

                return .authenticated(
                    host: proxy.host,
                    port: proxy.port,
                    username: proxyUsername,
                    password: proxyPassword
                )
            } else {
                return .unauthenticated(host: proxy.host, port: proxy.port)
            }
        }()

        let wireAPIBackendEnvironment = BackendEnvironment(
            url: environment.backendURL,
            webSocketURL: environment.backendWSURL,
            blacklistURL: environment.blackListURL,
            pinnedKeys: environment.trustData.map { trustData in
                PinnedKey(
                    key: trustData.certificateKey,
                    rawKey: trustData.rawCertificateKey,
                    hosts: trustData.hosts.map { host in
                        switch host.rule {
                        case .equals:
                            .equals(host.value)
                        case .endsWith:
                            .endsWith(host.value)
                        }
                    }
                )
            },
            proxySettings: proxySettings
        )

        guard let apiVersion = BackendInfo.apiVersion,
              let wireAPIVersion = WireNetwork.APIVersion(rawValue: UInt(apiVersion.rawValue)) else {
            fatal("cannot resolve api version")

        }

        try await self.init(
            accountIdentifier: accountIdentifier,
            selfClientID: selfClientID!,
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: FileManager.default.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL),
            accountContainer: CoreDataStack.accountDataFolder(
                accountIdentifier: accountIdentifier,
                applicationContainer: sharedContainerURL
            ),
            appLockConfig: appLockConfig,
            wireAPIBackendEnvironment: wireAPIBackendEnvironment,
            minTLSVersion: .minVersionFrom(minTLSVersion),
            apiVersion: wireAPIVersion,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: URL("unused")!,
            legacyEnvironment: environment,
            proxyCredentials: credentials,
            currentBuildNumber: currentBuildNumber,
            localDomain: localDomain
        )
    }

    @MainActor
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
        mlsService: MLSServiceInterface,
        mlsDecryptionService: MLSDecryptionServiceInterface,
        sharedUserDefaults: UserDefaults
    ) async throws {

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
        else { throw InitializationError.loggedOut }

        let accountDirectory = coreDataStack.accountContainer
        guard !cryptoboxMigrationManager.isMigrationNeeded(accountDirectory: accountDirectory) else {
            throw InitializationError.pendingCryptoboxMigration
        }

        coreDataStack.syncContext.performAndWait {
            if DeveloperFlag.proteusViaCoreCrypto.isOn, coreDataStack.syncContext.proteusService == nil {
                coreDataStack.syncContext.proteusService = proteusService
            }

            let mlsFeature = LegacyFeatureRepository(context: coreDataStack.syncContext).fetchMLS()
            if mlsFeature.isEnabled {
                if coreDataStack.syncContext.mlsDecryptionService == nil {
                    coreDataStack.syncContext.mlsDecryptionService = mlsDecryptionService
                }

                if coreDataStack.syncContext.mlsService == nil {
                    coreDataStack.syncContext.mlsService = mlsService
                }
            }
        }

        setupCaches(at: cachesDirectory)
        setupObservers()
    }

    @MainActor
    public convenience init(
        accountIdentifier: UUID,
        selfClientID: String,
        coreDataStack: CoreDataStack,
        transportSession: ZMTransportSession,
        cachesDirectory: URL,
        accountContainer: URL,
        appLockConfig: AppLockController.LegacyConfig?,
        wireAPIBackendEnvironment: WireNetwork.BackendEnvironment,
        minTLSVersion: WireNetwork.TLSVersion,
        apiVersion: WireNetwork.APIVersion,
        sharedUserDefaults: UserDefaults,
        sharedContainerURL: URL,
        legacyEnvironment: WireTransport.BackendEnvironment,
        proxyCredentials: WireTransport.ProxyCredentials?,
        currentBuildNumber: String,
        localDomain: String?
    ) async throws {

        let applicationStatusDirectory = ApplicationStatusDirectory(
            syncContext: coreDataStack.syncContext,
            transportSession: transportSession
        )
        let linkPreviewPreprocessor = LinkPreviewPreprocessor(
            linkPreviewDetector: applicationStatusDirectory.linkPreviewDetector,
            managedObjectContext: coreDataStack.syncContext
        )

        let legacyAPIVersion = WireTransport.APIVersion(rawValue: Int32(apiVersion.rawValue))

        let strategyFactory = StrategyFactory(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            linkPreviewPreprocessor: linkPreviewPreprocessor,
            transportSession: transportSession,
            initiateResetMLSConversationUseCase: NullInitiateResetMLSConversationUseCase(),
            apiVersion: legacyAPIVersion,
            localDomain: localDomain
        )

        let requestGeneratorStore = RequestGeneratorStore(
            strategies: strategyFactory.strategies,
            apiVersion: legacyAPIVersion
        )

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
        let journal = Journal(
            userID: accountIdentifier,
            storage: sharedUserDefaults
        )
        let coreCryptoProvider = CoreCryptoProvider(
            selfUserID: accountIdentifier,
            sharedContainerURL: coreDataStack.applicationContainer,
            accountDirectory: coreDataStack.accountContainer,
            sharedUserDefaults: sharedUserDefaults,
            syncContext: coreDataStack.syncContext,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            coreCryptoKeyMigrationManager: CoreCryptoKeyMigrationManager(journal: journal),
            allowCreation: false,
            localDomain: localDomain
        )
        let featureRepository = LegacyFeatureRepository(context: coreDataStack.syncContext)
        let mlsActionExecutor = MLSActionExecutor(
            coreCryptoProvider: coreCryptoProvider,
            featureRepository: featureRepository
        )
        let contextStorage = LAContextStorage()
        let earService = EARService(
            accountID: accountIdentifier,
            databaseContexts: [
                coreDataStack.viewContext,
                coreDataStack.syncContext
            ],
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: contextStorage)
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
            userID: coreDataStack.account.userIdentifier,
            localDomain: localDomain
        )

        let preferredAPIVersion = BackendInfo.preferredAPIVersion.flatMap {
            WireNetwork.APIVersion(rawValue: UInt($0.rawValue))
        }

        let proxyCredentials = proxyCredentials.map {
            WireNetwork.ProxyCredentials(
                username: $0.username,
                password: $0.password
            )
        }

        let networkStack = NetworkStack(
            backendEnvironment: BackendEnvironment2(legacyEnvironment),
            minTLSVersion: minTLSVersion,
            preferredAPIVersion: preferredAPIVersion,
            proxyCredentials: proxyCredentials
        )

        let networkServices = try await networkStack.networkServices
        let metadata = try await networkStack.resolvedBackendMetadata()
        let cookieStorage = CookieStorage(
            userID: accountIdentifier,
            cookieEncryptionKey: UserDefaults.cookiesKey(),
            keychain: Keychain()
        )

        let isMLSEnabled = if DeveloperFlag.multibackend.isOn {
            journal[.isBackendMLSEnabled]
        } else {
            BackendInfo.isMLSEnabled
        }

        let userSessionComponent = UserSessionComponent(
            currentBuildNumber: currentBuildNumber,
            selfUserID: accountIdentifier,
            cookieStorage: cookieStorage,
            restNetworkService: networkServices.rest,
            websocketNetworkService: networkServices.webSocket,
            blacklistNetworkService: networkServices.blacklist,
            backendMetaData: metadata,
            isMLSEnabled: isMLSEnabled,
            sharedUserDefaults: sharedUserDefaults,
            sharedContainerURL: nil, // the container is not used in this case
            syncContext: coreDataStack.syncContext,
            eventContext: coreDataStack.eventContext,
            mlsService: mlsService,
            mlsDecryptionService: mlsService,
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

        let selfClient = ZMUser.selfUser(in: coreDataStack.viewContext).selfClient()
        let clientUserSessionComponent = userSessionComponent.clientSessionComponent(
            clientID: selfClientID,
            completionHandlers: completionHandlers
        )

        coreCryptoProvider.registerMlsTransport(clientUserSessionComponent.mlsTransport)

        try await self.init(
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
            mlsService: mlsService,
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

}

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

private extension WireDataModel.ConversationList {

    var writeableConversations: [Conversation] {
        items.filter { !$0.isReadOnly }
    }
}

extension InitiateResetMLSConversationUseCase: WireRequestStrategy.InitiateResetMLSConversationUseCaseProtocol {}

// No need to handle it in share extension for now
struct NullInitiateResetMLSConversationUseCase: WireRequestStrategy.InitiateResetMLSConversationUseCaseProtocol {
    func invoke(groupID: WireDataModel.MLSGroupID, epoch: UInt64) async {
        // do nothing
    }
}

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
import WireRequestStrategy

public enum NotificationSessionError: LocalizedError {

    case accountNotAuthenticated
    case noEventID
    case invalidEventID
    case alreadyFetchedEvent
    case unknown

    public var errorDescription: String? {
        switch self {
        case .accountNotAuthenticated:
            return "user is not authenticated"

        case .noEventID:
            return "event id is missing in push payload"

        case .invalidEventID:
            return "invalid event id"

        case .alreadyFetchedEvent:
            return "event was already fetched"

        case .unknown:
            return "unknown"
        }
    }

}

public protocol NotificationSessionDelegate: AnyObject {

    func notificationSessionDidFailWithError(error: NotificationSessionError)

    func notificationSessionDidGenerateNotification(
        _ notification: ZMLocalNotification?,
        unreadConversationCount: Int
    )

    func notificationSessionDidReceivePushData(_ data: Data)

    func reportCallEvent(
        _ payload: CallEventPayload,
        currentTimestamp: TimeInterval
    )

}

/// A syncing layer for the notification processing
/// - note: this is the entry point of this framework. Users of
/// the framework should create an instance as soon as possible in
/// the lifetime of the notification extension, and hold on to that session
/// for the entire lifetime.
///
public final class NotificationSession: NSObject, ZMPushChannelConsumer {

    /// The failure reason of a `NotificationSession` initialization
    /// - noAccount: Account doesn't exist

    public enum InitializationError: Error {

        case noAccount
        case pendingCryptoboxMigration
        case coreDataMissingSharedContainer
        case coreDataMigrationRequired

    }

    // MARK: - Properties

    /// Directory of all application statuses.

    private let applicationStatusDirectory: ApplicationStatusDirectory

    /// The list to which save notifications of the UI moc are appended and persisted.

    private let saveNotificationPersistence: ContextDidSaveNotificationPersistence

    private var contextSaveObserverToken: NSObjectProtocol?
    private let transportSession: ZMTransportSession
    private let coreDataStack: CoreDataStack
    private let operationLoop: RequestGeneratingOperationLoop
    private let eventDecoder: EventDecoder
    private let earService: EARServiceInterface

    public let accountIdentifier: UUID

    private var callEvent: CallEventPayload?
    private var localNotifications = [ZMLocalNotification]()

    private var context: NSManagedObjectContext { coreDataStack.syncContext }

    public weak var delegate: NotificationSessionDelegate?

    // MARK: - Life cycle

    /// Initializes a new `SessionDirectory` to be used in an extension environment
    /// - parameter databaseDirectory: The `NSURL` of the shared group container
    /// - throws: `InitializationError.noAccount` in case the account does not exist
    /// - returns: The initialized session object if no error is thrown

    public convenience init(
        applicationGroupIdentifier: String,
        accountIdentifier: UUID,
        environment: BackendEnvironmentProvider,
        analytics: AnalyticsType?,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String?
    ) throws {
        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let accountManager = AccountManager(sharedDirectory: sharedContainerURL)

        guard let account = accountManager.account(with: accountIdentifier) else {
            throw InitializationError.noAccount
        }

        let coreDataStack = CoreDataStack(
            account: account,
            applicationContainer: sharedContainerURL
        )

        guard coreDataStack.storesExists else {
            throw InitializationError.coreDataMissingSharedContainer
        }

        guard !coreDataStack.needsMigration  else {
            throw InitializationError.coreDataMigrationRequired
        }

        coreDataStack.loadStores { error in
            // ⚠️ errors are not handled and `NotificationSession` will be created.
            // Currently it is the given behavior, but should be refactored
            // into a "setup" or "load" func that can be async and handle errors.

            if let error {
                WireLogger.notifications.error("Loading coreDataStack with error: \(error.localizedDescription)")
            }
        }

        // Don't cache the cookie because if the user logs out and back in again in the main app
        // process, then the cached cookie will be invalid.
        let cookieStorage = ZMPersistentCookieStorage(forServerName: environment.backendURL.host!, userIdentifier: accountIdentifier, useCache: false)
        let reachabilityGroup = ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Sharing session reachability")
        let serverNames = [environment.backendURL, environment.backendWSURL].compactMap { $0.host }
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
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: FileManager.default.cachesURLForAccount(with: accountIdentifier, in: sharedContainerURL),
            accountContainer: CoreDataStack.accountDataFolder(accountIdentifier: accountIdentifier, applicationContainer: sharedContainerURL),
            analytics: analytics,
            accountIdentifier: accountIdentifier,
            sharedUserDefaults: sharedUserDefaults
        )
    }

    convenience init(
        coreDataStack: CoreDataStack,
        transportSession: ZMTransportSession,
        cachesDirectory: URL,
        accountContainer: URL,
        analytics: AnalyticsType?,
        accountIdentifier: UUID,
        sharedUserDefaults: UserDefaults
    ) throws {
        let lastEventIDRepository = LastEventIDRepository(
            userID: accountIdentifier,
            sharedUserDefaults: sharedUserDefaults
        )

        let applicationStatusDirectory = ApplicationStatusDirectory(
            syncContext: coreDataStack.syncContext,
            transportSession: transportSession,
            lastEventIDRepository: lastEventIDRepository
        )

        let notificationsTracker = (analytics != nil) ? NotificationsTracker(analytics: analytics!) : nil

        let pushNotificationStrategy = PushNotificationStrategy(
            syncContext: coreDataStack.syncContext,
            applicationStatus: applicationStatusDirectory,
            pushNotificationStatus: applicationStatusDirectory.pushNotificationStatus,
            notificationsTracker: notificationsTracker,
            lastEventIDRepository: lastEventIDRepository
        )

        let requestGeneratorStore = RequestGeneratorStore(strategies: [pushNotificationStrategy])

        let operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: requestGeneratorStore,
            transportSession: transportSession
        )

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

        let saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)

        let earService = EARService(
            accountID: accountIdentifier,
            sharedUserDefaults: sharedUserDefaults,
            authenticationContext: AuthenticationContext(storage: LAContextStorage())
        )

        try self.init(
            coreDataStack: coreDataStack,
            transportSession: transportSession,
            cachesDirectory: cachesDirectory,
            saveNotificationPersistence: saveNotificationPersistence,
            applicationStatusDirectory: applicationStatusDirectory,
            operationLoop: operationLoop,
            accountIdentifier: accountIdentifier,
            pushNotificationStrategy: pushNotificationStrategy,
            cryptoboxMigrationManager: cryptoboxMigrationManager,
            earService: earService,
            proteusService: ProteusService(coreCryptoProvider: coreCryptoProvider),
            mlsDecryptionService: MLSDecryptionService(context: coreDataStack.syncContext, mlsActionExecutor: mlsActionExecutor),
            lastEventIDRepository: lastEventIDRepository
        )
    }

    init(
        coreDataStack: CoreDataStack,
        transportSession: ZMTransportSession,
        cachesDirectory: URL,
        saveNotificationPersistence: ContextDidSaveNotificationPersistence,
        applicationStatusDirectory: ApplicationStatusDirectory,
        operationLoop: RequestGeneratingOperationLoop,
        accountIdentifier: UUID,
        pushNotificationStrategy: PushNotificationStrategy,
        cryptoboxMigrationManager: CryptoboxMigrationManagerInterface,
        earService: EARServiceInterface,
        proteusService: ProteusServiceInterface,
        mlsDecryptionService: MLSDecryptionServiceInterface,
        lastEventIDRepository: LastEventIDRepositoryInterface

    ) throws {
        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.saveNotificationPersistence = saveNotificationPersistence
        self.applicationStatusDirectory = applicationStatusDirectory
        self.operationLoop = operationLoop
        self.accountIdentifier = accountIdentifier
        self.earService = earService

        eventDecoder = EventDecoder(
            eventMOC: coreDataStack.eventContext,
            syncMOC: coreDataStack.syncContext,
            lastEventIDRepository: lastEventIDRepository
        )

        super.init()

        pushNotificationStrategy.delegate = self

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

    }

    deinit {
        if let token = contextSaveObserverToken {
            NotificationCenter.default.removeObserver(token)
            contextSaveObserverToken = nil
        }

        transportSession.reachability.tearDown()
        transportSession.tearDown()
    }

    // MARK: - Methods

    public func processPushNotification(with payload: [AnyHashable: Any]) {
        WireLogger.notifications.info("processing notification with payload: \(payload)")

        let clientID = context.performAndWait { [context] in
            ZMUser.selfUser(in: context).selfClient()?.remoteIdentifier
        }

        guard let clientID else {
            return
        }

        transportSession.configurePushChannel(consumer: self, groupQueue: context)
        transportSession.pushChannel.clientID = clientID
        transportSession.pushChannel.keepOpen = true
    }

    public func pushChannelDidReceive(_ data: Data) {
        WireLogger.notifications.info("did receive push channel data")
        delegate?.notificationSessionDidReceivePushData(data)
    }

    public func pushChannelDidClose() {
        WireLogger.notifications.warn("push channel did close")
    }

    public func pushChannelDidOpen() {
        WireLogger.notifications.info("push channel did open")
    }

//    public func processPushNotification(with payload: [AnyHashable: Any]) {
//        WireLogger.notifications.info("processing notification with payload: \(payload)")
//
//        coreDataStack.syncContext.performGroupedBlock {
//            if self.applicationStatusDirectory.authenticationStatus.state == .unauthenticated {
//                WireLogger.notifications.error("Not displaying notification because app is not authenticated")
//                self.delegate?.notificationSessionDidFailWithError(error: .accountNotAuthenticated)
//                return
//            }
//
//            let selfClient = ZMUser(context: self.coreDataStack.syncContext).selfClient()
//            if let clientId = selfClient?.safeRemoteIdentifier.safeForLoggingDescription {
//                WireLogger.authentication.addTag(.selfClientId, value: clientId)
//            }
//
//            self.fetchEvents(fromPushChannelPayload: payload)
//        }
//    }

    func fetchEvents(fromPushChannelPayload payload: [AnyHashable: Any]) {
        guard let nonce = self.messageNonce(fromPushChannelData: payload) else {
            delegate?.notificationSessionDidFailWithError(error: .noEventID)
            return
        }

        WireLogger.notifications.info("attempting to fetch events")
        applicationStatusDirectory.pushNotificationStatus.fetch(eventId: nonce) { result in
            switch result {
            case .success:
                break

            case .failure(.alreadyFetchedEvent):
                self.delegate?.notificationSessionDidFailWithError(error: .alreadyFetchedEvent)

            case .failure(.invalidEventID):
                self.delegate?.notificationSessionDidFailWithError(error: .invalidEventID)

            case .failure(.unknown):
                self.delegate?.notificationSessionDidFailWithError(error: .unknown)
            }
        }
    }

    private func messageNonce(fromPushChannelData payload: [AnyHashable: Any]) -> UUID? {
        guard
            let notificationData = payload[PushChannelKeys.data.rawValue] as? [AnyHashable: Any],
            let data = notificationData[PushChannelKeys.data.rawValue] as? [AnyHashable: Any],
            let rawUUID = data[PushChannelKeys.identifier.rawValue] as? String
        else {
            return nil
        }

        return UUID(uuidString: rawUUID)
    }

    private enum PushChannelKeys: String {
        case data = "data"
        case identifier = "id"
    }
}

extension NotificationSession: PushNotificationStrategyDelegate {

    func pushNotificationStrategy(
        _ strategy: PushNotificationStrategy,
        didFetchEvents events: [ZMUpdateEvent]
    ) async throws {
        let decodedEvents = try await self.eventDecoder.decryptAndStoreEvents(
            events,
            publicKeys: try? self.earService.fetchPublicKeys()
        )

        await self.context.perform { [self] in
            processDecodedEvents(decodedEvents)
        }
    }

    private func processDecodedEvents(_ events: [ZMUpdateEvent]) {
        WireLogger.notifications.info("processing \(events.count) decoded events...")

        // Dictionary to filter notifications fetched in same batch with same messageOnce
        // i.e: textMessage and linkPreview
        var tempNotifications = [Int: ZMLocalNotification]()

        for event in events {
            if let callEventPayload = callEventPayloadForCallKit(from: event) {
                WireLogger.calling.info("detected a call event", attributes: event.logAttributes)
                // Only store the last call event.
                callEvent = callEventPayload
            } else if let notification = notification(from: event, in: context) {
                WireLogger.notifications.info("generated a notification from an event", attributes: event.logAttributes)
                tempNotifications[notification.contentHashValue] = notification
            } else {
                WireLogger.notifications.info("ignoring event", attributes: event.logAttributes)
            }
        }

        localNotifications = Array(tempNotifications.values)
        context.saveOrRollback()
    }

    private func callEventPayloadForCallKit(from event: ZMUpdateEvent) -> CallEventPayload? {
        // Ensure this actually is a call event.
        guard let callContent = CallEventContent(from: event) else {
            return nil
        }

        guard let callerID = event.senderUUID else {
            WireLogger.calling.error("should not handle call event: senderUUID missing from event")
            return nil
        }

        guard let caller = ZMUser.fetch(
            with: callerID,
            domain: event.senderDomain,
            in: context
        ) else {
            WireLogger.calling.warn("should not handle call event: caller not in db")
            return nil
        }

        guard let conversationID = event.conversationUUID else {
            WireLogger.calling.error("should not handle call event: conversationUUID missing from event")
            return nil
        }

        guard let conversation = ZMConversation.fetch(
            with: conversationID,
            domain: event.conversationDomain,
            in: context
        ) else {
            WireLogger.calling.warn("should not handle call event: conversation not in db")
            return nil
        }

        guard !conversation.needsToBeUpdatedFromBackend else {
            WireLogger.calling.warn("should not handle call event: conversation not synced")
            return nil
        }

        if conversation.mutedMessageTypesIncludingAvailability != .none {
            WireLogger.calling.info("should not handle call event: conversation is muted or user is not available")
            return nil
        }

        if conversation.isForcedReadOnly {
            WireLogger.calling.info("should not handle call event: conversation is forced readonly")
            return nil
        }

        guard VoIPPushHelper.isAVSReady else {
            WireLogger.calling.warn("should not handle call event: AVS is not ready")
            return nil
        }

        guard VoIPPushHelper.isCallKitAvailable else {
            WireLogger.calling.info("should not handle call event: CallKit is not available")
            return nil
        }

        guard VoIPPushHelper.isUserSessionLoaded(accountID: accountIdentifier) else {
            WireLogger.calling.warn("should not handle call event: user session is not loaded")
            return nil
        }

        let handle = "\(accountIdentifier.transportString())+\(conversationID.transportString())"
        let wasCallHandleReported = VoIPPushHelper.knownCallHandles.contains(handle)

        // Should not handle a call if the caller is a self user and it's an incoming call or call end.
        // The caller can be the same as the self user if it's a rejected call or answered elsewhere.
        if let selfUserID = ZMUser.selfUser(in: context).remoteIdentifier,
            let callerID = callContent.callerID,
            callerID == selfUserID,
            callContent.isIncomingCall || callContent.isEndCall {
            WireLogger.calling.info("should not handle call event: self call")
            return nil
        }

        if callContent.initiatesRinging, !wasCallHandleReported {
            WireLogger.calling.info("should initiate ringing")
            return CallEventPayload(
                accountID: accountIdentifier.uuidString,
                conversationID: conversationID.uuidString,
                shouldRing: true,
                callerName: conversation.localizedCallerName(with: caller),
                hasVideo: callContent.isVideo
            )
        } else if callContent.terminatesRinging, wasCallHandleReported {
            WireLogger.calling.info("should terminate ringing")
            return CallEventPayload(
                accountID: accountIdentifier.uuidString,
                conversationID: conversationID.uuidString,
                shouldRing: false,
                callerName: conversation.localizedCallerName(with: caller),
                hasVideo: callContent.isVideo
            )
        } else {
            WireLogger.calling.info("should not handle call event: nothing to report")
            return nil
        }
    }

    func pushNotificationStrategyDidFinishFetchingEvents(_ strategy: PushNotificationStrategy) {
        WireLogger.notifications.info("did finish processing events")
        processCallEvent()
        processLocalNotifications()
    }

    private func processCallEvent() {
        if let callEvent {
            delegate?.reportCallEvent(
                callEvent,
                currentTimestamp: context.serverTimeDelta
            )

            self.callEvent = nil
        }
    }

    private func processLocalNotifications() {
        let notification: ZMLocalNotification?

        if localNotifications.count > 1 {
            WireLogger.notifications.info("bundling \(localNotifications.count) notifications")
            notification = ZMLocalNotification.bundledMessages(count: localNotifications.count, in: context)
        } else {
            notification = localNotifications.first
        }

        let unreadCount = Int(ZMConversation.unreadConversationCount(in: context))
        delegate?.notificationSessionDidGenerateNotification(notification, unreadConversationCount: unreadCount)
        localNotifications.removeAll()
    }

}

// MARK: - Converting events to localNotifications

extension NotificationSession {

    private func notification(from event: ZMUpdateEvent, in context: NSManagedObjectContext) -> ZMLocalNotification? {
        var note: ZMLocalNotification?

        guard let conversationID = event.conversationUUID else {
            WireLogger.notifications.warn("failed to generate notification from event: missing conversation id")
            return nil
        }

        let conversation = ZMConversation.fetch(with: conversationID, domain: event.conversationDomain, in: context)

        if let callEventContent = CallEventContent(from: event) {
            let currentTimestamp = Date().addingTimeInterval(context.serverTimeDelta)

            /// The caller should not be the same as the user receiving the call event and
            /// the age of the event is less than 30 seconds
            guard
                let callState = callEventContent.callState,
                let callerID = callEventContent.callerID,
                let caller = ZMUser.fetch(with: callerID, domain: event.senderDomain, in: context),
                caller != ZMUser.selfUser(in: context),
                !isEventTimedOut(currentTimestamp: currentTimestamp, eventTimestamp: event.timestamp)
            else {
                return nil
            }

            note = ZMLocalNotification.init(callState: callState, conversation: conversation, caller: caller, moc: context)

        } else {
            note = ZMLocalNotification.init(event: event, conversation: conversation, managedObjectContext: context)
        }

        note?.increaseEstimatedUnreadCount(on: conversation)
        return note
    }

    private func isEventTimedOut(currentTimestamp: Date, eventTimestamp: Date?) -> Bool {
        guard let eventTimestamp else {
            return true
        }

        return Int(currentTimestamp.timeIntervalSince(eventTimestamp)) > 30
    }

}

public struct CallEventPayload {

    public let accountID: String
    public let conversationID: String
    public let shouldRing: Bool
    public let callerName: String
    public let hasVideo: Bool

    public init(
        accountID: String,
        conversationID: String,
        shouldRing: Bool,
        callerName: String,
        hasVideo: Bool
    ) {
        self.accountID = accountID
        self.conversationID = conversationID
        self.shouldRing = shouldRing
        self.callerName = callerName
        self.hasVideo = hasVideo
    }

}

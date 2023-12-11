//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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
public class NotificationSession {

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

    public init(
        applicationGroupIdentifier: String,
        accountIdentifier: UUID,
        coreDataStack: CoreDataStack,
        environment: BackendEnvironmentProvider,
        analytics: AnalyticsType?,
        sharedUserDefaults: UserDefaults,
        minTLSVersion: String?
    ) throws {
        // Don't cache the cookie because if the user logs out and back in again in the main app
        // process, then the cached cookie will be invalid.
        let cookieStorage = ZMPersistentCookieStorage(forServerName: environment.backendURL.host!, userIdentifier: accountIdentifier, useCache: false)
        let credentials = environment.proxy.flatMap { ProxyCredentials.retrieve(for: $0) }

        let transportSession = ZMTransportSession(
            environment: environment,
            proxyUsername: credentials?.username,
            proxyPassword: credentials?.password,
            cookieStorage: cookieStorage,
            reachability: ZMReachability(
                serverNames: [environment.backendURL, environment.backendWSURL].compactMap { $0.host },
                group: ZMSDispatchGroup(dispatchGroup: DispatchGroup(), label: "Sharing session reachability")!
            ),
            initialAccessToken: nil,
            applicationGroupIdentifier: applicationGroupIdentifier,
            applicationVersion: "1.0.0",
            minTLSVersion: minTLSVersion
        )

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

        self.coreDataStack = coreDataStack
        self.transportSession = transportSession
        self.applicationStatusDirectory = applicationStatusDirectory
        self.accountIdentifier = accountIdentifier

        let sharedContainerURL = FileManager.sharedContainerDirectory(for: applicationGroupIdentifier)
        let accountContainer = CoreDataStack.accountDataFolder(accountIdentifier: accountIdentifier, applicationContainer: sharedContainerURL)
        self.saveNotificationPersistence = ContextDidSaveNotificationPersistence(accountContainer: accountContainer)

        self.operationLoop = RequestGeneratingOperationLoop(
            userContext: coreDataStack.viewContext,
            syncContext: coreDataStack.syncContext,
            callBackQueue: .main,
            requestGeneratorStore: RequestGeneratorStore(strategies: [pushNotificationStrategy]),
            transportSession: transportSession
        )

        self.earService = EARService(accountID: accountIdentifier, sharedUserDefaults: sharedUserDefaults)

        self.eventDecoder = EventDecoder(
            eventMOC: coreDataStack.eventContext,
            syncMOC: coreDataStack.syncContext
        )

        // from here `self` is initialized

        pushNotificationStrategy.delegate = self
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

        coreDataStack.syncContext.performGroupedBlock {
            if self.applicationStatusDirectory.authenticationStatus.state == .unauthenticated {
                WireLogger.notifications.error("Not displaying notification because app is not authenticated")
                self.delegate?.notificationSessionDidFailWithError(error: .accountNotAuthenticated)
                return
            }

            self.fetchEvents(fromPushChannelPayload: payload)
        }
    }

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
    ) async {
        let decodedEvents = await eventDecoder.decryptAndStoreEvents(
            events,
            publicKeys: try? earService.fetchPublicKeys()
        )
        processDecodedEvents(decodedEvents)
    }

    private func processDecodedEvents(_ events: [ZMUpdateEvent]) {
        WireLogger.notifications.info("processing \(events.count) decoded events...")

        for event in events {
            if let callEventPayload = callEventPayloadForCallKit(from: event) {
                WireLogger.calling.info("detected a call event")
                // Only store the last call event.
                callEvent = callEventPayload
            } else if let notification = notification(from: event, in: context) {
                WireLogger.notifications.info("generated a notification from an event")
                localNotifications.append(notification)
            } else {
                WireLogger.notifications.info("ignoring event")
            }
        }
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
        if
            let selfUserID = ZMUser.selfUser(in: context).remoteIdentifier,
            let callerID = callContent.callerID,
            callerID == selfUserID,
            callContent.isIncomingCall || callContent.isEndCall
        {
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
        if let callEvent = callEvent {
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
        guard let eventTimestamp = eventTimestamp else {
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

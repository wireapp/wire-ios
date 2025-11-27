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

import Foundation
import WireDomain
import WireLogging
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
            "user is not authenticated"

        case .noEventID:
            "event id is missing in push payload"

        case .invalidEventID:
            "invalid event id"

        case .alreadyFetchedEvent:
            "event was already fetched"

        case .unknown:
            "unknown"
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
public final class NotificationSession {

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

        self.eventDecoder = EventDecoder(
            eventMOC: coreDataStack.eventContext,
            syncMOC: coreDataStack.syncContext,
            lastEventIDRepository: lastEventIDRepository,
            isFederationEnabled: BackendInfo.isFederationEnabled
        )

        pushNotificationStrategy.delegate = self

        let accountDirectory = coreDataStack.accountContainer
        guard !cryptoboxMigrationManager.isMigrationNeeded(accountDirectory: accountDirectory) else {
            throw InitializationError.pendingCryptoboxMigration
        }
        coreDataStack.syncContext.performAndWait {
            if DeveloperFlag.proteusViaCoreCrypto.isOn, coreDataStack.syncContext.proteusService == nil {
                coreDataStack.syncContext.proteusService = proteusService
            }

            let mlsFeature = LegacyFeatureRepository(context: coreDataStack.syncContext).fetchMLS()
            if mlsFeature.isEnabled, coreDataStack.syncContext.mlsDecryptionService == nil {
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
        WireLogger.notifications.info("processing notification with payload: \(payload)", attributes: .legacyNSE)

        coreDataStack.syncContext.performGroupedBlock {
            if self.applicationStatusDirectory.authenticationStatus.state == .unauthenticated {
                WireLogger.notifications.error(
                    "Not displaying notification because app is not authenticated",
                    attributes: .legacyNSE
                )
                self.delegate?.notificationSessionDidFailWithError(error: .accountNotAuthenticated)
                return
            }

            let selfClient = ZMUser(context: self.coreDataStack.syncContext).selfClient()
            if let clientID = selfClient?.safeRemoteIdentifier.safeForLoggingDescription {
                WireLogger.authentication.setClientID(clientID)
            }

            self.fetchEvents(fromPushChannelPayload: payload)
        }
    }

    func fetchEvents(fromPushChannelPayload payload: [AnyHashable: Any]) {
        guard let nonce = messageNonce(fromPushChannelData: payload) else {
            delegate?.notificationSessionDidFailWithError(error: .noEventID)
            return
        }

        WireLogger.notifications.info("attempting to fetch events", attributes: .legacyNSE, .safePublic)
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
        case data
        case identifier = "id"
    }
}

extension NotificationSession: PushNotificationStrategyDelegate {

    func pushNotificationStrategy(
        _ strategy: PushNotificationStrategy,
        didFetchEvents events: [ZMUpdateEvent]
    ) async throws {
        let decodedEvents = try await eventDecoder.decryptAndStoreEvents(
            events,
            publicKeys: try? earService.fetchPublicKeys()
        )

        await context.perform { [self] in
            processDecodedEvents(decodedEvents)
        }
    }

    private func processDecodedEvents(_ events: [ZMUpdateEvent]) {
        WireLogger.notifications.info("processing \(events.count) decoded events...", attributes: .legacyNSE)

        // Dictionary to filter notifications fetched in same batch with same messageOnce
        // i.e: textMessage and linkPreview
        var tempNotifications = [Int: ZMLocalNotification]()

        for event in events {
            if let callEventPayload = callEventPayloadForCallKit(from: event) {
                WireLogger.calling.info("detected a call event", attributes: event.logAttributes, .legacyNSE)
                // Only store the last call event.
                callEvent = callEventPayload
            } else if let notification = notification(from: event, in: context) {
                WireLogger.notifications.info(
                    "generated a notification from an event",
                    attributes: event.logAttributes,
                    .legacyNSE
                )
                tempNotifications[notification.contentHashValue] = notification
            } else {
                WireLogger.notifications.info("ignoring event", attributes: event.logAttributes, .legacyNSE)
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
            WireLogger.calling.error(
                "should not handle call event: senderUUID missing from event",
                attributes: .legacyNSE
            )
            return nil
        }

        guard let caller = ZMUser.fetch(
            with: callerID,
            domain: event.senderDomain,
            in: context
        ) else {
            WireLogger.calling.warn("should not handle call event: caller not in db", attributes: .legacyNSE)
            return nil
        }

        guard let conversationID = event.conversationUUID else {
            WireLogger.calling.error(
                "should not handle call event: conversationUUID missing from event",
                attributes: .legacyNSE
            )
            return nil
        }

        guard let conversation = ZMConversation.fetch(
            with: conversationID,
            domain: event.conversationDomain,
            in: context
        ) else {
            WireLogger.calling.warn("should not handle call event: conversation not in db", attributes: .legacyNSE)
            return nil
        }

        guard !conversation.needsToBeUpdatedFromBackend else {
            WireLogger.calling.warn("should not handle call event: conversation not synced", attributes: .legacyNSE)
            return nil
        }

        if conversation.mutedMessageTypesIncludingAvailability != .none {
            WireLogger.calling.info(
                "should not handle call event: conversation is muted or user is not available",
                attributes: .legacyNSE
            )
            return nil
        }

        if conversation.isForcedReadOnly {
            WireLogger.calling.info(
                "should not handle call event: conversation is forced readonly",
                attributes: .legacyNSE
            )
            return nil
        }

        guard VoIPPushHelper.isAVSReady else {
            WireLogger.calling.warn("should not handle call event: AVS is not ready", attributes: .legacyNSE)
            return nil
        }

        guard VoIPPushHelper.isCallKitAvailable else {
            WireLogger.calling.info("should not handle call event: CallKit is not available", attributes: .legacyNSE)
            return nil
        }

        guard VoIPPushHelper.isUserSessionLoaded(accountID: accountIdentifier) else {
            WireLogger.calling.warn("should not handle call event: user session is not loaded", attributes: .legacyNSE)
            return nil
        }

        let handle = "\(accountIdentifier.transportString())+\(conversationID.transportString())"
        let wasCallHandleReported = VoIPPushHelper.knownCallHandles.contains(handle)

        // Should not handle a call if the caller is a self user and it's an incoming call or call end.
        // The caller can be the same as the self user if it's a rejected call or answered elsewhere.
        let selfUser = ZMUser.selfUser(in: context)
        if let callerID = callContent.callerID(isFederationEnabled: BackendInfo.isFederationEnabled),
           callerID.identifier == selfUser.remoteIdentifier,
           callerID.domain == selfUser.domain,
           callContent.isIncomingCall || callContent.isEndCall {
            WireLogger.calling.info("should not handle call event: self call", attributes: .legacyNSE)
            return nil
        }

        if callContent.initiatesRinging, !wasCallHandleReported {
            WireLogger.calling.info("should initiate ringing", attributes: .legacyNSE)
            return CallEventPayload(
                accountID: accountIdentifier.uuidString,
                conversationID: conversationID.uuidString,
                shouldRing: true,
                callerName: conversation.localizedCallerName(with: caller),
                hasVideo: callContent.isVideo
            )
        } else if callContent.terminatesRinging, wasCallHandleReported {
            WireLogger.calling.info("should terminate ringing", attributes: .legacyNSE)
            return CallEventPayload(
                accountID: accountIdentifier.uuidString,
                conversationID: conversationID.uuidString,
                shouldRing: false,
                callerName: conversation.localizedCallerName(with: caller),
                hasVideo: callContent.isVideo
            )
        } else {
            WireLogger.calling.info("should not handle call event: nothing to report", attributes: .legacyNSE)
            return nil
        }
    }

    func pushNotificationStrategyDidFinishFetchingEvents(_ strategy: PushNotificationStrategy) {
        WireLogger.notifications.info("did finish processing events", attributes: .legacyNSE, .safePublic)
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
            WireLogger.notifications.info(
                "bundling \(localNotifications.count) notifications",
                attributes: .legacyNSE,
                .safePublic
            )
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
            WireLogger.notifications.warn(
                "failed to generate notification from event: missing conversation id",
                attributes: event.logAttributes,
                .legacyNSE
            )
            return nil
        }

        let conversation = ZMConversation.fetch(with: conversationID, domain: event.conversationDomain, in: context)

        if let callEventContent = CallEventContent(from: event) {
            let currentTimestamp = Date().addingTimeInterval(context.serverTimeDelta)

            /// The caller should not be the same as the user receiving the call event and
            /// the age of the event is less than 30 seconds
            guard
                let callState = callEventContent.callState,
                let callerID = callEventContent.callerID(isFederationEnabled: BackendInfo.isFederationEnabled),
                let caller = ZMUser.fetch(with: callerID.identifier, domain: callerID.domain, in: context),
                caller != ZMUser.selfUser(in: context),
                !isEventTimedOut(currentTimestamp: currentTimestamp, eventTimestamp: event.timestamp)
            else {
                return nil
            }

            note = ZMLocalNotification(callState: callState, conversation: conversation, caller: caller, moc: context)

        } else {
            note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: context)
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

extension LogAttributes {
    static let newNSE = [
        LogAttributesKey.nse: "new"
    ]

    static let legacyNSE = [
        LogAttributesKey.nse: "legacy"
    ]
}

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
import CallKit
import WireLogging
import WireDataModel
/// Coordinates CallKit reporting in response to AVS calling events.
///
/// This coordinator:
/// - Sets up callbacks on AVSCallingEventService
/// - Handles incoming call and call closed events
/// - Reports to CallKit via CXProvider
/// - Manages async task lifecycle for CallKit operations
///
/// **Lifecycle:** Owned by NSEClientScope, lives for the duration of notification processing.
/// **Thread-safety:** All methods should be called from the same actor/queue.
//final class CallKitReportingCoordinator {
//
//    // MARK: - Properties
//
//    private let accountID: UUID
//    private var callKitReportTask: Task<Void, Never>?
//    private var didReportIncomingCall: Bool = false
//
//    // MARK: - Initialization
//
//    /// Creates a coordinator and sets up AVS callbacks.
//    ///
//    /// - Parameters:
//    ///   - accountID: The account identifier for CallKit content
//    ///   - avsService: The AVS service to observe for calling events
//    ///
//    /// **Important:** This initializer sets callbacks on the AVS service that
//    /// capture `self` strongly. This is safe because the coordinator doesn't
//    /// own the service, preventing retain cycles.
//    init(accountID: UUID, avsService: any AVSCallingEventServiceProtocol) {
//        self.accountID = accountID
//
//        WireLogger.calling.debug(
//            "CallKitReportingCoordinator: initializing for account \(accountID)",
//            attributes: .newNSE, .safePublic
//        )
//
//        // Set up callbacks - capturing self strongly is safe here
//        // because we don't own avsService (no retain cycle)
//        avsService.onIncomingCall = { [self] conversationId, shouldRing, isVideoCall in
//            self.handleIncomingCall(
//                conversationId: conversationId,
//                shouldRing: shouldRing,
//                isVideoCall: isVideoCall
//            )
//        }
//
//        avsService.onMissedCall = { conversationId, messageTime, isVideoCall in
//            WireLogger.calling.info(
//                "CallKitReportingCoordinator: onMissedCall fired",
//                attributes: .newNSE, .safePublic
//            )
//            // Nothing to do here — the missed call text notification
//            // is already built by ConversationCallingEventNotificationBuilder
//            // from the same event in the event stream.
//            WireLogger.calling.info(
//                "AVS: missed call in conversation \(conversationId)",
//                attributes: .newNSE, .safePublic
//            )
//        }
//
//        avsService.onCallClosed = { [self] reason, conversationId in
//            self.handleCallClosed(reason: reason, conversationId: conversationId)
//        }
//    }
//
//    deinit {
//        WireLogger.calling.debug(
//            "CallKitReportingCoordinator: deallocating",
//            attributes: .newNSE, .safePublic
//        )
//    }
//
//    // MARK: - Public API
//
//    /// Waits for any pending CallKit reporting tasks to complete.
//    ///
//    /// Call this before finishing notification processing to ensure
//    /// CallKit has been properly notified.
//    ///
//    /// - Returns: Completes when the CallKit task finishes (or immediately if no task)
//    func waitForCompletion() async {
//        WireLogger.calling.debug(
//            "CallKitReportingCoordinator: waiting for completion",
//            attributes: .newNSE, .safePublic
//        )
//
//        await callKitReportTask?.value
//
//        WireLogger.calling.debug(
//            "CallKitReportingCoordinator: completion awaited",
//            attributes: .newNSE, .safePublic
//        )
//    }
//
//    // MARK: - Private Callback Handlers
//
//    /// Handles incoming call events from AVS.
//    private func handleIncomingCall(
//        conversationId: String,
//        shouldRing: Bool,
//        isVideoCall: Bool
//    ) {
//        WireLogger.calling.info(
//            "CallKitReportingCoordinator: onIncomingCall fired, conversationId=\(conversationId), shouldRing=\(shouldRing)",
//            attributes: .newNSE, .safePublic
//        )
//
//        guard let qualifiedID = QualifiedID(rawValue: conversationId) else {
//            WireLogger.calling.error(
//                "CallKitReportingCoordinator: invalid conversation ID: \(conversationId)",
//                attributes: .newNSE, .safePublic
//            )
//            return
//        }
//
//        let callKitContent: [String: Any] = [
//            "accountID": accountID.uuidString,
//            "conversationID": qualifiedID.uuid.uuidString,
//            "shouldRing": shouldRing,
//            "hasVideo": isVideoCall,
//            "callerName": ""
//        ]
//
//        didReportIncomingCall = shouldRing
//
//        WireLogger.calling.debug(
//            "CallKitReportingCoordinator: reporting to CallKit, content: \(callKitContent)",
//            attributes: .newNSE, .safePublic
//        )
//
//        callKitReportTask = Task {
//            await withCheckedContinuation { continuation in
//                CXProvider.reportNewIncomingVoIPPushPayload(callKitContent) { error in
//                    if let error {
//                        WireLogger.calling.error(
//                            "CallKitReportingCoordinator: reportNewIncomingVoIPPushPayload error: \(error)",
//                            attributes: .newNSE, .safePublic
//                        )
//                    } else {
//                        WireLogger.calling.info(
//                            "CallKitReportingCoordinator: reportNewIncomingVoIPPushPayload done",
//                            attributes: .newNSE, .safePublic
//                        )
//                    }
//                    continuation.resume()
//                }
//            }
//        }
//    }
//
//    /// Handles call closed events from AVS.
//    private func handleCallClosed(reason: CallClosedReason, conversationId: String) {
//        WireLogger.calling.info(
//            "CallKitReportingCoordinator: onCallClosed fired, reason=\(reason)",
//            attributes: .newNSE, .safePublic
//        )
//
//        guard didReportIncomingCall else {
//            WireLogger.calling.debug(
//                "CallKitReportingCoordinator: no incoming call was reported, skipping CallKit update",
//                attributes: .newNSE, .safePublic
//            )
//            return
//        }
//
//        // Stop ringing — only if we previously started it
//        let callKitContent: [String: Any] = [
//            "accountID": accountID.uuidString,
//            "conversationID": conversationId,
//            "shouldRing": false
//        ]
//
//        didReportIncomingCall = false
//
//        WireLogger.calling.debug(
//            "CallKitReportingCoordinator: stopping CallKit ring",
//            attributes: .newNSE, .safePublic
//        )
//
//        callKitReportTask = Task {
//            do {
//                try await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
//                WireLogger.calling.info(
//                    "CallKitReportingCoordinator: CallKit ring stopped successfully",
//                    attributes: .newNSE, .safePublic
//                )
//            } catch {
//                WireLogger.calling.error(
//                    "CallKitReportingCoordinator: error stopping CallKit ring: \(error)",
//                    attributes: .newNSE, .safePublic
//                )
//            }
//        }
//    }
//}

/// Coordinates CallKit reporting in response to AVS calling events.
/// Callback-based, no stream/bus abstraction.
final class CallKitReportingCoordinator {

    // MARK: - Properties

    private let accountID: UUID
    private var didReportIncomingCall = false
    private let conversationLocalStore: any ConversationLocalStoreProtocol
    private let userLocalStore: any UserLocalStoreProtocol
    private let context: NSManagedObjectContext

    // Keep all callback-created async work so NSE can await it.
    private let pendingTasksLock = NSLock()
    private var pendingTasks: [UUID: Task<Void, Never>] = [:]

    // Non-blocking proof that callbacks were alive.
    private let callbackCountLock = NSLock()
    private var _callbackCount = 0
    var callbackCount: Int {
        callbackCountLock.lock()
        defer { callbackCountLock.unlock() }
        return _callbackCount
    }

    // MARK: - Init

    init(
        accountID: UUID,
        avsService: any AVSCallingEventServiceProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol,
        context: NSManagedObjectContext
    ) {
        self.accountID = accountID
        self.conversationLocalStore = conversationLocalStore
        self.userLocalStore = userLocalStore
        self.context = context

        WireLogger.calling.debug(
            "CallKitReportingCoordinator: initializing for account \(accountID)",
            attributes: .newNSE, .safePublic
        )

        avsService.onIncomingCall = { [self] conversationId, userId, shouldRing, isVideoCall in
            markCallbackReceived()
            handleIncomingCall(
                conversationId: conversationId,
                userId: userId,
                shouldRing: shouldRing,
                isVideoCall: isVideoCall
            )
        }

        avsService.onMissedCall = { [self] conversationId, _, _ in
            markCallbackReceived()
            WireLogger.calling.info(
                "CallKitReportingCoordinator: onMissedCall fired, conversationId=\(conversationId)",
                attributes: .newNSE, .safePublic
            )
        }

        avsService.onCallClosed = { [self] reason, conversationId in
            markCallbackReceived()
            handleCallClosed(reason: reason, conversationId: conversationId)
        }
    }

    deinit {
        WireLogger.calling.debug(
            "CallKitReportingCoordinator: deallocating (callbackCount=\(callbackCount))",
            attributes: .newNSE, .safePublic
        )
    }

    // MARK: - Public API

    /// Wait for all callback-started CallKit tasks to finish.
    /// Does not wait for "future callbacks", only current outstanding tasks.
    func waitForCompletion() async {
        WireLogger.calling.debug(
            "CallKitReportingCoordinator: waiting for completion (callbackCount=\(callbackCount))",
            attributes: .newNSE, .safePublic
        )

        while true {
            let snapshot: [Task<Void, Never>] = {
                pendingTasksLock.lock()
                defer { pendingTasksLock.unlock() }
                return Array(pendingTasks.values)
            }()

            guard !snapshot.isEmpty else { break }

            for task in snapshot {
                await task.value
            }
        }

        WireLogger.calling.debug(
            "CallKitReportingCoordinator: completion awaited",
            attributes: .newNSE, .safePublic
        )
    }

    // MARK: - Private Helpers

    private func markCallbackReceived() {
        callbackCountLock.lock()
        _callbackCount += 1
        callbackCountLock.unlock()
    }

    private func registerPendingTask(_ task: Task<Void, Never>) {
        let id = UUID()

        pendingTasksLock.lock()
        pendingTasks[id] = task
        pendingTasksLock.unlock()

        Task { [weak self] in
            await task.value
            guard let self else { return }
            self.pendingTasksLock.lock()
            self.pendingTasks.removeValue(forKey: id)
            self.pendingTasksLock.unlock()
        }
    }

    // MARK: - Callback Handlers

    private func handleIncomingCall(
        conversationId: String,
        userId: String,
        shouldRing: Bool,
        isVideoCall: Bool
    ) {
        WireLogger.calling.info(
            "CallKitReportingCoordinator: onIncomingCall fired, conversationId=\(conversationId), shouldRing=\(shouldRing)",
            attributes: .newNSE, .safePublic
        )

        guard let qualifiedID = QualifiedID(rawValue: conversationId) else {
            WireLogger.calling.error(
                "CallKitReportingCoordinator: invalid conversation ID: \(conversationId)",
                attributes: .newNSE, .safePublic
            )
            return
        }

        guard let senderID = QualifiedID(rawValue: userId) else { return }
        didReportIncomingCall = shouldRing

       // let task = Task {
//        let callerName = await resolveCallerName(conversationID: qualifiedID, senderID: senderID)
        let callerName = resolveCallerNameSync(
            conversationID: qualifiedID,
            senderID: senderID
        )
        let callKitContent: [String: Any] = [
            "accountID": accountID.uuidString,
            "conversationID": qualifiedID.uuid.uuidString,
            "shouldRing": shouldRing,
            "hasVideo": isVideoCall,
            "callerName": callerName ?? "",

        ]
        WireLogger.calling.info(
             "‼️ CallKitReportingCoordinator: callerName=\(callerName)",
            attributes: .newNSE, .safePublic
        )
            let task = Task {
            await withCheckedContinuation { continuation in
                CXProvider.reportNewIncomingVoIPPushPayload(callKitContent) { error in
                    if let error {
                        WireLogger.calling.error(
                            "CallKitReportingCoordinator: report incoming failed: \(error)",
                            attributes: .newNSE, .safePublic
                        )
                    } else {
                        WireLogger.calling.info(
                            "CallKitReportingCoordinator: report incoming done",
                            attributes: .newNSE, .safePublic
                        )
                    }
                    continuation.resume()
                }
            }
        }

        registerPendingTask(task)
    }

//    private func resolveCallerNameSync(
//        conversationID: QualifiedID,
//        senderID: QualifiedID
//    ) -> String? {
//        let conversation = context.performAndWait {
//            ZMConversation.fetch(
//                with: conversationID.uuid,
//                domain: conversationID.domain,
//                in: context
//            )
//        }
//        let caller = context.performAndWait {
//            return ZMUser.fetch(with: senderID.uuid, in: context)
//        }
//        let selfUser = context.performAndWait {
//            return ZMUser.selfUser(in: context)
//        }
//
//        guard let conversation else { return nil }
//        let isGroup = conversation.conversationType == .group
//        let teamName = selfUser.teamName
//        let conversationName = conversation.displayName
//        let callerName = caller?.name
//
//        let format: NotificationTitle.MessageTitleDescriptor? = if isGroup, let conversationName {
//            if let teamName { .conversationInTeam(conversation: conversationName, team: teamName) }
//            else { .conversation(conversation: conversationName) }
//        } else if let callerName {
//            if let teamName { .senderInTeam(sender: callerName, team: teamName) }
//            else { .sender(sender: callerName) }
//        } else {
//            nil
//        }
//
//        return format.map { NotificationTitle.conversationMessage($0).make() }
//    }

    private func resolveCallerNameSync(
        conversationID: QualifiedID,
        senderID: QualifiedID
    ) -> String? {
        context.performAndWait {
            guard let conversation = fetchByDomain(ZMConversation.self, qualifiedID: conversationID) else {
                WireLogger.calling.info(
                     "‼️ CallKitReportingCoordinator: no conversation",
                    attributes: .newNSE, .safePublic
                )
                return nil
            }
            let caller = fetchByDomain(ZMUser.self, qualifiedID: senderID)

            // All reads stay on the context queue.
            let isGroup = conversation.conversationType == .group
            let conversationName = conversation.displayName
            let callerName = caller?.name
            let teamName = conversation.team?.name

            let format: NotificationTitle.MessageTitleDescriptor? = if isGroup, let conversationName {
                if let teamName { .conversationInTeam(conversation: conversationName, team: teamName) }
                else { .conversation(conversation: conversationName) }
            } else if let callerName {
                if let teamName { .senderInTeam(sender: callerName, team: teamName) }
                else { .sender(sender: callerName) }
            } else {
                nil
            }

            guard let format else {
                WireLogger.calling.info(
                     "‼️ CallKitReportingCoordinator: no format",
                    attributes: .newNSE, .safePublic
                )
                return nil
            }
            return NotificationTitle.conversationMessage(format).make()
        }
    }

    /// Domain-aware fetch that mirrors `ZMManagedObject.fetch(with:domain:in:)`,
    /// but derives the local domain from the context instead of `ZMUser.selfUser(in:)`
    /// — selfUser is not a pure read (it can insert + save a session) and crashes in the NSE.
//    private func fetchByDomain<T: ZMManagedObject>(
//        _ type: T.Type,
//        qualifiedID: QualifiedID
//    ) -> T? {
//        let effectiveDomain: String? =
//            (context.isFederationEnabled && !qualifiedID.domain.isEmpty) ? qualifiedID.domain : nil
//        let localDomain = context.localDomain
//        let isSearchingLocalDomain =
//            effectiveDomain == nil || localDomain == nil || localDomain == effectiveDomain
//
//        WireLogger.calling.info(
//             "‼️ CallKitReportingCoordinator: fetchByDomain qualifiedID: \(qualifiedID.uuid), effectiveDomain: \(effectiveDomain), localDomain: \(localDomain), searchingLocalDomain: \(isSearchingLocalDomain)",
//            attributes: .newNSE, .safePublic
//        )
//        return T.internalFetch(
//            withRemoteIdentifier: qualifiedID.uuid,
//            domain: effectiveDomain ?? localDomain,
//            searchingLocalDomain: isSearchingLocalDomain,
//            in: context
//        )
//    }

    private func fetchByDomain<T: ZMManagedObject>(
        _ type: T.Type,
        qualifiedID: QualifiedID
    ) -> T? {
        let effectiveDomain: String? =
            (context.isFederationEnabled && !qualifiedID.domain.isEmpty) ? qualifiedID.domain : nil

        // No domain in the event → UUID-only fetch.
        // Remote identifiers are globally unique, so this is unambiguous, and it
        // won't be excluded by a local-domain predicate that doesn't match the
        // conversation's stored domain.
        guard let effectiveDomain else {
            return T.internalFetch(withRemoteIdentifier: qualifiedID.uuid, in: context)
        }

        let localDomain = context.localDomain
        let isSearchingLocalDomain = localDomain == nil || localDomain == effectiveDomain
        return T.internalFetch(
            withRemoteIdentifier: qualifiedID.uuid,
            domain: effectiveDomain,
            searchingLocalDomain: isSearchingLocalDomain,
            in: context
        )
    }

    private func handleCallClosed(reason: CallClosedReason, conversationId: String) {
        WireLogger.calling.info(
            "CallKitReportingCoordinator: onCallClosed fired, reason=\(reason)",
            attributes: .newNSE, .safePublic
        )
        guard let qualifiedID = QualifiedID(rawValue: conversationId) else {
            WireLogger.calling.error(
                "CallKitReportingCoordinator: invalid conversation ID: \(conversationId)",
                attributes: .newNSE, .safePublic
            )
            return
        }
        guard didReportIncomingCall else {
            WireLogger.calling.debug(
                "CallKitReportingCoordinator: skipping close report (no incoming reported)",
                attributes: .newNSE, .safePublic
            )
            return
        }

        // Keep previous behavior: use raw conversationId on close.
        let callKitContent: [String: Any] = [
            "accountID": accountID.uuidString,
            "conversationID": qualifiedID.uuid.uuidString,
            "shouldRing": false
        ]

        didReportIncomingCall = false

        let task = Task {
            do {
                try await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
                WireLogger.calling.info(
                    "CallKitReportingCoordinator: stop ring done",
                    attributes: .newNSE, .safePublic
                )
            } catch {
                WireLogger.calling.error(
                    "CallKitReportingCoordinator: stop ring failed: \(error)",
                    attributes: .newNSE, .safePublic
                )
            }
        }

        registerPendingTask(task)
    }
}

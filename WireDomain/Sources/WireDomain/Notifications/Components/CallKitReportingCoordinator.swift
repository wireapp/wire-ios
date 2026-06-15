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

import CallKit
import Foundation
import WireLogging

/// Coordinates CallKit reporting in response to AVS calling events.
/// Callback-based, no stream/bus abstraction.
final class CallKitReportingCoordinator {

    // MARK: - Properties

    private let accountID: UUID
    private var didReportIncomingCall = false
    private let callerNamesLock = NSLock()
    private var callerNamesByConversationID: [String: String] = [:]

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
        avsService: any AVSCallingEventServiceProtocol
    ) {
        self.accountID = accountID

        avsService.onIncomingCall = { [self] conversationId, userId, shouldRing, isVideoCall in
            markCallbackReceived()
            handleIncomingCall(
                conversationId: conversationId,
                userId: userId,
                shouldRing: shouldRing,
                isVideoCall: isVideoCall
            )
        }

        avsService.onMissedCall = { [self] _, _, _ in
            markCallbackReceived()
        }

        avsService.onCallClosed = { [self] reason, conversationId in
            markCallbackReceived()
            handleCallClosed(reason: reason, conversationId: conversationId)
        }
    }

    // MARK: - Public API

    func setCallerName(
        _ callerName: String?,
        for conversationId: String
    ) {
        guard let conversationID = AVSIdentifier(rawValue: conversationId) else { return }

        callerNamesLock.lock()
        defer { callerNamesLock.unlock() }

        callerNamesByConversationID[conversationID.storageKey] = callerName
    }

    /// Wait for all callback-started CallKit tasks to finish.
    /// Does not wait for "future callbacks", only current outstanding tasks.
    func waitForCompletion() async {

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
            pendingTasksLock.lock()
            pendingTasks.removeValue(forKey: id)
            pendingTasksLock.unlock()
        }
    }

    private func callerName(for conversationID: AVSIdentifier) -> String? {
        callerNamesLock.lock()
        defer { callerNamesLock.unlock() }

        return callerNamesByConversationID[conversationID.storageKey]
    }

    private func removeCallerName(for conversationID: AVSIdentifier) {
        callerNamesLock.lock()
        defer { callerNamesLock.unlock() }

        callerNamesByConversationID.removeValue(forKey: conversationID.storageKey)
    }

    // MARK: - Callback Handlers

    private func handleIncomingCall(
        conversationId: String,
        userId: String,
        shouldRing: Bool,
        isVideoCall: Bool
    ) {
        guard let conversationID = AVSIdentifier(rawValue: conversationId) else {
            WireLogger.calling.error(
                "CallKitReportingCoordinator: invalid conversation ID: \(conversationId)",
                attributes: .newNSE, .safePublic
            )
            return
        }

        didReportIncomingCall = shouldRing
        let callerName = callerName(for: conversationID)

        let callKitContent: [String: Any] = [
            "accountID": accountID.uuidString,
            "conversationID": conversationID.uuid.uuidString,
            "shouldRing": shouldRing,
            "hasVideo": isVideoCall,
            "callerName": callerName ?? ""
        ]

        let task = Task {
            await withCheckedContinuation { continuation in
                CXProvider.reportNewIncomingVoIPPushPayload(callKitContent) { error in
                    // TODO: do we need these logs?
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

    private func handleCallClosed(reason: CallClosedReason, conversationId: String) {
        guard let conversationID = AVSIdentifier(rawValue: conversationId) else {
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
            "conversationID": conversationID.uuid.uuidString,
            "shouldRing": false
        ]

        didReportIncomingCall = false
        removeCallerName(for: conversationID)

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

// TODO: where to move?
private struct AVSIdentifier {
    let uuid: UUID
    let domain: String?

    var storageKey: String {
        "\(uuid.uuidString.lowercased())@\(domain?.lowercased() ?? "")"
    }

    init?(rawValue: String) {
        let components = rawValue.split(
            separator: "@",
            omittingEmptySubsequences: false
        ).map(String.init)

        switch components.count {
        case 1:
            guard let uuid = UUID(uuidString: components[0]) else { return nil }
            self.uuid = uuid
            self.domain = nil
        case 2:
            guard let uuid = UUID(uuidString: components[0]) else { return nil }
            self.uuid = uuid
            self.domain = components[1].isEmpty ? nil : components[1]
        default:
            return nil
        }
    }
}

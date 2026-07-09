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

/// Coordinates CallKit reporting for AVS calling-event callback results.
///
/// `AVSCallingEventService` invokes its callbacks only after the NSE has finished
/// processing a synchronized batch of calling events. This coordinator registers
/// those callbacks, keeps the caller metadata needed for CallKit payloads, and
/// reports the resulting incoming or closed-call actions to CallKit.
///
/// Callback-triggered CallKit work is tracked as pending tasks so the NSE can wait
/// for reporting to finish before continuing with regular notification generation.
actor CallKitReportingCoordinator {

    // MARK: - Properties

    private let accountID: UUID
    private var didReportIncomingCall = false
    private var callerNamesByConversationID: [String: String] = [:]
    private var pendingTasks: [UUID: Task<Void, Never>] = [:]
    // MARK: - Init

    init(
        accountID: UUID,
        avsService: any AVSCallingEventServiceProtocol
    ) {
        self.accountID = accountID

        avsService.onIncomingCall = { [self] conversationId, userId, shouldRing, isVideoCall in
            Task {
                await self.handleIncomingCall(
                    conversationId: conversationId,
                    userId: userId,
                    shouldRing: shouldRing,
                    isVideoCall: isVideoCall
                )
            }
        }

        avsService.onMissedCall = { _, _, _ in }

        avsService.onCallClosed = { [self] reason, conversationId in
            Task {
                await self.handleCallClosed(reason: reason, conversationId: conversationId)
            }
        }
    }

    // MARK: - Public API

    func setCallerName(
        _ callerName: String?,
        for conversationId: String
    ) {
        guard let conversationID = AVSIdentifier(rawValue: conversationId) else { return }
        callerNamesByConversationID[conversationID.storageKey] = callerName
        WireLogger.calling.debug("🚀 callerNamesByConversationID: \(callerNamesByConversationID)", attributes: .newNSE, .safePublic)

    }

    /// Wait for all callback-started CallKit tasks to finish.
    func waitForCompletion() async {
        while true {
            let snapshot = Array(pendingTasks.values)
            guard !snapshot.isEmpty else { break }
            for task in snapshot {
                await task.value
            }
        }
    }

    // MARK: - Private Helpers

    private func registerPendingTask(_ task: Task<Void, Never>) {
        let id = UUID()
        pendingTasks[id] = task

        Task {
            await task.value
            pendingTasks.removeValue(forKey: id)
        }
    }

    private func callerName(for conversationID: AVSIdentifier) -> String? {
        callerNamesByConversationID[conversationID.storageKey]
    }

    private func removeCallerName(for conversationID: AVSIdentifier) {
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
        WireLogger.calling.debug("🚀 CallKitReportingCoordinator: lookup key: \(conversationID.storageKey), stored keys: \(callerNamesByConversationID.keys.joined(separator: ", "))", attributes: .newNSE, .safePublic)
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

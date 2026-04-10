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
final class CallKitReportingCoordinator {

    // MARK: - Properties

    private let accountID: UUID
    private var callKitReportTask: Task<Void, Never>?
    private var didReportIncomingCall: Bool = false

    // MARK: - Initialization

    /// Creates a coordinator and sets up AVS callbacks.
    ///
    /// - Parameters:
    ///   - accountID: The account identifier for CallKit content
    ///   - avsService: The AVS service to observe for calling events
    ///
    /// **Important:** This initializer sets callbacks on the AVS service that
    /// capture `self` strongly. This is safe because the coordinator doesn't
    /// own the service, preventing retain cycles.
    init(accountID: UUID, avsService: any AVSCallingEventServiceProtocol) {
        self.accountID = accountID

        WireLogger.calling.debug(
            "CallKitReportingCoordinator: initializing for account \(accountID)",
            attributes: .newNSE, .safePublic
        )

        // Set up callbacks - capturing self strongly is safe here
        // because we don't own avsService (no retain cycle)
        avsService.onIncomingCall = { [self] conversationId, shouldRing, isVideoCall in
            self.handleIncomingCall(
                conversationId: conversationId,
                shouldRing: shouldRing,
                isVideoCall: isVideoCall
            )
        }

        avsService.onMissedCall = { conversationId, messageTime, isVideoCall in
            WireLogger.calling.info(
                "CallKitReportingCoordinator: onMissedCall fired",
                attributes: .newNSE, .safePublic
            )
            // Nothing to do here — the missed call text notification
            // is already built by ConversationCallingEventNotificationBuilder
            // from the same event in the event stream.
            WireLogger.calling.info(
                "AVS: missed call in conversation \(conversationId)",
                attributes: .newNSE, .safePublic
            )
        }

        avsService.onCallClosed = { [self] reason, conversationId in
            self.handleCallClosed(reason: reason, conversationId: conversationId)
        }
    }

    deinit {
        WireLogger.calling.debug(
            "CallKitReportingCoordinator: deallocating",
            attributes: .newNSE, .safePublic
        )
    }

    // MARK: - Public API

    /// Waits for any pending CallKit reporting tasks to complete.
    ///
    /// Call this before finishing notification processing to ensure
    /// CallKit has been properly notified.
    ///
    /// - Returns: Completes when the CallKit task finishes (or immediately if no task)
    func waitForCompletion() async {
        WireLogger.calling.debug(
            "CallKitReportingCoordinator: waiting for completion",
            attributes: .newNSE, .safePublic
        )

        await callKitReportTask?.value

        WireLogger.calling.debug(
            "CallKitReportingCoordinator: completion awaited",
            attributes: .newNSE, .safePublic
        )
    }

    // MARK: - Private Callback Handlers

    /// Handles incoming call events from AVS.
    private func handleIncomingCall(
        conversationId: String,
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

        let callKitContent: [String: Any] = [
            "accountID": accountID.uuidString,
            "conversationID": qualifiedID.uuid.uuidString,
            "shouldRing": shouldRing,
            "hasVideo": isVideoCall,
            "callerName": ""
        ]

        didReportIncomingCall = shouldRing

        WireLogger.calling.debug(
            "CallKitReportingCoordinator: reporting to CallKit, content: \(callKitContent)",
            attributes: .newNSE, .safePublic
        )

        callKitReportTask = Task {
            await withCheckedContinuation { continuation in
                CXProvider.reportNewIncomingVoIPPushPayload(callKitContent) { error in
                    if let error {
                        WireLogger.calling.error(
                            "CallKitReportingCoordinator: reportNewIncomingVoIPPushPayload error: \(error)",
                            attributes: .newNSE, .safePublic
                        )
                    } else {
                        WireLogger.calling.info(
                            "CallKitReportingCoordinator: reportNewIncomingVoIPPushPayload done",
                            attributes: .newNSE, .safePublic
                        )
                    }
                    continuation.resume()
                }
            }
        }
    }

    /// Handles call closed events from AVS.
    private func handleCallClosed(reason: CallClosedReason, conversationId: String) {
        WireLogger.calling.info(
            "CallKitReportingCoordinator: onCallClosed fired, reason=\(reason)",
            attributes: .newNSE, .safePublic
        )

        guard didReportIncomingCall else {
            WireLogger.calling.debug(
                "CallKitReportingCoordinator: no incoming call was reported, skipping CallKit update",
                attributes: .newNSE, .safePublic
            )
            return
        }

        // Stop ringing — only if we previously started it
        let callKitContent: [String: Any] = [
            "accountID": accountID.uuidString,
            "conversationID": conversationId,
            "shouldRing": false
        ]

        didReportIncomingCall = false

        WireLogger.calling.debug(
            "CallKitReportingCoordinator: stopping CallKit ring",
            attributes: .newNSE, .safePublic
        )

        callKitReportTask = Task {
            do {
                try await CXProvider.reportNewIncomingVoIPPushPayload(callKitContent)
                WireLogger.calling.info(
                    "CallKitReportingCoordinator: CallKit ring stopped successfully",
                    attributes: .newNSE, .safePublic
                )
            } catch {
                WireLogger.calling.error(
                    "CallKitReportingCoordinator: error stopping CallKit ring: \(error)",
                    attributes: .newNSE, .safePublic
                )
            }
        }
    }
}

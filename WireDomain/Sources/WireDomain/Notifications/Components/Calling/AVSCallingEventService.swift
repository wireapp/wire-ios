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

import avs
import Foundation
import WireLogging

public protocol AVSCallingEventServiceProtocol: AnyObject {
    var onIncomingCall: ((_ conversationId: String, _ userId: String, _ shouldRing: Bool, _ isVideoCall: Bool)
        -> Void)? { get set }
    var onMissedCall: ((_ conversationId: String, _ messageTime: Date, _ isVideoCall: Bool) -> Void)? { get set }
    var onCallClosed: ((_ reason: CallClosedReason, _ conversationId: String) -> Void)? { get set }

    func start()
    func process(
        data: Data,
        currentTime: UInt32,
        serverTime: UInt32,
        conversationId: String,
        userId: String,
        clientId: String,
        conversationType: Int32
    )
    func end()
}

/// Bridges NSE calling-event processing to the AVS `wcall_event_*` API.
///
/// The service owns the AVS calling-event handle created with `wcall_event_create()`
/// and reuses it for all subsequent batch-processing calls. It exposes Swift closures
/// for the AVS callback results so callers can react to incoming, missed, and closed
/// calls without dealing with C callback signatures directly.
///
/// A typical NSE flow is:
/// - call `start()` before processing synchronized notification events
/// - call `process(...)` for each call-related event
/// - call `end()` after synchronization is complete, allowing AVS to evaluate the
///   batch and invoke the registered callbacks
public final class AVSCallingEventService: AVSCallingEventServiceProtocol {

    // MARK: - Closure properties (set by the caller in NSEClientScope)

    public var onIncomingCall: ((_ conversationId: String, _ userId: String, _ shouldRing: Bool, _ isVideoCall: Bool)
        -> Void)?
    public var onMissedCall: ((_ conversationId: String, _ messageTime: Date, _ isVideoCall: Bool) -> Void)?
    public var onCallClosed: ((_ reason: CallClosedReason, _ conversationId: String) -> Void)?

    // MARK: - Private

    private var handle: UInt32
    private var contextPointer: UnsafeMutableRawPointer?
    private let userID: String
    private let clientID: String

    // MARK: - Init

    // Per the AVS team: wcall_event_create must be called once per account and
    // returns a distinct handle per (userID, clientID). The `arg` context pointer
    // passed at creation is handed back verbatim in every callback for that handle,
    // so each account's callbacks can be routed to its own instance. The NSE is a
    // long-lived process shared across accounts, so we cache one instance per
    // identity and reuse it across NSE invocations, keeping each account's handle
    // and contextRef stable while isolating accounts from one another.
    private nonisolated(unsafe) static var processInstances: [String: AVSCallingEventService] = [:]
    private static let instancesLock = NSLock()

    public static func shared(userID: String, clientID: String) -> AVSCallingEventService {
        let key = "\(userID)|\(clientID)"
        instancesLock.lock()
        defer { instancesLock.unlock() }
        if let existing = processInstances[key] {
            WireLogger.calling.info(
                "AVS-DIAG: shared() reusing instance for account=\(userID) (cached count=\(processInstances.count))",
                attributes: .newNSE, .safePublic
            )
            return existing
        }
        let instance = AVSCallingEventService(userID: userID, clientID: clientID)
        processInstances[key] = instance
        WireLogger.calling.info(
            "AVS-DIAG: shared() created new instance for account=\(userID) (cached count=\(processInstances.count))",
            attributes: .newNSE, .safePublic
        )
        return instance
    }

    public init(userID: String, clientID: String) {
        self.userID = userID
        self.clientID = clientID
        self.handle = 0
        wcall_set_log_handler({ _, msgPtr, _ in
            guard let msg = msgPtr.flatMap({ String(cString: $0) }) else { return }
            WireLogger.calling.debug(msg, attributes: .newNSE, .safePublic)
        }, nil)
        let retained = Unmanaged.passRetained(self)
        self.contextPointer = retained.toOpaque()
        self.handle = wcall_event_create(
            userID,
            clientID,
            Self.incomingCallHandler,
            Self.missedCallHandler,
            Self.closedCallHandler,
            contextPointer
        )
        WireLogger.calling.info(
            "AVS-DIAG: called wcall_event_create for userID=\(userID), clientID=\(clientID), (handle=\(self.handle)), contextPointer=\(contextPointer)",
            attributes: .newNSE, .safePublic
        )
        WireLogger.calling.info(
            """
            AVS-DIAG: wcall_event_create returned handle=\(handle) \
            context=\(contextPointer.map(String.init(describing:)) ?? "nil") \
            account=\(userID) client=\(clientID)
            """,
            attributes: .newNSE, .safePublic
        )
    }

    deinit {
        if let ptr = contextPointer {
            Unmanaged<AVSCallingEventService>.fromOpaque(ptr).release()
        }
    }

    // MARK: - AVSCallingEventServiceProtocol

    public func start() {
        WireLogger.calling.debug(
            "AVS-DIAG: wcall_event_start handle=\(handle) account=\(userID)",
            attributes: .newNSE, .safePublic
        )
        wcall_event_start(handle)
    }

    public func process(
        data: Data,
        currentTime: UInt32,
        serverTime: UInt32,
        conversationId: String,
        userId: String,
        clientId: String,
        conversationType: Int32
    ) {
        WireLogger.calling.info(
            """
            AVS-DIAG: process feeding conversationId=\(conversationId) \
            handle=\(handle) account=\(userID) \
            ownContext=\(contextPointer.map(String.init(describing:)) ?? "nil")
            """,
            attributes: .newNSE, .safePublic
        )
        data.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
            wcall_event_process(
                handle,
                bytes,
                data.count,
                currentTime,
                serverTime,
                conversationId,
                userId,
                clientId,
                conversationType
            )
        }
    }

    public func end() {
        WireLogger.calling.debug(
            "AVS-DIAG: wcall_event_end (evaluating batch) handle=\(handle) account=\(userID)",
            attributes: .newNSE, .safePublic
        )
        wcall_event_end(handle)
    }

    // MARK: - Diagnostics

    /// Describes every registered instance as "account=context", so a callback log
    /// can show the full set of distinct contexts we passed to wcall_event_create
    /// next to the single `arg` AVS actually hands back.
    private static func knownContextsDescription() -> String {
        instancesLock.lock()
        defer { instancesLock.unlock() }
        return processInstances.values
            .map { "\($0.userID)@\($0.contextPointer.map(String.init(describing:)) ?? "nil")" }
            .joined(separator: ", ")
    }

    // MARK: - Static C Callbacks

    //
    // These match the exact C function pointer signatures expected by wcall_create.
    // contextRef is the Unmanaged pointer to self, set during init.

    private static let incomingCallHandler: @convention(c) (
        UnsafePointer<Int8>?,   // conversationId
        UInt32,                  // messageTime
        UnsafePointer<Int8>?,   // userId
        UnsafePointer<Int8>?,   // clientId
        Int32,                   // isVideoCall (1 = true)
        Int32,                   // shouldRing  (1 = true)
        Int32,                   // conversationType
        UnsafeMutableRawPointer? // contextRef → self
    ) -> Void = { conversationIdPtr, _, userIdPtr, _, isVideoCallFlag, shouldRingFlag, _, contextRef in
        guard
            let contextRef,
            let conversationId = conversationIdPtr.flatMap({ String(cString: $0) }),
            let userId = userIdPtr.flatMap({ String(cString: $0) })
        else {
            WireLogger.calling.warn(
                "AVS callback: incoming call dropped (missing context or IDs)",
                attributes: .newNSE, .safePublic
            )
            return
        }

        let service = Unmanaged<AVSCallingEventService>.fromOpaque(contextRef).takeUnretainedValue()
        WireLogger.calling.info(
            """
            AVS-DIAG: incoming callback arg=\(contextRef) \
            resolved handle=\(service.handle) account=\(service.userID) \
            knownContexts=[\(AVSCallingEventService.knownContextsDescription())] \
            payload conversationId=\(conversationId) userId=\(userId) \
            (shouldRing: \(shouldRingFlag == 1), video: \(isVideoCallFlag == 1))
            """,
            attributes: .newNSE, .safePublic
        )
        service.onIncomingCall?(
            conversationId,
            userId,
            shouldRingFlag == 1,
            isVideoCallFlag == 1
        )
    }

    private static let missedCallHandler: @convention(c) (
        UnsafePointer<Int8>?,   // conversationId
        UInt32,                  // messageTime
        UnsafePointer<Int8>?,   // userId
        UnsafePointer<Int8>?,   // clientId
        Int32,                   // isVideoCall (1 = true)
        UnsafeMutableRawPointer? // contextRef → self
    ) -> Void = { conversationIdPtr, messageTime, _, _, isVideoCallFlag, contextRef in
        guard
            let contextRef,
            let conversationId = conversationIdPtr.flatMap({ String(cString: $0) })
        else {
            WireLogger.calling.warn(
                "AVS callback: missed call dropped (missing context or ID)",
                attributes: .newNSE, .safePublic
            )
            return
        }

        let service = Unmanaged<AVSCallingEventService>.fromOpaque(contextRef).takeUnretainedValue()
        WireLogger.calling.info(
            """
            AVS-DIAG: missed callback arg=\(contextRef) \
            resolved handle=\(service.handle) account=\(service.userID) \
            knownContexts=[\(AVSCallingEventService.knownContextsDescription())] \
            payload conversationId=\(conversationId)
            """,
            attributes: .newNSE, .safePublic
        )
        // Mirror AVSWrapper: treat messageTime=0 as "now"
        let nonZeroTime = messageTime != 0 ? messageTime : UInt32(Date().timeIntervalSince1970)
        service.onMissedCall?(
            conversationId,
            Date(timeIntervalSince1970: TimeInterval(nonZeroTime)),
            isVideoCallFlag == 1
        )
    }

    private static let closedCallHandler: @convention(c) (
        Int32,                   // reason (WCALL_REASON_*)
        UnsafePointer<Int8>?,   // conversationId
        UInt32,                  // messageTime
        UnsafePointer<Int8>?,   // userId
        UnsafePointer<Int8>?,   // clientId
        UnsafeMutableRawPointer? // contextRef → self
    ) -> Void = { reasonCode, conversationIdPtr, _, _, _, contextRef in
        guard
            let contextRef,
            let conversationId = conversationIdPtr.flatMap({ String(cString: $0) })
        else {
            WireLogger.calling.warn(
                "AVS callback: call closed dropped (missing context or ID)",
                attributes: .newNSE, .safePublic
            )
            return
        }

        let reason = CallClosedReason(wcall_reason: reasonCode)
        let service = Unmanaged<AVSCallingEventService>.fromOpaque(contextRef).takeUnretainedValue()
        WireLogger.calling.info(
            """
            AVS-DIAG: closed callback arg=\(contextRef) \
            resolved handle=\(service.handle) account=\(service.userID) \
            knownContexts=[\(AVSCallingEventService.knownContextsDescription())] \
            payload conversationId=\(conversationId) reason=\(reason)
            """,
            attributes: .newNSE, .safePublic
        )
        service.onCallClosed?(
            reason,
            conversationId
        )
    }
}

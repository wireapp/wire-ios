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

public enum CallClosedReason: Int32, Sendable {
    case normal
    case canceled
    case answeredElsewhere
    case rejectedElsewhere
    case timeout
    case lostMedia
    case internalError
    case inputOutputError
    case stillOngoing
    case securityDegraded
    case outdatedClient
    case datachannel
    case timeoutECONN
    case noOneJoined
    case everyoneLeft
    case unknown

    init(wcall_reason: Int32) {
        switch wcall_reason {
        case WCALL_REASON_NORMAL:            self = .normal
        case WCALL_REASON_CANCELED:          self = .canceled
        case WCALL_REASON_ANSWERED_ELSEWHERE: self = .answeredElsewhere
        case WCALL_REASON_REJECTED:          self = .rejectedElsewhere
        case WCALL_REASON_TIMEOUT:           self = .timeout
        case WCALL_REASON_LOST_MEDIA:        self = .lostMedia
        case WCALL_REASON_ERROR:             self = .internalError
        case WCALL_REASON_IO_ERROR:          self = .inputOutputError
        case WCALL_REASON_STILL_ONGOING:     self = .stillOngoing
        case WCALL_REASON_OUTDATED_CLIENT:   self = .outdatedClient
        case WCALL_REASON_TIMEOUT_ECONN:     self = .timeoutECONN
        case WCALL_REASON_DATACHANNEL:       self = .datachannel
        case WCALL_REASON_NOONE_JOINED:      self = .noOneJoined
        case WCALL_REASON_EVERYONE_LEFT:     self = .everyoneLeft
        default:                             self = .unknown
        }
    }
}

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

    // MARK: - Init

    // AVS registers C-level callbacks with a handle created in init. Calling
    // wcall_event_create a second time returns the same handle, so callbacks
    // always fire through the first instance's contextRef. We keep one instance
    // per process so the handle and contextRef are stable across NSE invocations.
    private nonisolated(unsafe) static var processInstance: AVSCallingEventService?

    public static func shared(userID: String, clientID: String) -> AVSCallingEventService {
        if let existing = processInstance {
            return existing
        }
        let instance = AVSCallingEventService(userID: userID, clientID: clientID)
        processInstance = instance
        return instance
    }

    public init(userID: String, clientID: String) {
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
    }

    deinit {
        if let ptr = contextPointer {
            Unmanaged<AVSCallingEventService>.fromOpaque(ptr).release()
        }
    }

    // MARK: - AVSCallingEventServiceProtocol

    public func start() {
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
        wcall_event_end(handle)
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
        else { return }

        let service = Unmanaged<AVSCallingEventService>.fromOpaque(contextRef).takeUnretainedValue()
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
        else { return }

        let service = Unmanaged<AVSCallingEventService>.fromOpaque(contextRef).takeUnretainedValue()
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
        else { return }

        let service = Unmanaged<AVSCallingEventService>.fromOpaque(contextRef).takeUnretainedValue()
        service.onCallClosed?(
            CallClosedReason(wcall_reason: reasonCode),
            conversationId
        )
    }
}

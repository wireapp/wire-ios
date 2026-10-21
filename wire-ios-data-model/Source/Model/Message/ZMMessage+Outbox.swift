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
import GenericMessageProtocol

public enum MessageOutboxState: Int16 {
    case notEnrolled = 0
    case queued = 1
    case preparing = 2
    case sending = 3
    case uncertain = 4
    case sent = 5
    case failed = 6
    case cancelled = 7
}

public enum MessageOutboxOperation: Int16 {
    case none = 0
    case initialMessage = 1
    case edit = 2
    case contentUpdate = 3
}

public enum MessageOutboxError: Error, Equatable {
    case invalidTransition
    case invalidOperation
    case invalidPayload
    case staleAttempt
    case retryNotDue
}

/// Immutable content claimed by one attempt. This is plaintext content, not transport ciphertext.
public struct MessageOutboxAttempt {
    public let identifier: UUID
    public let payload: Data

    fileprivate init(identifier: UUID, payload: Data) {
        self.identifier = identifier
        self.payload = payload
    }
}

public extension ZMMessage {
    @NSManaged internal var outboxStateRaw: Int16
    @NSManaged internal var outboxOperationRaw: Int16
    @NSManaged private(set) var outboxEnqueuedAt: Date?
    @NSManaged private(set) var outboxAttemptIdentifier: UUID?
    @NSManaged private(set) var outboxPayload: Data?
    @NSManaged private(set) var outboxAttemptCount: Int32
    @NSManaged private(set) var outboxNextAttemptAt: Date?
}

/// Call these operations on the owning managed object context's queue. They mutate that context only.
/// Save enrollment before reporting acceptance, and save preparation/sending before encryption/HTTP handoff.
/// A failed save must abort the attempt. Send eligibility and transport error classification belong to the sender.
public extension ZMMessage {

    /// Unknown persisted values deliberately remain unknown; they must not enter the legacy sending path.
    var outboxState: MessageOutboxState? {
        MessageOutboxState(rawValue: outboxStateRaw)
    }

    var outboxOperation: MessageOutboxOperation? {
        MessageOutboxOperation(rawValue: outboxOperationRaw)
    }

    /// Additional outbox condition for future queued editing; ordinary type/security restrictions still apply.
    var hasUnclaimedOutboxContent: Bool {
        outboxState == .queued && outboxOperation == .initialMessage && outboxPayload == nil
    }

    func enqueueInOutbox(operation: MessageOutboxOperation, at date: Date = Date()) throws {
        guard !isDeleted, !hasBeenDeleted,
              self is ZMClientMessage || self is ZMAssetClientMessage,
              outboxState == .notEnrolled || outboxState == .sent
        else {
            throw MessageOutboxError.invalidTransition
        }
        guard operation != .none,
              operation != .initialMessage || (outboxState == .notEnrolled && !delivered),
              operation != .contentUpdate || outboxState == .sent
        else {
            throw MessageOutboxError.invalidOperation
        }

        outboxStateRaw = MessageOutboxState.queued.rawValue
        outboxOperationRaw = operation.rawValue
        outboxEnqueuedAt = date
        outboxAttemptIdentifier = nil
        outboxPayload = nil
        outboxAttemptCount = 0
        outboxNextAttemptAt = nil
    }

    func prepareOutboxAttempt(payload: Data, at date: Date = Date()) throws -> MessageOutboxAttempt {
        guard !isDeleted, !hasBeenDeleted, outboxState == .queued,
              let operation = outboxOperation, operation != .none,
              outboxAttemptCount < Int32.max
        else {
            throw MessageOutboxError.invalidTransition
        }
        guard outboxNextAttemptAt.map({ $0 <= date }) ?? true else {
            throw MessageOutboxError.retryNotDue
        }

        let snapshot = outboxPayload ?? payload
        try validateOutboxPayload(snapshot)
        let attempt = MessageOutboxAttempt(identifier: UUID(), payload: snapshot)
        outboxStateRaw = MessageOutboxState.preparing.rawValue
        outboxAttemptIdentifier = attempt.identifier
        outboxAttemptCount += 1
        outboxNextAttemptAt = nil
        return attempt
    }

    /// Persist this transition and its snapshot successfully before submitting any message request.
    func markOutboxAttemptSending(_ attempt: MessageOutboxAttempt) throws {
        try requireOutboxAttempt(attempt.identifier, in: [.preparing])
        try validateOutboxPayload(attempt.payload)
        guard outboxPayload == nil || outboxPayload == attempt.payload else {
            throw MessageOutboxError.invalidPayload
        }
        outboxPayload = attempt.payload
        outboxStateRaw = MessageOutboxState.sending.rawValue
    }

    /// Use only after proven non-submission or an explicitly retryable rejection, never an ambiguous timeout.
    func rescheduleOutboxAttempt(_ identifier: UUID, notBefore date: Date? = nil) throws {
        try requireOutboxAttempt(identifier, in: [.preparing, .sending])
        outboxStateRaw = MessageOutboxState.queued.rawValue
        outboxAttemptIdentifier = nil
        outboxNextAttemptAt = date
    }

    func markOutboxAttemptUncertain(_ identifier: UUID) throws {
        try requireOutboxAttempt(identifier, in: [.sending])
        outboxStateRaw = MessageOutboxState.uncertain.rawValue
    }

    /// Finalize alongside normal delivery bookkeeping, in the same context save.
    func completeOutboxAttempt(_ identifier: UUID) throws {
        try requireOutboxAttempt(identifier, in: [.sending, .uncertain])
        outboxStateRaw = MessageOutboxState.sent.rawValue
        clearOutboxAttempt()
    }

    func failOutboxAttempt(_ identifier: UUID) throws {
        try requireOutboxAttempt(identifier, in: [.preparing, .sending, .uncertain])
        outboxStateRaw = MessageOutboxState.failed.rawValue
        outboxAttemptIdentifier = nil
        outboxNextAttemptAt = nil
    }

    func cancelOutboxOperation() throws {
        guard let state = outboxState,
              [.queued, .preparing, .sending, .uncertain, .failed].contains(state)
        else {
            throw MessageOutboxError.invalidTransition
        }
        outboxStateRaw = MessageOutboxState.cancelled.rawValue
        clearOutboxAttempt()
    }

    /// Pure local crash recovery. It neither sends work nor decides how to retry an uncertain outcome.
    func recoverOutboxAfterRestart() {
        guard !isDeleted, !hasBeenDeleted else { return }
        switch outboxState {
        case .preparing:
            outboxStateRaw = MessageOutboxState.queued.rawValue
            outboxAttemptIdentifier = nil
        case .sending:
            outboxStateRaw = MessageOutboxState.uncertain.rawValue
        default:
            break
        }
    }

    private func requireOutboxAttempt(_ identifier: UUID, in states: [MessageOutboxState]) throws {
        guard !isDeleted, !hasBeenDeleted, outboxAttemptIdentifier == identifier else {
            throw MessageOutboxError.staleAttempt
        }
        guard let state = outboxState, states.contains(state) else {
            throw MessageOutboxError.invalidTransition
        }
    }

    private func validateOutboxPayload(_ data: Data) throws {
        guard let message = try? GenericMessage(serializedData: data),
              let nonce, UUID(uuidString: message.messageID) == nonce,
              message.content != nil
        else {
            throw MessageOutboxError.invalidPayload
        }
    }

    private func clearOutboxAttempt() {
        outboxAttemptIdentifier = nil
        outboxPayload = nil
        outboxAttemptCount = 0
        outboxNextAttemptAt = nil
    }
}

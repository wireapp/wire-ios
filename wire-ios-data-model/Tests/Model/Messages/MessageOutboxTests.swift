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

import GenericMessageProtocol
import XCTest

@testable import WireDataModel

final class MessageOutboxTests: BaseZMClientMessageTests {

    func testEnabledSubmissionIsPersistedButHiddenProtocolTrafficIsNotEnrolled() throws {
        let previous = uiMOC.offlinePendingMessagesEnabled
        uiMOC.offlinePendingMessagesEnabled = true
        defer { uiMOC.offlinePendingMessagesEnabled = previous }

        let message = try makeMessage()
        XCTAssertEqual(message.outboxState, .queued)
        XCTAssertFalse(message.isInserted)
        XCTAssertNil(message.expirationDate)

        let hidden = try conversation.appendClientMessage(
            with: GenericMessage(content: Text(content: "hidden protocol content")),
            hidden: true
        )
        XCTAssertEqual(hidden.outboxState, .notEnrolled)
    }

    func testTurningOffEnrollmentDoesNotDiscardPreviouslyQueuedContent() throws {
        let previous = uiMOC.offlinePendingMessagesEnabled
        defer { uiMOC.offlinePendingMessagesEnabled = previous }
        uiMOC.offlinePendingMessagesEnabled = true
        let queued = try makeMessage()
        uiMOC.offlinePendingMessagesEnabled = false

        let legacy = try makeMessage()
        queued.recoverOutboxAfterRestart()

        XCTAssertEqual(queued.outboxState, .queued)
        XCTAssertEqual(legacy.outboxState, .notEnrolled)
    }

    func testNormalSentEditUsesAnEditOperationAndRetainsItsMarker() throws {
        let previous = uiMOC.offlinePendingMessagesEnabled
        uiMOC.offlinePendingMessagesEnabled = true
        defer { uiMOC.offlinePendingMessagesEnabled = previous }
        let message = try makeMessage()
        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(attempt)
        try message.completeOutboxAttempt(attempt.identifier)
        message.markAsSent()

        message.editText("normal edit", mentions: [], fetchLinkPreview: false)

        XCTAssertEqual(message.outboxState, .queued)
        XCTAssertEqual(message.outboxOperation, .edit)
        XCTAssertTrue(try XCTUnwrap(message.underlyingMessage).hasEdited)
        XCTAssertNotNil(message.updatedTimestamp)
    }

    func testSubmissionRemainsUnenrolledAndKeepsLegacyExpiration() throws {
        let message = try makeMessage()
        XCTAssertEqual(message.outboxState, .notEnrolled)
        XCTAssertEqual(message.outboxOperation, MessageOutboxOperation.none)
        XCTAssertNil(message.outboxEnqueuedAt)
        XCTAssertNil(try message.loadOutboxPayload())
        XCTAssertFalse(message.hasUnclaimedOutboxContent)

        message.expire(withReason: .timeout)
        message.recoverOutboxAfterRestart()

        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(message.outboxState, .notEnrolled)
    }

    func testOnlyOneAttemptCanClaimQueuedContent() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        XCTAssertTrue(message.hasUnclaimedOutboxContent)

        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))

        XCTAssertEqual(message.outboxState, .preparing)
        XCTAssertFalse(message.hasUnclaimedOutboxContent)
        XCTAssertEqual(message.outboxAttemptCount, 1)
        XCTAssertThrowsError(try message.prepareOutboxAttempt(payload: attempt.payload))
        XCTAssertEqual(message.outboxAttemptIdentifier, attempt.identifier)
        XCTAssertEqual(message.outboxAttemptCount, 1)
    }

    func testInvalidNonceCannotBeClaimedAndDoesNotMutateQueue() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let wrongPayload = try GenericMessage(content: Text(content: "wrong"), nonce: UUID()).serializedData()

        XCTAssertThrowsError(try message.prepareOutboxAttempt(payload: wrongPayload))

        XCTAssertEqual(message.outboxState, .queued)
        XCTAssertEqual(message.outboxAttemptCount, 0)
        XCTAssertNil(message.outboxAttemptIdentifier)
    }

    func testPreparationFailureAllowsEditingUntilFirstPossibleHandoff() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))

        try message.rescheduleOutboxAttempt(attempt.identifier)

        XCTAssertTrue(message.hasUnclaimedOutboxContent)
        XCTAssertNil(try message.loadOutboxPayload())
        XCTAssertThrowsError(try message.markOutboxAttemptSending(attempt))
    }

    func testRetriesKeepFrozenContentAndRespectBackoff() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let firstAttempt = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(firstAttempt)
        let retryDate = Date(timeIntervalSinceNow: 300)
        try message.rescheduleOutboxAttempt(firstAttempt.identifier, notBefore: retryDate)
        let changedPayload = try GenericMessage(content: Text(content: "changed"), nonce: message.nonce!)
            .serializedData()

        XCTAssertFalse(message.hasUnclaimedOutboxContent)
        XCTAssertThrowsError(try message.prepareOutboxAttempt(payload: changedPayload))
        let retry = try message.prepareOutboxAttempt(payload: changedPayload, at: retryDate)

        XCTAssertEqual(retry.payload, firstAttempt.payload)
        XCTAssertNotEqual(retry.identifier, firstAttempt.identifier)
        XCTAssertEqual(message.outboxAttemptCount, 2)
        XCTAssertThrowsError(try message.completeOutboxAttempt(firstAttempt.identifier))
    }

    func testRestartBeforeHandoffReturnsToQueueWithoutFreezingInitialContent() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))

        message.recoverOutboxAfterRestart()

        XCTAssertEqual(message.outboxState, .queued)
        XCTAssertTrue(message.hasUnclaimedOutboxContent)
        XCTAssertNil(message.outboxAttemptIdentifier)
        XCTAssertThrowsError(try message.markOutboxAttemptSending(attempt))
    }

    func testRestartAfterHandoffPreservesUncertainContentAndDoesNotRetry() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(attempt)

        message.recoverOutboxAfterRestart()
        message.recoverOutboxAfterRestart()

        XCTAssertEqual(message.outboxState, .uncertain)
        XCTAssertEqual(try message.loadOutboxPayload(), attempt.payload)
        XCTAssertFalse(message.hasUnclaimedOutboxContent)
        XCTAssertThrowsError(try message.prepareOutboxAttempt(payload: attempt.payload))
    }

    func testLateAcceptanceCanResolveUncertaintyAndReleasesSnapshot() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(attempt)
        try message.markOutboxAttemptUncertain(attempt.identifier)

        try message.completeOutboxAttempt(attempt.identifier)

        XCTAssertEqual(message.outboxState, .sent)
        XCTAssertNil(try message.loadOutboxPayload())
        XCTAssertNil(message.outboxAttemptIdentifier)
        XCTAssertEqual(message.outboxAttemptCount, 0)
    }

    func testPreviousOperationCannotCompleteLaterEdit() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let firstAttempt = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(firstAttempt)
        try message.completeOutboxAttempt(firstAttempt.identifier)
        message.delivered = true
        message.editText("edited", mentions: [], fetchLinkPreview: false)

        try message.enqueueInOutbox(operation: .edit)
        let edit = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(edit)

        XCTAssertThrowsError(try message.completeOutboxAttempt(firstAttempt.identifier))
        XCTAssertEqual(message.outboxState, .sending)
        XCTAssertEqual(message.outboxOperation, .edit)
        XCTAssertFalse(message.hasUnclaimedOutboxContent)
        XCTAssertNotNil(message.updatedTimestamp)
        XCTAssertTrue(message.underlyingMessage!.hasEdited)
    }

    func testCancellationAndDeletionRejectLateCallbacks() throws {
        for delete in [false, true] {
            let message = try makeMessage()
            try message.enqueueInOutbox(operation: .initialMessage)
            let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))
            try message.markOutboxAttemptSending(attempt)

            if delete {
                uiMOC.delete(message)
            } else {
                try message.cancelOutboxOperation()
                XCTAssertNil(try message.loadOutboxPayload())
            }

            XCTAssertThrowsError(try message.completeOutboxAttempt(attempt.identifier))
        }
    }

    func testUnknownStateAndOperationNeverBecomeEligible() throws {
        let message = try makeMessage()
        message.outboxStateRaw = 99
        XCTAssertNil(message.outboxState)
        XCTAssertFalse(message.hasUnclaimedOutboxContent)
        XCTAssertThrowsError(try message.enqueueInOutbox(operation: .initialMessage))
        message.recoverOutboxAfterRestart()
        XCTAssertEqual(message.outboxStateRaw, 99)

        message.outboxStateRaw = MessageOutboxState.queued.rawValue
        message.outboxOperationRaw = 99
        XCTAssertThrowsError(try message.prepareOutboxAttempt(payload: payload(of: message)))
    }

    func testOutboxPersistsAcrossContextsWithoutAddingUpstreamModificationKeys() throws {
        let message = try makeMessage()
        let originalKeys = message.keysThatHaveLocalModifications
        let nonce = message.nonce
        try message.enqueueInOutbox(operation: .initialMessage)
        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(attempt)
        try uiMOC.save()

        XCTAssertEqual(message.keysThatHaveLocalModifications, originalKeys)
        syncMOC.performGroupedAndWait {
            let restored = try! self.syncMOC.existingObject(with: message.objectID) as! ZMClientMessage
            XCTAssertEqual(restored.outboxState, .sending)
            XCTAssertEqual(restored.outboxOperation, .initialMessage)
            XCTAssertEqual(try! restored.loadOutboxPayload(), attempt.payload)
            XCTAssertEqual(restored.outboxAttemptIdentifier, attempt.identifier)
            XCTAssertEqual(restored.nonce, nonce)
            XCTAssertNotNil(restored.outboxEnqueuedAt)
        }
    }

    private func makeMessage() throws -> ZMClientMessage {
        try XCTUnwrap(conversation.appendText(content: "queued text") as? ZMClientMessage)
    }

    private func payload(of message: ZMClientMessage) throws -> Data {
        try XCTUnwrap(message.underlyingMessage).serializedData()
    }
}

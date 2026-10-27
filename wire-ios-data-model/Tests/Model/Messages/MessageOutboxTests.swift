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

    func testDeletionAfterHandoffKeepsAttemptUntilAcceptanceAndQueuesOneDurableControl() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let content = try payload(of: message)
        let attempt = try message.prepareOutboxAttempt(payload: content)
        try message.markOutboxAttemptSending(attempt)
        try uiMOC.save()

        try message.requestOutboxDeletion(.everyone)
        try message.requestOutboxDeletion(.everyone)
        try uiMOC.save()

        XCTAssertTrue(message.hasPendingOutboxDeletion)
        XCTAssertEqual(message.outboxState, .sending)
        XCTAssertEqual(message.outboxAttemptIdentifier, attempt.identifier)
        XCTAssertEqual(try message.loadOutboxPayload(), content)
        XCTAssertTrue(message.outboxDeletionMessages.isEmpty)
        XCTAssertFalse(message.hasBeenDeleted)

        message.markAsSent()
        try message.completeOutboxAttempt(attempt.identifier)
        try message.processPendingOutboxDeletion()
        try message.processPendingOutboxDeletion()
        try uiMOC.save()

        let marker = try XCTUnwrap(message.outboxDeletionMessages.first)
        XCTAssertEqual(message.outboxDeletionMessages.count, 1)
        XCTAssertEqual(marker.outboxOperation, .deletion)
        XCTAssertEqual(marker.outboxState, .queued)
        XCTAssertFalse(marker.hasBeenDeleted, "Hidden live control records are not erased target rows")
        XCTAssertEqual(marker.underlyingMessage?.deleted.messageID, message.nonce?.transportString())
        XCTAssertEqual(marker.outboxDeletionTarget, message)
        syncMOC.performGroupedAndWait {
            let restored = try! self.syncMOC.existingObject(with: message.objectID) as! ZMClientMessage
            XCTAssertTrue(restored.hasPendingOutboxDeletion)
            XCTAssertEqual(restored.outboxDeletionMessages.count, 1)
        }

        let deletion = try marker.prepareOutboxAttempt(payload: payload(of: marker))
        try marker.markOutboxAttemptSending(deletion)
        marker.markAsSent()
        try marker.completeOutboxAttempt(deletion.identifier)
        try message.processPendingOutboxDeletion()
        try uiMOC.save()

        XCTAssertFalse(message.hasPendingOutboxDeletion)
        XCTAssertTrue(message.hasBeenDeleted)
    }

    func testUncertainOriginalRetainsDeletionAcrossRecoveryAndCannotBeRetriedToDeleteIt() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let attempt = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(attempt)
        try message.requestOutboxDeletion(.everyone)
        try uiMOC.save()

        message.recoverOutboxAfterRestart()
        try message.processPendingOutboxDeletion()
        message.resend()
        try uiMOC.save()

        XCTAssertEqual(message.outboxState, .uncertain)
        XCTAssertTrue(message.hasPendingOutboxDeletion)
        XCTAssertFalse(message.canRetryPendingOutboxDeletion)
        XCTAssertTrue(message.outboxDeletionMessages.isEmpty)
        XCTAssertEqual(try message.loadOutboxPayload(), attempt.payload)
        XCTAssertThrowsError(try message.retryOutboxOperation())

        // A later accepted delivery/echo is evidence; changing reachability alone is not.
        message.markAsSent()
        try message.processPendingOutboxDeletion()
        XCTAssertEqual(message.outboxDeletionMessages.count, 1)
        XCTAssertEqual(message.outboxState, .sent)
    }

    func testPendingDeletionAbandonsAnEditBeforeHandoffAndDeletesTheAcceptedVersion() throws {
        let message = try makeMessage()
        message.markAsSent()
        let acceptedID = message.nonce
        message.editText("unsent edit", mentions: [], fetchLinkPreview: false)
        try message.enqueueInOutbox(operation: .edit)
        let edit = try message.prepareOutboxAttempt(payload: payload(of: message))

        try message.requestOutboxDeletion(.everyone)

        XCTAssertEqual(message.nonce, acceptedID)
        XCTAssertEqual(message.outboxState, .sent)
        XCTAssertThrowsError(try message.markOutboxAttemptSending(edit))
        XCTAssertEqual(message.outboxDeletionMessages.first?.underlyingMessage?.deleted.messageID,
                       acceptedID?.transportString())
    }

    func testDeletionControlCanRecoverAfterLostAcknowledgementWithoutRequeueingItsOriginal() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let original = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(original)
        message.markAsSent()
        try message.completeOutboxAttempt(original.identifier)
        try message.requestOutboxDeletion(.everyone)
        let marker = try XCTUnwrap(message.outboxDeletionMessages.first)
        let attempt = try marker.prepareOutboxAttempt(payload: payload(of: marker))
        try marker.markOutboxAttemptSending(attempt)
        try uiMOC.save()

        marker.recoverOutboxAfterRestart()

        XCTAssertEqual(marker.outboxState, .queued)
        XCTAssertEqual(try marker.loadOutboxPayload(), attempt.payload)
        XCTAssertEqual(message.outboxState, .sent)
        XCTAssertTrue(message.delivered)
        XCTAssertTrue(message.hasPendingOutboxDeletion)
        XCTAssertThrowsError(try message.enqueueInOutbox(operation: .contentUpdate))
    }

    func testRetryOfPendingDeletionRetriesOnlyAFailedControlMessage() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let original = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(original)
        message.markAsSent()
        try message.completeOutboxAttempt(original.identifier)
        try message.requestOutboxDeletion(.everyone)
        let marker = try XCTUnwrap(message.outboxDeletionMessages.first)
        try marker.failQueuedOutboxOperation()
        marker.expire(withReason: .other)
        let originalContent = try payload(of: message)

        XCTAssertTrue(message.canRetryPendingOutboxDeletion)
        message.resend()

        XCTAssertEqual(marker.outboxState, .queued)
        XCTAssertFalse(marker.isExpired)
        XCTAssertEqual(message.outboxState, .sent)
        XCTAssertEqual(try payload(of: message), originalContent)
        XCTAssertTrue(message.delivered)
    }

    func testLocalHideCanBeUpgradedToEveryoneWithoutClearingTheOriginalEarly() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let original = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(original)
        message.markAsSent()
        try message.completeOutboxAttempt(original.identifier)
        try message.requestOutboxDeletion(.local)
        XCTAssertTrue(message.outboxDeletionMessages.contains { $0.underlyingMessage?.hasHidden == true })

        try message.requestOutboxDeletion(.everyone)
        try message.requestOutboxDeletion(.local)
        XCTAssertEqual(message.outboxDeletionScopeRaw, MessageOutboxDeletionScope.everyone.rawValue)
        XCTAssertTrue(message.outboxDeletionMessages.contains { $0.underlyingMessage?.hasDeleted == true })
        XCTAssertFalse(message.hasBeenDeleted)

        for marker in message.outboxDeletionMessages {
            let attempt = try marker.prepareOutboxAttempt(payload: payload(of: marker))
            try marker.markOutboxAttemptSending(attempt)
            marker.markAsSent()
            try marker.completeOutboxAttempt(attempt.identifier)
        }
        try message.processPendingOutboxDeletion()
        try uiMOC.save()
        XCTAssertTrue(message.hasBeenDeleted)
        XCTAssertFalse(message.isDeleted, "An everyone delete leaves the existing deleted-message tombstone")
    }

    func testRepeatedQueuedEditsKeepIdentityQuoteAndMentionsWithoutAnEditedMarker() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let nonce = message.nonce
        let enqueuedAt = message.outboxEnqueuedAt
        var original = try XCTUnwrap(message.underlyingMessage)
        let quote = Quote.with {
            $0.quotedMessageID = UUID().transportString()
            $0.quotedMessageSha256 = Data(repeating: 1, count: 32)
        }
        original.text.quote = quote
        original.text.expectsReadConfirmation = true
        try message.setUnderlyingMessage(original)
        let mention = Mention(range: NSRange(location: 0, length: 4), user: user1)

        try message.editOutboxText("@Joe first draft", mentions: [mention], fetchLinkPreview: true)
        try message.editOutboxText("@Joe final draft", mentions: [mention], fetchLinkPreview: false)
        try uiMOC.save()

        let content = try XCTUnwrap(message.underlyingMessage)
        XCTAssertEqual(message.nonce, nonce)
        XCTAssertEqual(content.messageID, original.messageID)
        XCTAssertEqual(message.outboxEnqueuedAt, enqueuedAt)
        XCTAssertEqual(content.text.quote, quote)
        XCTAssertTrue(content.text.expectsReadConfirmation)
        XCTAssertEqual(message.mentions, [mention])
        XCTAssertEqual(message.messageText, "@Joe final draft")
        XCTAssertEqual(message.normalizedText, "@joe final draft")
        XCTAssertEqual(message.linkPreviewState, .done)
        XCTAssertFalse(content.hasEdited)
        XCTAssertNil(message.updatedTimestamp)
        XCTAssertTrue(message.hasUnclaimedOutboxContent)
        let claim = try message.prepareOutboxAttempt(payload: payload(of: message))
        XCTAssertEqual(try GenericMessage(serializedData: claim.payload).text.content, "@Joe final draft")
    }

    func testQueuedMultipartEditsAndPreviewsPreserveAttachmentsAndQuote() throws {
        let attachment = MultipartAttachment(
            uuid: UUID(), contentType: "application/pdf", initialName: "document.pdf",
            initialSize: 42, initialMetadata: nil
        ).toProto()
        var text = Text(content: "draft")
        text.quote = Quote.with {
            $0.quotedMessageID = UUID().transportString()
            $0.quotedMessageSha256 = Data(repeating: 2, count: 32)
        }
        let message = try conversation.appendClientMessage(
            with: GenericMessage(content: Multipart(text: text, attachments: [attachment]))
        )
        try message.enqueueInOutbox(operation: .initialMessage)
        let nonce = message.nonce
        let preview = GenericMessageProtocol.LinkPreview.with {
            $0.url = "https://wire.com"
            $0.urlOffset = 0
        }

        try message.editOutboxText("https://wire.com", mentions: [], fetchLinkPreview: true)
        try message.setOutboxLinkPreviews([preview])

        let content = try XCTUnwrap(message.underlyingMessage)
        XCTAssertEqual(content.multipart.attachments, [attachment])
        XCTAssertEqual(content.multipart.text.quote, text.quote)
        XCTAssertEqual(content.multipart.text.linkPreview, [preview])
        XCTAssertEqual(message.nonce, nonce)
        XCTAssertNil(message.updatedTimestamp)

        try message.editOutboxText("", mentions: [], fetchLinkPreview: false)
        XCTAssertEqual(message.underlyingMessage?.multipart.attachments, [attachment])
        XCTAssertEqual(message.underlyingMessage?.multipart.text.content, "")
        XCTAssertTrue(message.underlyingMessage!.multipart.text.linkPreview.isEmpty)
    }

    func testSendClaimRejectsQueuedEditWithoutChangingClaimedContent() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let nonce = message.nonce
        let claim = try message.prepareOutboxAttempt(payload: payload(of: message))

        XCTAssertFalse(message.canEditOutboxText)
        XCTAssertThrowsError(try message.editOutboxText("draft to retain in editor", mentions: [], fetchLinkPreview: false))
        XCTAssertEqual(try payload(of: message), claim.payload)
        XCTAssertEqual(message.nonce, nonce)
        XCTAssertNil(message.updatedTimestamp)

        try message.markOutboxAttemptSending(claim)
        try message.rescheduleOutboxAttempt(claim.identifier)
        XCTAssertFalse(message.canEditOutboxText)
        XCTAssertThrowsError(try message.editOutboxText("still frozen", mentions: [], fetchLinkPreview: false))
        XCTAssertEqual(try message.loadOutboxPayload(), claim.payload)
    }

    func testNormalEditRemainsUnavailableUntilPreviousOutboxOperationFinishes() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let claim = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(claim)
        try message.completeOutboxAttempt(claim.identifier)
        message.markAsSent()
        let originalNonce = message.nonce
        uiMOC.offlinePendingMessagesEnabled = true
        defer { uiMOC.offlinePendingMessagesEnabled = false }

        try message.editOutboxText("normal sent edit", mentions: [], fetchLinkPreview: true)

        XCTAssertEqual(message.outboxOperation, .edit)
        XCTAssertNotNil(message.updatedTimestamp)
        XCTAssertEqual(message.underlyingMessage?.edited.replacingMessageID, originalNonce?.transportString())
        XCTAssertFalse(message.canEditOutboxText)
        let editContent = try payload(of: message)
        message.editText("must not overwrite pending edit", mentions: [], fetchLinkPreview: false)
        XCTAssertEqual(try payload(of: message), editContent)

        let preview = GenericMessageProtocol.LinkPreview.with {
            $0.url = "https://wire.com"
            $0.urlOffset = 0
        }
        try message.setOutboxLinkPreviews([preview])
        XCTAssertTrue(message.underlyingMessage!.hasEdited)
        XCTAssertEqual(message.underlyingMessage?.edited.replacingMessageID, originalNonce?.transportString())
    }

    func testDeletingBeforeHandoffCreatesNoRemoteDeleteAndInvalidatesPreparation() throws {
        for preparing in [false, true] {
            let message = try makeMessage()
            try message.enqueueInOutbox(operation: .initialMessage)
            let claim = preparing ? try message.prepareOutboxAttempt(payload: payload(of: message)) : nil
            let hiddenCount = conversation.hiddenMessages.count

            XCTAssertNil(ZMMessage.deleteForEveryone(message))

            XCTAssertTrue(message.isDeleted)
            XCTAssertEqual(conversation.hiddenMessages.count, hiddenCount)
            if let claim { XCTAssertThrowsError(try message.markOutboxAttemptSending(claim)) }
        }
    }

    func testHidingAnUnsubmittedMessageDoesNotCreateRemoteHideTraffic() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        let selfConversation = ZMConversation.selfConversation(in: uiMOC)
        let hiddenCount = selfConversation.hiddenMessages.count

        message.hideForSelfUser()

        XCTAssertTrue(message.isDeleted)
        XCTAssertEqual(selfConversation.hiddenMessages.count, hiddenCount)
    }

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

    func testRetryDoesNotReviveCancelledText() throws {
        let message = try makeMessage()
        try message.enqueueInOutbox(operation: .initialMessage)
        try message.cancelOutboxOperation()
        message.expire(withReason: .cancelled)
        let originalContent = try payload(of: message)

        message.resend()

        XCTAssertEqual(message.outboxState, .cancelled)
        XCTAssertTrue(message.isExpired)
        XCTAssertEqual(try payload(of: message), originalContent)
    }

    func testRetryDoesNotReopenACompletedOutboxEdit() throws {
        let previous = uiMOC.offlinePendingMessagesEnabled
        uiMOC.offlinePendingMessagesEnabled = true
        defer { uiMOC.offlinePendingMessagesEnabled = previous }
        let message = try makeMessage()
        let initial = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(initial)
        try message.completeOutboxAttempt(initial.identifier)
        message.markAsSent()
        message.editText("sent edit", mentions: [], fetchLinkPreview: false)
        let edit = try message.prepareOutboxAttempt(payload: payload(of: message))
        try message.markOutboxAttemptSending(edit)
        try message.completeOutboxAttempt(edit.identifier)
        message.markAsSent()
        let nonce = message.nonce
        let content = try payload(of: message)

        message.resend()

        XCTAssertEqual(message.outboxState, .sent)
        XCTAssertTrue(message.delivered)
        XCTAssertEqual(message.nonce, nonce)
        XCTAssertEqual(try payload(of: message), content)
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

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

extension ZMConversation {
    static func appendHideMessageToSelfConversation(_ message: ZMMessage) throws {
        guard
            let messageId = message.nonce,
            let conversation = message.conversation,
            let conversationId = conversation.remoteIdentifier,
            let context = message.managedObjectContext
        else {
            return
        }

        let message = MessageHide(conversationId: conversationId, messageId: messageId)
        try ZMConversation.sendMessageToSelfClients(message, in: context)
    }
}

public extension ZMMessage {

    // NOTE: This is a free function meant to be called from Obj-C because you can't call protocol extension from it
    @objc
    static func hideMessage(_ message: ZMConversationMessage) {
        // when deleting ephemeral, we must delete for everyone (only self & sender will receive delete message)
        // b/c deleting locally will void the destruction timer completion.
        guard !message.isEphemeral else { deleteForEveryone(message); return }
        guard let castedMessage = message as? ZMMessage else { return }
        castedMessage.hideForSelfUser()
    }

    @objc
    func hideForSelfUser() {
        guard !isZombieObject else { return }
        if outboxState != .notEnrolled {
            do { try requestOutboxDeletion(.local) }
            catch {
                managedObjectContext?.rollback()
                Logging.messageProcessing.warn("Could not request outbox hide")
            }
            return
        }
        if discardUnsubmittedOutboxMessage() { return }

        do {
            try ZMConversation.appendHideMessageToSelfConversation(self)
        } catch {
            Logging.messageProcessing.warn("Failed to append hide message. Reason: \(error.localizedDescription)")
            return
        }

        // To avoid reinserting when receiving an edit we delete the message locally
        removeClearingSender(true)
        managedObjectContext?.delete(self)
    }

    @discardableResult @objc
    static func deleteForEveryone(_ message: ZMConversationMessage) -> ZMClientMessage? {
        guard let castedMessage = message as? ZMMessage else { return nil }
        return castedMessage.deleteForEveryone()
    }

    @discardableResult @objc
    internal func deleteForEveryone() -> ZMClientMessage? {
        guard !isZombieObject, let sender, sender.isSelfUser || isEphemeral else { return nil }
        if outboxState != .notEnrolled {
            do { try requestOutboxDeletion(.everyone) }
            catch {
                managedObjectContext?.rollback()
                Logging.messageProcessing.warn("Could not request outbox deletion")
            }
            return nil
        }
        if discardUnsubmittedOutboxMessage() { return nil }
        guard let conversation, let messageNonce = nonce else { return nil }

        do {
            let genericMessage = GenericMessage(content: MessageDelete(messageId: messageNonce))
            let message = try conversation.appendClientMessage(with: genericMessage, expires: false, hidden: true)
            removeClearingSender(false)
            updateCategoryCache()
            return message
        } catch {
            Logging.messageProcessing.warn("Failed delete message for everyone. Reason: \(error.localizedDescription)")
            return nil
        }
    }

    @objc internal var isEditableMessage: Bool {
        false
    }

    /// Serialize with send claims on the sync context. No remote hide/delete is needed before handoff.
    private func discardUnsubmittedOutboxMessage() -> Bool {
        guard canDiscardOutboxLocally else { return false }
        do {
            try cancelOutboxOperation()
        } catch {
            return false
        }
        let context = managedObjectContext
        removeClearingSender(true)
        context?.delete(self)
        return true
    }

    /// Run and save on the send owner's context. Keep the row, snapshot and attempt token intact
    /// after handoff: a local delete is not proof that the original HTTP request was stopped.
    func requestOutboxDeletion(_ scope: MessageOutboxDeletionScope) throws {
        guard scope != .none, let context = managedObjectContext, context.zm_isValidContext,
              context.canProcessOfflinePendingMessages, !isDeleted, !hasBeenDeleted,
              outboxState != .notEnrolled, outboxOperation != .deletion,
              MessageOutboxDeletionScope(rawValue: outboxDeletionScopeRaw) != nil,
              scope != .everyone || sender?.isSelfUser == true else {
            throw MessageOutboxError.invalidTransition
        }
        if discardUnsubmittedOutboxMessage() { return }
        // A repeated local hide must not downgrade an existing delete-for-everyone request.
        outboxDeletionScopeRaw = max(outboxDeletionScopeRaw, scope.rawValue)
        try processPendingOutboxDeletion()
    }

    /// Called after acceptance or during bootstrap/context tracking. Creating markers and saving
    /// them with the original's completed state makes the follow-up durable across termination.
    func processPendingOutboxDeletion() throws {
        guard hasPendingOutboxDeletion, !isDeleted, !hasBeenDeleted,
              let context = managedObjectContext, context.canProcessOfflinePendingMessages,
              let scope = MessageOutboxDeletionScope(rawValue: outboxDeletionScopeRaw), scope != .none,
              try prepareOutboxDeletionIfDeliveryKnown(), let nonce, let conversation else { return }

        switch scope {
        case .everyone:
            if !outboxDeletionMessages.contains(where: { $0.underlyingMessage?.hasDeleted == true }) {
                let content = GenericMessage(content: MessageDelete(messageId: nonce))
                let marker = try conversation.appendClientMessage(with: content, expires: false, hidden: true)
                try enrollDeletionMarker(marker)
            }
        case .local:
            if outboxDeletionMessages.isEmpty {
                guard let conversationID = conversation.remoteIdentifier else {
                    throw MessageOutboxError.invalidPayload
                }
                let content = MessageHide(conversationId: conversationID, messageId: nonce)
                let markers = try ZMConversation.sendMessageToSelfClients(content, in: context)
                try enrollDeletionMarker(markers.proteus)
                if let mls = markers.mls { try enrollDeletionMarker(mls) }
            }
        case .none:
            return
        }
        guard !outboxDeletionMessages.isEmpty,
              outboxDeletionMessages.allSatisfy({ $0.outboxState == .sent }) else { return }

        // Erase content only after all required markers were accepted. Until then the UI keeps a
        // visible deletion-pending row, including when a permanent failure requires explicit Retry.
        outboxDeletionScopeRaw = MessageOutboxDeletionScope.none.rawValue
        switch scope {
        case .everyone:
            removeClearingSender(false)
            updateCategoryCache()
        case .local:
            removeClearingSender(true)
            context.delete(self)
        case .none:
            break
        }
    }

    /// Retry the follow-up markers only; an uncertain original must never be resent just to delete it.
    func retryPendingOutboxDeletion() throws {
        guard hasPendingOutboxDeletion else { throw MessageOutboxError.invalidTransition }
        for marker in outboxDeletionMessages where marker.outboxState == .failed {
            marker.resend()
            guard marker.outboxState == .queued else { throw MessageOutboxError.invalidTransition }
        }
    }

    private func enrollDeletionMarker(_ marker: ZMClientMessage) throws {
        do {
            marker.outboxDeletionTarget = self
            try marker.enqueueInOutbox(operation: .deletion)
        } catch {
            marker.managedObjectContext?.delete(marker)
            throw error
        }
    }
}

extension ZMClientMessage {
    @NSManaged public internal(set) var outboxDeletionTarget: ZMMessage?

    override var isEditableMessage: Bool {
        guard !hasPendingOutboxDeletion else { return false }
        guard
            let genericMessage = underlyingMessage,
            let sender, sender.isSelfUser,
            let content = genericMessage.content else {
            return false
        }
        if outboxState != .notEnrolled, outboxState != .sent {
            guard hasUnclaimedOutboxContent, !isEphemeral else { return false }
            switch content {
            case .text, .multipart: return true
            default: return false
            }
        }
        switch content {
        case .edited:
            return true
        case .text:
            return !isEphemeral && isSent
        case .multipart:
            return isSent
        default:
            return false
        }
    }
}

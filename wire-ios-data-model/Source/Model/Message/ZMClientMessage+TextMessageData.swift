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

extension ZMClientMessage: TextMessageData {

    @NSManaged public var quote: ZMMessage?

    public var quoteMessage: ZMConversationMessage? {
        quote
    }

    public override var textMessageData: TextMessageData? {
        guard underlyingMessage?.textData != nil else {
            return nil
        }
        return self
    }

    public var isQuotingSelf: Bool {
        quote?.sender?.isSelfUser ?? false
    }

    public var hasQuote: Bool {
        underlyingMessage?.textData?.hasQuote ?? false
    }

    public var quotedMessageIsDeleted: Bool {
        // The `quote` relationship is cleared when the quoted message is deleted (its `replies`
        // set is emptied), so a deleted quote and a quote we never received both leave `quote ==
        // nil`. Resolve the quoted nonce to distinguish them: a deleted message survives as a
        // hidden tombstone (`hasBeenDeleted`), whereas an unseen message has no local object.
        guard quote == nil,
              hasQuote,
              let managedObjectContext,
              let conversation,
              let quotedMessageID = underlyingMessage?.textData?.quote.quotedMessageID,
              let nonce = UUID(uuidString: quotedMessageID),
              let quotedMessage = ZMOTRMessage.fetch(
                  withNonce: nonce,
                  for: conversation,
                  in: managedObjectContext
              )
        else {
            return false
        }
        return quotedMessage.hasBeenDeleted
    }

    public var messageText: String? {
        underlyingMessage?.textData?.content.removingExtremeCombiningCharacters
    }

    public var mentions: [Mention] {
        Mention.mentions(
            from: underlyingMessage?.textData?.mentions,
            messageText: messageText,
            moc: managedObjectContext
        )
    }

    public func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        guard let nonce, isEditableMessage else { return }

        // Quotes are ignored in edits but keep it to mark that the message has quote for us locally
        let editedText = Text(content: text, mentions: mentions, linkPreviews: [], replyingTo: quote as? ZMOTRMessage)
        let editNonce = UUID()
        let content = if let multipartAttachments {
            MessageEdit(
                replacingMessageID: nonce,
                multipart: .init(text: editedText, attachments: multipartAttachments)
            )
        } else {
            MessageEdit(
                replacingMessageID: nonce,
                text: editedText
            )
        }

        let updatedMessage = GenericMessage(content: content, nonce: editNonce)

        do {
            try setUnderlyingMessage(updatedMessage)
        } catch {
            Logging.messageProcessing.warn("Failed to edit text message. Reason: \(error.localizedDescription)")
            return
        }

        updateNormalizedText()

        self.nonce = editNonce
        updatedTimestamp = Date()
        reactions.removeAll()
        linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
        linkAttachments = nil
        delivered = false
        sendAttemptStarted = false
    }

    // MARK: - Pending messages

    /// Whether the text can be replaced without sending an edit, because the message is pending and
    /// hasn't been sent yet. Recipients then only ever see the new text, without an edited marker.
    public var isEditableInPlace: Bool {
        guard
            DeveloperFlag.offlinePendingMessages.isOn,
            !isEphemeral,
            !isExpired,
            !delivered,
            !sendAttemptStarted,
            let sender, sender.isSelfUser
        else {
            return false
        }

        switch underlyingMessage?.content {
        case .text:
            return true
        case let .edited(messageEdit):
            if case .text = messageEdit.content {
                return true
            }
            return false
        default:
            return false
        }
    }

    /// Creates the text for `replacePendingText(with:fetchLinkPreview:)`. Call it on the context of the
    /// mentioned users.
    public func makePendingText(_ text: String, mentions: [Mention]) -> Text {
        Text(content: text, mentions: mentions, linkPreviews: [], replyingTo: quote as? ZMOTRMessage)
    }

    /// Replaces the text of a pending message that hasn't been sent yet, keeping its nonce.
    ///
    /// Call it on the sync context, which also marks the message before sending it, so the text can't
    /// change while a send reads it.
    ///
    /// - Returns: `false` if the message is no longer editable in place, e.g. because sending started.
    @discardableResult
    public func replacePendingText(with text: Text, fetchLinkPreview: Bool) -> Bool {
        guard isEditableInPlace, let nonce, let content = underlyingMessage?.content else { return false }

        let updatedMessage: GenericMessage
        switch content {
        case let .edited(messageEdit):
            guard let originalNonce = UUID(uuidString: messageEdit.replacingMessageID) else { return false }
            updatedMessage = GenericMessage(
                content: MessageEdit(replacingMessageID: originalNonce, text: text),
                nonce: nonce
            )
        default:
            updatedMessage = GenericMessage(content: text, nonce: nonce)
        }

        do {
            try setUnderlyingMessage(updatedMessage)
        } catch {
            Logging.messageProcessing.warn("Failed to replace pending text. Reason: \(error.localizedDescription)")
            return false
        }

        updateNormalizedText()
        linkPreviewState = fetchLinkPreview ? .waitingToBeProcessed : .done
        linkAttachments = nil
        return true
    }

    /// Whether the message can be deleted without sending a delete, because it's a new pending message
    /// that hasn't been sent yet, so nobody else has it.
    public var isDeletableWhilePending: Bool {
        guard isEditableInPlace, case .text = underlyingMessage?.content else { return false }
        return true
    }

    /// Deletes a pending message that hasn't been sent yet, without sending a delete.
    ///
    /// Call it on the sync context, which also marks the message before sending it, so it can't be
    /// deleted while a send reads it.
    ///
    /// - Returns: `false` if the message can no longer be deleted this way, e.g. because sending started.
    @discardableResult
    public func deletePendingMessage() -> Bool {
        guard isDeletableWhilePending, let managedObjectContext else { return false }

        removeClearingSender(true)
        managedObjectContext.delete(self)
        return true
    }

    var multipartAttachments: [GenericMessageProtocol.Attachment]? {
        switch underlyingMessage?.content {
        case let .multipart(multipart):
            multipart.attachments
        case let .edited(messageEdit):
            switch messageEdit.content {
            case let .multipart(data):
                data.attachments
            default:
                nil
            }
        default:
            nil
        }
    }
}

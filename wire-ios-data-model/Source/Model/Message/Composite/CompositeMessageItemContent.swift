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

final class CompositeMessageItemContent: NSObject {
    private let parentMessage: ZMClientMessage
    private let item: Composite.Item

    private var text: Text? {
        guard case .some(.text) = item.content else { return nil }
        return item.text
    }

    private var button: Button? {
        guard case .some(.button) = item.content else { return nil }
        return item.button
    }

    init(with item: Composite.Item, message: ZMClientMessage) {
        self.item = item
        self.parentMessage = message
    }
}

// MARK: - TextMessageData

extension CompositeMessageItemContent: TextMessageData {

    var messageText: String? {
        text?.content.removingExtremeCombiningCharacters
    }

    var linkPreview: LinkMetadata? {
        nil
    }

    var mentions: [Mention] {
        Mention.mentions(from: text?.mentions, messageText: messageText, moc: parentMessage.managedObjectContext)
    }

    var quote: ZMMessage? {
        nil
    }

    var quoteMessage: ZMConversationMessage? {
        quote
    }

    var linkPreviewHasImage: Bool {
        false
    }

    var linkPreviewImageCacheKey: String? {
        nil
    }

    var isQuotingSelf: Bool {
        false
    }

    var hasQuote: Bool {
        false
    }

    func fetchLinkPreviewImageData(
        queue: DispatchQueue,
        completionHandler: @escaping (_ imageData: Data?) -> Void
    ) {
        // no op
    }

    func requestLinkPreviewImageDownload() {
        // no op
    }

    func editText(_ text: String, mentions: [Mention], fetchLinkPreview: Bool) {
        // no op
    }

    var multipartMessageData: MultipartMessageData? {
        nil
    }
}

// MARK: - ButtonMessageData

extension CompositeMessageItemContent: ButtonMessageData {

    var title: String? {
        button?.text
    }

    var state: ButtonMessageState {
        buttonState?.state ?? .unselected
    }

    var isExpired: Bool {
        buttonState?.isExpired ?? false
    }

    func touchAction() {
        guard let context = parentMessage.managedObjectContext else { return }

        context.performGroupedBlock { [weak self] in
            guard let self, let messageID = parentMessage.nonce, let buttonID = button?.id,
                  !hasSelectedButton else { return }

            let buttonState = buttonState ??
                ButtonState.insert(with: buttonID, message: parentMessage, inContext: context)
            parentMessage.buttonStates?.resetExpired()
            guard parentMessage.isSenderInConversation else {
                buttonState.isExpired = true
                context.saveOrRollback()
                return
            }

            do {
                try parentMessage.conversation?.appendButtonAction(havingId: buttonID, referenceMessageId: messageID)
                parentMessage.buttonStates?.confirmButtonState(buttonID: buttonID)
            } catch {
                Logging.messageProcessing.warn("Failed to append button action. Reason: \(error.localizedDescription)")
            }

            context.saveOrRollback()
        }
    }
}

// MARK: - Helpers

extension CompositeMessageItemContent {

    /// Returns `true` if there is a button which has been selected but hasn't been confirmed, `false` otherwise.

    private var hasSelectedButton: Bool {
        parentMessage.buttonStates?.contains(where: { $0.state == .selected }) ?? false
    }

    private var buttonState: ButtonState? {
        guard let button else { return nil }

        return parentMessage.buttonStates?.first(where: { buttonState in
            guard let remoteIdentifier = buttonState.remoteIdentifier else { return false }
            return remoteIdentifier == button.id
        })
    }
}

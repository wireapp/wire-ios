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

import UIKit
import WireCommonComponents
import WireLogging
import WireSyncEngine

extension ConversationInputBarViewController {
    func sendText() {

        let checker = PrivacyWarningChecker(conversation: conversation) {
            Task { await self._sendText() }
        }

        checker.performAction()
    }

    @MainActor
    private func _sendText() async {
        let (text, mentions) = inputBar.textView.preparedText
        let quote = quotedMessage

        guard !showAlertIfTextIsTooLong(text: text) else { return }

        if inputBar.isEditing, let message = editingMessage {
            guard message.textMessageData?.messageText != text else { return }

            delegate?.conversationInputBarViewControllerDidFinishEditing(message, withText: text, mentions: mentions)
            editingMessage = nil
            updateWritingState(animated: true)
        } else {
            if !attachments.isEmpty {
                do {
                    try await publishDraftsUseCase.invoke()
                    await clearPublishedDraftsUseCase.invoke()
                } catch {
                    WireLogger.conversation.error("Failed to publish drafts: \(error)")
                    return
                }
            }

            clearInputBar()
            delegate?.conversationInputBarViewControllerDidComposeText(
                text: text,
                attachments: attachments.map { draft in
                    MultipartAttachment(
                        uuid: draft.nodeID,
                        contentType: draft.mimeType,
                        initialName: draft.name,
                        initialSize: draft.bytes,
                        initialMetadata: draft.metadata.map { metadata in
                            switch metadata {
                            case let .image(width, height):
                                .image(width: width, height: height)
                            case let .video(width, height, duration):
                                .video(width: width, height: height, duration: duration)
                            case let .audio(duration):
                                // Currently normalized loudness is not supported
                                .audio(duration: duration, normalizedLoudness: nil)
                            }
                        }
                    )
                },
                mentions: mentions,
                replyingTo: quote
            )
        }

        dismissMentionsIfNeeded()
    }

    func showAlertIfTextIsTooLong(text: String) -> Bool {
        let maximumMessageLength = 8000

        guard text.count > maximumMessageLength else { return false }

        let alert = UIAlertController(
            title: L10n.Localizable.Conversation.InputBar.MessageTooLong.title,
            message: L10n.Localizable.Conversation.InputBar.MessageTooLong.message(maximumMessageLength),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: L10n.Localizable.General.ok,
            style: .cancel
        ))

        present(alert, animated: true)

        return true
    }

}

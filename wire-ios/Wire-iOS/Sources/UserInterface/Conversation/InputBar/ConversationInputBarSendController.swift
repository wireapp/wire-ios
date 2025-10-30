//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireDataModel
import WireSyncEngine

final class ConversationInputBarSendController: NSObject {
    let conversation: InputBarConversationType
    private let feedbackGenerator: UIImpactFeedbackGenerator = .init(style: .light)

    init(conversation: InputBarConversationType) {
        self.conversation = conversation
        super.init()
    }

    func sendMessage(
        image: SendableImage,
        userSession: UserSession,
        completion completionHandler: Completion? = nil
    ) {

        guard let conversation = conversation as? ZMConversation else { return }

        feedbackGenerator.prepare()
        userSession.enqueue {
            do {
                let useCase = userSession.makeAppendImageMessageUseCase()
                try useCase.invoke(
                    image: image,
                    in: conversation
                )
                self.feedbackGenerator.impactOccurred()
            } catch {
                Logging.messageProcessing.warn("Failed to append image message. Reason: \(error.localizedDescription)")
            }
        } completionHandler: {
            completionHandler?()
        }
    }

    func sendTextMessage(
        _ text: String,
        attachments: [MultipartAttachment],
        mentions: [Mention],
        userSession: UserSession,
        replyingTo message: ZMConversationMessage?,
    ) {
        guard let conversation = conversation as? ZMConversation else { return }

        userSession.enqueue {
            let shouldFetchLinkPreview = !Settings.disableLinkPreviews

            do {
                if attachments.isEmpty {
                    let useCase = userSession.makeAppendTextMessageUseCase()
                    try useCase.invoke(
                        text: text,
                        mentions: mentions,
                        replyingTo: message,
                        in: conversation,
                        fetchLinkPreview: shouldFetchLinkPreview
                    )

                } else {
                    let useCase = userSession.makeAppendMultipartMessageUseCase()
                    try useCase.invoke(
                        text: text,
                        mentions: mentions,
                        replyingTo: message,
                        in: conversation,
                        fetchLinkPreview: shouldFetchLinkPreview,
                        attachments: attachments
                    )
                }
            } catch {
                Logging.messageProcessing.warn("Failed to append text message. Reason: \(error.localizedDescription)")
            }
        }
    }

    func sendTextMessage(
        _ text: String,
        mentions: [Mention],
        userSession: UserSession,
        withGIFImageData data: Data
    ) {
        guard let conversation = conversation as? ZMConversation else { return }

        let shouldFetchLinkPreview = !Settings.disableLinkPreviews

        userSession.enqueue {
            do {
                let textMessageUseCase = userSession.makeAppendTextMessageUseCase()
                let imageMessageUseCase = userSession.makeAppendImageMessageUseCase()
                try textMessageUseCase.invoke(
                    text: text,
                    mentions: mentions,
                    replyingTo: nil,
                    in: conversation,
                    fetchLinkPreview: shouldFetchLinkPreview
                )
                let image = SendableImage(
                    name: nil,
                    utType: nil,
                    data: data
                )
                try imageMessageUseCase.invoke(
                    image: image,
                    in: conversation
                )
            } catch {
                Logging.messageProcessing
                    .warn("Failed to append text message with image data. Reason: \(error.localizedDescription)")
            }
        }
    }
}

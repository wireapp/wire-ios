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

import SwiftUI
import UIKit
import WireDataModel
import WireDesign
import WireMessagingDomain
import WireMessagingUI

final class ConversationMultipartMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationMultipartMessageCell

    let configuration: View.Configuration

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = true

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String? = nil
    var supportsActions: Bool = true

    private let model: MultipartAttachmentsModel

    @MainActor var conversationCellModel: ConversationCellModel? {
        .multipartAttachments(model)
    }

    init(
        multipartMessage: MultipartMessageData,
        isSentBySelfUser: Bool
    ) {
        self.configuration = View.Configuration(
            attachments: multipartMessage.attachments,
            alignment: isSentBySelfUser ? .trailing : .leading
        )

        let attachments = multipartMessage.attachments.map {
            WireDriveMessageAttachment(
                nodeID: $0.nodeID,
                contentType: $0.contentType,
                initialName: $0.initialName,
                initialSize: $0.initialSize,
                initialMetadata: $0.initialMetadata.map { metadata in
                    switch metadata {
                    case let .image(width: width, height: height):
                        .image(width: width, height: height)
                    case let .video(width: width, height: height, duration: duration):
                        .video(width: width, height: height, duration: duration)
                    case let .audio(duration: duration, normalizedLoudness: normalizedLoudness):
                        .audio(duration: duration, normalizedLoudness: normalizedLoudness)
                    }
                }
            )
        }

        self.model = MultipartAttachmentsModel(
            attachments: attachments,
            isSentBySelfUser: isSentBySelfUser,
        )

    }
}

// This cell is not used. It exists only to fulfill protocol requirements of
// `ConversationMultipartMessageCellDescription`. Instead, for multipart cells, we use SwiftUI views.
final class ConversationMultipartMessageCell: UIView, ConversationMessageCell {

    struct Configuration {
        var attachments: [MultipartMessageData.Attachment]
        let alignment: HorizontalAlignment
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var message: ZMConversationMessage?
    weak var actionController: ConversationMessageActionController?

    var isSelected: Bool = false

    func configure(with object: Configuration, animated: Bool) {
        assertionFailure("This cell should not be used.")
    }

}

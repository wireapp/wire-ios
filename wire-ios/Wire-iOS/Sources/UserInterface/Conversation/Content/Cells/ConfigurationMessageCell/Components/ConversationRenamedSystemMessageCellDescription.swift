//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireDesign

final class ConversationRenamedSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationRenamedSystemMessageCell
    typealias LabelColors = SemanticColors.Label

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 0

    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(
        message: ZMConversationMessage,
        data: ZMSystemMessageData,
        sender: UserType,
        newName: String
    ) {
        let senderText = message.senderName
        let titleString = "content.system.renamed_conv.title".localized(pov: sender.pov, args: senderText)

        let title = NSAttributedString(
            string: titleString,
            attributes: [.font: UIFont.mediumFont, .foregroundColor: LabelColors.textDefault]
        )

        let conversationName = NSAttributedString(
            string: newName,
            attributes: [.font: UIFont.normalSemiboldFont, .foregroundColor: LabelColors.textDefault]
        )
        self.configuration = View.Configuration(attributedText: title, newConversationName: conversationName)
        self.actionController = nil
        self.accessibilityLabel = "\(titleString), \(newName)"
    }
}

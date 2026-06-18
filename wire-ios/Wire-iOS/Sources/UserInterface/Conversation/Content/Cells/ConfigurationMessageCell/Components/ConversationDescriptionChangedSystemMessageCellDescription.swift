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
import WireDataModel
import WireDesign

final class ConversationDescriptionChangedSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationDescriptionChangedSystemMessageCell
    typealias LabelColors = SemanticColors.Label

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(
        message: ZMConversationMessage,
        data: ZMSystemMessageData,
        sender: UserType,
        newDescription: String?
    ) {
        let senderText = message.senderName
        let titleString: String

        if newDescription != nil {
            titleString = "content.system.changed_description.title".localized(pov: sender.pov, args: senderText)
        } else {
            titleString = sender.isSelfUser
                ? "content.system.you_changed_description_to_nothing".localized
                : "content.system.other_changed_description_to_nothing".localized(args: senderText)
        }

        let title = NSAttributedString(
            string: titleString,
            attributes: [.font: UIFont.mediumFont, .foregroundColor: LabelColors.textDefault]
        )

        let descriptionAttributedString = newDescription.map {
            NSAttributedString(
                string: $0,
                attributes: [.font: UIFont.mediumFont, .foregroundColor: LabelColors.textDefault]
            )
        }

        self.configuration = View.Configuration(
            attributedText: title,
            newDescription: descriptionAttributedString
        )
        self.actionController = nil
        self.accessibilityLabel = [titleString, newDescription].compactMap { $0 }.joined(separator: ", ")
    }

}

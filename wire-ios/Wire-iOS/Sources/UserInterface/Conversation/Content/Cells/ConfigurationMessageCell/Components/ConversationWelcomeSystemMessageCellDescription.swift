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
import WireDataModel
import WireDesign

final class ConversationWelcomeSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell<ConversationFileCollaborationSystemMessageCellDescription>
    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false
    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    typealias Variant = (wireCells: Bool, isChannel: Bool)

    init(variant: Variant) {
        let title = variant.wireCells ? L10n.Localizable.Conversation.ConnectionView.Welcome.Title.wireCells : L10n
            .Localizable.Conversation.ConnectionView.Welcome.Title.wire

        let message: String = switch variant {
        case (wireCells: false, isChannel: false):
            L10n.Localizable.Conversation.ConnectionView.Welcome.Message.wireGroup
        case (wireCells: false, isChannel: true):
            L10n.Localizable.Conversation.ConnectionView.Welcome.Message.wireChannel
        case (wireCells: true, isChannel: _):
            L10n.Localizable.Conversation.ConnectionView.Welcome.Message.wireCells
        }

        let linkLabel = L10n.Localizable.Conversation.ConnectionView.Welcome.learnMore
        let linkUrl = URL(string: "https://support.wire.com/hc/articles/10898523878173")!

        let titleAttributes: [NSAttributedString.Key: AnyObject] = [
            .font: FontSpec(.header, .semibold).font!,
            .foregroundColor: LabelColors.textSecurityEnabled
        ]

        let messageAttributes: [NSAttributedString.Key: AnyObject] = [
            .font: UIFont.mediumFont,
            .foregroundColor: LabelColors.textDefault
        ]

        let linkAttributes: [NSAttributedString.Key: AnyObject] = [
            .font: UIFont.mediumSemiboldFont,
            .foregroundColor: LabelColors.textDefault,
            .link: linkUrl as AnyObject,
            .underlineStyle: NSUnderlineStyle.single.rawValue as AnyObject,
            .underlineColor: LabelColors.textDefault
        ]

        let icon = UIImage(systemName: "shield.righthalf.filled")?
            .withRenderingMode(.alwaysOriginal)
            .withTintColor(LabelColors.textSecurityEnabled)

        let attributedText: NSMutableAttributedString = .init()

        // Faking spacing with line breaks to avoid having to add extra views and having to expose code to be able to
        // modify margin/padding constraints.
        let spaceBetweenParagraphs = "\n\n"
        let bottomMargin = "\n"

        attributedText.append(.init(string: title + spaceBetweenParagraphs, attributes: titleAttributes))
        attributedText.append(.init(string: message + spaceBetweenParagraphs, attributes: messageAttributes))
        attributedText.append(.init(string: linkLabel + bottomMargin, attributes: linkAttributes))

        self.configuration = View.Configuration(
            icon: icon,
            attributedText: attributedText,
            showLine: false,
            resetLinkStyleForOverride: true,
            backgroundColor: SemanticColors.View.backgroundGreen
        )
        self.accessibilityLabel = attributedText.string
        self.actionController = nil
    }

}

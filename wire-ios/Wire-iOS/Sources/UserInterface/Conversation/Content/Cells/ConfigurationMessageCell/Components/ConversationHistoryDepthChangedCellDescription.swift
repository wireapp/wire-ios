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

import Foundation
import WireCommonComponents
import WireDataModel
import WireDesign

struct HistoryDepthViewModel {
    let iconColor: UIColor
    let text: String?
    let sender: UserType

    private let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.mediumFont,
        .foregroundColor: SemanticColors.Label.textDefault
    ]

    func image() -> UIImage? {
        UIImage(
            systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90"
        )?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
    }

    func createSystemMessage(template: String) -> NSAttributedString {
        var updateText: NSAttributedString

        if sender.isSelfUser {
            let youLocalized = L10n.Localizable.Content.System.youStarted

            if let text {
                updateText = NSAttributedString(
                    string: template.localized(pov: sender.pov, args: youLocalized, text),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: youLocalized)
                .adding(font: .mediumSemiboldFont, to: text)
            } else {
                updateText = NSAttributedString(
                    string: template.localized(pov: sender.pov, args: youLocalized),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: youLocalized)
            }
        } else {
            if let text {
                let otherUserName = sender.name ?? L10n.Localizable.Conversation.Status.someone
                updateText = NSAttributedString(
                    string: template.localized(args: otherUserName, text),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: otherUserName)
                .adding(font: .mediumSemiboldFont, to: text)
            } else {
                let otherUserName = sender.name ?? L10n.Localizable.Conversation.Status.someone
                updateText = NSAttributedString(
                    string: template.localized(args: otherUserName),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: otherUserName)
            }
        }

        return updateText
    }

    func attributedTitle() -> NSAttributedString? {
        createSystemMessage(
            template: text != nil ? "content.system.message_history_depth" :
                "content.system.message_history_depth_disabled"
        )
    }

}

final class ConversationHistoryDepthChangedCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationSystemMessageCell<ConversationReadReceiptSettingChangedCellDescription>

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(
        sender: UserType,
        text: String?
    ) {
        let viewModel = HistoryDepthViewModel(
            iconColor: SemanticColors.Icon.backgroundDefault,
            text: text,
            sender: sender
        )

        self.configuration = View.Configuration(
            icon: viewModel.image(),
            attributedText: viewModel.attributedTitle(),
            showLine: false
        )
        self.accessibilityLabel = viewModel.attributedTitle()?.string
        self.actionController = nil
    }
}

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
    let isNewConversation: Bool
    let iconColor: UIColor
    let historyDepth: String?
    let sender: UserType

    private let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.mediumFont,
        .foregroundColor: SemanticColors.Label.textDefault
    ]

    func image() -> UIImage? {
        UIImage(
            systemName: isNewConversation ? "arrow.trianglehead.counterclockwise.rotate.90" : "clock.arrow.trianglehead.counterclockwise.rotate.90"
        )?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
    }

    func createSystemMessage(template: String) -> NSAttributedString {
        if isNewConversation {
            return historyDepthInitiallySetAttributedText(
                template: template
            )
        } else {
            return historyDepthModifiedAttributedText(
                template: template
            )
        }
    }
    
    private func historyDepthInitiallySetAttributedText(
        template: String
    ) -> NSAttributedString {
        guard let historyDepth else {
            fatalError(
                "Should not reach this point if this is a new conversation and history depth is null"
            )
        }
        
        var updateText: NSAttributedString
        // TODO: [WPB-18396] map historyDepth to string value
        let text = "13 days"
        updateText = NSAttributedString(
            string: template.localized(args: text),
            attributes: baseAttributes
        )
        .adding(font: .mediumSemiboldFont, to: text)
        
        return updateText
    }
    
    private func historyDepthModifiedAttributedText(
        template: String
    ) -> NSAttributedString {
        var updateText: NSAttributedString
        
        if sender.isSelfUser {
            let youLocalized = L10n.Localizable.Content.System.youStarted

            if let historyDepth {
                updateText = NSAttributedString(
                    string: template.localized(pov: sender.pov, args: youLocalized, historyDepth),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: youLocalized)
                .adding(font: .mediumSemiboldFont, to: historyDepth)
            } else {
                updateText = NSAttributedString(
                    string: template.localized(pov: sender.pov, args: youLocalized),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: youLocalized)
            }
        } else {
            if let historyDepth {
                let otherUserName = sender.name ?? L10n.Localizable.Conversation.Status.someone
                updateText = NSAttributedString(
                    string: template.localized(args: otherUserName, historyDepth),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: otherUserName)
                .adding(font: .mediumSemiboldFont, to: historyDepth)
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
        if isNewConversation {
            return createSystemMessage(
                template: "content.system.message_history_depth_initially_set"
            )
        } else {
            return createSystemMessage(
                template: historyDepth != nil ? "content.system.message_history_depth_modified" :
                    "content.system.message_history_depth_modified_disabled"
            )
        }
    }

}

final class ConversationChannelHistoryDepthSystemMessageCellDescription: ConversationMessageCellDescription {
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
        historyDepth: String?,
        isNewConversation: Bool
    ) {
        let viewModel = HistoryDepthViewModel(
            isNewConversation: isNewConversation,
            iconColor: SemanticColors.Icon.backgroundDefault,
            historyDepth: historyDepth,
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

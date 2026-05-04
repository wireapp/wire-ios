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
            systemName: isNewConversation ? "arrow.trianglehead.counterclockwise.rotate.90" :
                "clock.arrow.trianglehead.counterclockwise.rotate.90"
        )?.withTintColor(iconColor, renderingMode: .alwaysOriginal)
    }

    private func parseHistoryDepth(historyDepth: String) -> (value: String, unit: String) {
        let components = historyDepth.components(separatedBy: .whitespaces)
        guard components.count == 2 else {
            fatalError("Couldn't parse history depth values")
        }

        return (components[0], components[1].lowercased())
    }

    private func historyDepthInitiallySetAttributedText() -> NSAttributedString {
        guard let historyDepth else {
            fatalError(
                "Should not reach this point if this is a new conversation and history depth is null"
            )
        }

        let historyDepthParsingResult = parseHistoryDepth(historyDepth: historyDepth)
        let historyDepthValue = historyDepthParsingResult.value
        let historyDepthUnit = historyDepthParsingResult.unit
        let template = "content.system.message_history_depth_initially_set_\(historyDepthUnit)"
        var updateText: NSAttributedString

        updateText = NSAttributedString(
            string: template.localized(args: historyDepthValue),
            attributes: baseAttributes
        )
        .adding(font: .mediumSemiboldFont, to: historyDepthValue)
        .adding(font: .mediumSemiboldFont, to: historyDepthUnit)

        return updateText
    }

    private func historyDepthModifiedAttributedText() -> NSAttributedString {
        var updateText: NSAttributedString

        if sender.isSelfUser {
            let youLocalized = L10n.Localizable.Content.System.youStarted

            if let historyDepth {
                let historyDepthParsingResult = parseHistoryDepth(historyDepth: historyDepth)
                let historyDepthValue = historyDepthParsingResult.value
                let historyDepthUnit = historyDepthParsingResult.unit
                let template = "content.system.message_history_depth_modified_\(historyDepthUnit)"

                updateText = NSAttributedString(
                    string: template.localized(pov: sender.pov, args: youLocalized, historyDepthValue),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: youLocalized)
                .adding(font: .mediumSemiboldFont, to: historyDepthValue)
                .adding(font: .mediumSemiboldFont, to: historyDepthUnit)
            } else {
                let template = "content.system.message_history_depth_modified_disabled"
                updateText = NSAttributedString(
                    string: template.localized(pov: sender.pov, args: youLocalized),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: youLocalized)
            }
        } else {
            if let historyDepth {
                let historyDepthParsingResult = parseHistoryDepth(historyDepth: historyDepth)
                let historyDepthValue = historyDepthParsingResult.value
                let historyDepthUnit = historyDepthParsingResult.unit
                let template = "content.system.message_history_depth_modified_\(historyDepthUnit)"

                let otherUserName = sender.name ?? L10n.Localizable.Conversation.Status.someone
                updateText = NSAttributedString(
                    string: template.localized(args: otherUserName, historyDepthValue),
                    attributes: baseAttributes
                )
                .adding(font: .mediumSemiboldFont, to: otherUserName)
                .adding(font: .mediumSemiboldFont, to: historyDepthValue)
                .adding(font: .mediumSemiboldFont, to: historyDepthUnit)
            } else {
                let template = "content.system.message_history_depth_modified_disabled"
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
            historyDepthInitiallySetAttributedText()
        } else {
            historyDepthModifiedAttributedText()
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

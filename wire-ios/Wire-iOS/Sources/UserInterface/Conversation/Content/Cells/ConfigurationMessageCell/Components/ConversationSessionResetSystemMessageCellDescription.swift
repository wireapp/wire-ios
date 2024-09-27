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
import WireCommonComponents
import WireDataModel
import WireDesign

final class ConversationSessionResetSystemMessageCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(message: ZMConversationMessage, data: ZMSystemMessageData, sender: UserType) {
        let icon = StyleKitIcon.envelope.makeImage(size: .tiny, color: UIColor.Wire.primaryLabel)
        let title = Self.makeAttributedString(sender)
        self.configuration = View.Configuration(
            icon: icon,
            attributedText: title,
            showLine: true
        )
        self.accessibilityLabel = title.string
    }

    // MARK: Internal

    typealias View = ConversationSystemMessageCell

    var message: ZMConversationMessage?
    var delegate: ConversationMessageCellDelegate?
    var actionController: ConversationMessageActionController?

    var topMargin: Float = 0
    var isFullWidth = true
    var supportsActions = false
    var showEphemeralTimer = false
    var containsHighlightableContent = false
    var accessibilityIdentifier: String?
    var accessibilityLabel: String?

    var configuration: ConversationSystemMessageCell.Configuration

    static func makeAttributedString(_ sender: UserType) -> NSAttributedString {
        let string: String =
            if sender.isSelfUser {
                L10n.Localizable.Content.System.SessionReset.`self`
            } else {
                L10n.Localizable.Content.System.SessionReset.other(sender.name ?? "")
            }

        return NSMutableAttributedString.markdown(from: string, style: .systemMessage)
    }
}

//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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
import WireDataModel

final class MLSMigrationJoinAfterwardsCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell

    let configuration: View.Configuration

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    var message: WireDataModel.ZMConversationMessage?
    var delegate: ConversationMessageCellDelegate?
    var actionController: ConversationMessageActionController?

    init(systemMessageData: ZMSystemMessageData) {
        let icon = Asset.Images.attention.image.withTintColor(SemanticColors.Icon.backgroundDefault)
        let content = Self.makeAttributedString(for: systemMessageData)

        configuration = View.Configuration(icon: icon, attributedText: content, showLine: false)
        accessibilityLabel = content?.string
    }

    private static func makeAttributedString(for systemMessageData: ZMSystemMessageData) -> NSAttributedString? {
        typealias Localizable = L10n.Localizable.Content.System.MlsMigration

        let text = NSMutableAttributedString.markdown(
            from: Localizable.joinAfterwards,
            style: .systemMessage
        )
        let link = NSAttributedString(
            string: Localizable.learnMore,
            attributes: [
                .font: UIFont.mediumSemiboldFont,
                .underlineStyle: NSUnderlineStyle(.single).rawValue as NSNumber
            ]
        )

        return [text, link].joined(separator: NSAttributedString(" "))
    }
}

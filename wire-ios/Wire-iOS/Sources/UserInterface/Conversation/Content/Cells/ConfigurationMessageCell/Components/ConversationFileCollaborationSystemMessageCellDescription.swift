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

final class ConversationFileCollaborationSystemMessageCellDescription: ConversationMessageCellDescription {

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

    init() {
        let fullText = L10n.Localizable.Content.System.FileCollaboration.enabled
        var attributedText: NSMutableAttributedString
        let baseAttributes: [NSAttributedString.Key: AnyObject] = [
            .font: UIFont.mediumFont,
            .foregroundColor: LabelColors.textDefault
        ]

        let icon = UIImage(systemName: "rectangle.stack.fill")?
            .withRenderingMode(.alwaysOriginal)
            .withTintColor(IconColors.backgroundDefault)

        attributedText = .init(
            string: fullText,
            attributes: baseAttributes
        )

        if let range = fullText.lowercased().range(of: "on", options: .backwards) {
            let nsRange = NSRange(range, in: fullText)
            attributedText.addAttribute(.font, value: UIFont.mediumSemiboldFont, range: nsRange)
        }

        self.configuration = View.Configuration(icon: icon, attributedText: attributedText, showLine: false)
        self.accessibilityLabel = attributedText.string
        self.actionController = nil
    }

}

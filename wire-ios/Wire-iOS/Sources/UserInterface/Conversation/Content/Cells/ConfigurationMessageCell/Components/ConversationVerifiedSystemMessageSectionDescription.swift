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

final class ConversationVerifiedSystemMessageSectionDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init() {
        let title = NSAttributedString.markdown(
            from: L10n.Localizable.Content.System.Mls.conversationIsVerified(WireURLs.shared.endToEndIdentityInfo),
            style: .systemMessage
        )

        self.configuration = View.Configuration(
            icon: .init(resource: .certificateValid),
            attributedText: title,
            showLine: true
        )

        self.accessibilityLabel = title.string
        self.actionController = nil
    }

    // MARK: Internal

    typealias View = ConversationSystemMessageCell

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
}

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

final class ConversationMissedCallSystemMessageCellDescription: ConversationMessageCellDescription {

    typealias View = ConversationSystemMessageCell
    typealias IconColors = SemanticColors.Icon
    typealias LabelColors = SemanticColors.Label

    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer: Bool = false
    var topMargin: Float = 0

    let isFullWidth: Bool = true
    let supportsActions: Bool = false
    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let viewModel = ConversationMissedCallSystemMessageViewModel(
            icon: .endCall,
            iconColor: IconColors.backgroundMissedPhoneCall,
            systemMessageType: data.systemMessageType,
            font: .mediumFont,
            textColor: LabelColors.textDefault,
            message: message
        )

        let attributedString = viewModel.attributedTitle()

        configuration = View.Configuration(
            icon: viewModel.image(),
            attributedText: attributedString,
            showLine: false
        )
        accessibilityLabel = attributedString?.string
        actionController = nil
    }

    func isConfigurationEqual(with other: Any) -> Bool {
        guard let otherDescription = other as? ConversationMissedCallSystemMessageCellDescription else {
            return false
        }

        return self.configuration == otherDescription.configuration
    }
}

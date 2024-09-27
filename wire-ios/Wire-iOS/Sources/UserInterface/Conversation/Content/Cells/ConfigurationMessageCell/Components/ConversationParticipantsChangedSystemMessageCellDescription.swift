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

final class ConversationParticipantsChangedSystemMessageCellDescription: ConversationMessageCellDescription {
    // MARK: Lifecycle

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let iconColor = IconColors.backgroundDefault
        let textColor = LabelColors.textDefault

        let model = ParticipantsCellViewModel(
            font: .mediumFont,
            largeFont: .largeSemiboldFont,
            textColor: textColor,
            iconColor: iconColor,
            message: message
        )

        self.configuration = View.Configuration(
            icon: model.image(),
            attributedText: model.attributedTitle(),
            showLine: true,
            warning: model.warning()
        )

        self.accessibilityLabel = model.attributedTitle()?.string
        self.actionController = nil
    }

    // MARK: Internal

    typealias View = ConversationParticipantsSystemMessageCell
    typealias LabelColors = SemanticColors.Label
    typealias IconColors = SemanticColors.Icon

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

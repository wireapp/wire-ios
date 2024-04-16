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

final class ConversationStartedSystemMessageCellDescription: NSObject, ConversationMessageCellDescription {

    typealias View = ConversationStartedSystemMessageCell
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
    var conversationObserverToken: Any?

    init(message: ZMConversationMessage, data: ZMSystemMessageData) {
        let color = LabelColors.textDefault
        let iconColor = IconColors.backgroundDefault
        let model = ParticipantsCellViewModel(
            font: .mediumFont,
            largeFont: .largeSemiboldFont,
            textColor: color,
            iconColor: iconColor,
            message: message
        )

        actionController = nil
        configuration = View.Configuration(title: model.attributedHeading(),
                                            message: model.attributedTitle() ?? NSAttributedString(string: ""),
                                            selectedUsers: model.selectedUsers,
                                            icon: model.image())
        super.init()

        accessibilityLabel = configuration.message.string
    }

}

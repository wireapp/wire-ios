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
import WireDataModel
import WireDesign

final class ConversationStartedSystemMessageCellDescription: NSObject, ConversationMessageCellDescription {

    typealias View = ConversationStartedSystemMessageCell<ConversationStartedSystemMessageCellDescription>
    typealias IconColors = SemanticColors.Icon
    typealias LabelColors = SemanticColors.Label

    var configuration: View.Configuration

    var message: ZMConversationMessage? {
        didSet {
            if let message {
                configuration.selectedUsers = Self.makeModel(message: message).selectedUsers
            }
        }
    }

    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var topMargin: CGFloat = 16
    var bottomMargin: CGFloat = -8

    let containsHighlightableContent: Bool = false

    let accessibilityIdentifier: String? = nil
    var conversationObserverToken: Any?

    init(message: ZMConversationMessage) {
        self.configuration = Self.makeConfiguration(message: message)
        self.actionController = nil

        super.init()

        accessibilityLabel = configuration.message.string
    }

    private static func makeModel(message: ZMConversationMessage) -> ParticipantsCellViewModel {
        let color = LabelColors.textDefault
        let iconColor = IconColors.backgroundDefault
        return ParticipantsCellViewModel(
            font: .mediumFont,
            largeFont: .largeSemiboldFont,
            textColor: color,
            iconColor: iconColor,
            message: message
        )
    }

    private static func makeConfiguration(message: ZMConversationMessage) -> View.Configuration {
        let model = makeModel(message: message)
        return View.Configuration(
            title: model.attributedHeading(),
            message: model.attributedTitle() ?? NSAttributedString(string: ""),
            selectedUsers: model.selectedUsers,
            icon: model.image()
        )
    }

}

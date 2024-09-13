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

final class ConversationEncryptionInfoSystemMessageCellDescription: ConversationMessageCellDescription {
    typealias View = ConversationWarningSystemMessageCell
    let configuration: View.Configuration

    var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 26.0

    let isFullWidth = true
    let supportsActions = false
    let containsHighlightableContent = false

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    init() {
        typealias connectionView = L10n.Localizable.Conversation.ConnectionView

        self.configuration = View.Configuration(
            topText: connectionView.encryptionInfo,
            bottomText: connectionView.sensitiveInformationWarning
        )

        self.accessibilityLabel = "\(connectionView.encryptionInfo), \(connectionView.sensitiveInformationWarning)"
        self.actionController = nil
    }
}

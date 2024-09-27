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

// MARK: - CustomMessageView + ConversationMessageCell

extension CustomMessageView: ConversationMessageCell {
    var selectionView: UIView? {
        messageLabel
    }

    func configure(with object: String, animated: Bool) {
        messageText = object
    }
}

// MARK: - UnknownMessageCellDescription

/// A description for a message cell that informs the user a message cannot be rendered.

final class UnknownMessageCellDescription: ConversationMessageCellDescription {
    typealias View = CustomMessageView
    let configuration: String

    weak var message: ZMConversationMessage?
    weak var delegate: ConversationMessageCellDelegate?
    weak var actionController: ConversationMessageActionController?

    var showEphemeralTimer = false
    var topMargin: Float = 0

    let accessibilityIdentifier: String? = nil
    let accessibilityLabel: String?

    let isFullWidth = false
    let supportsActions = false
    let containsHighlightableContent = false

    init() {
        self.configuration = L10n.Localizable.Content.System.UnknownMessage.body
        self.accessibilityLabel = configuration
    }
}

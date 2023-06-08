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
import UIKit
import WireDataModel

// MARK: - ReactionMessageCellDescription

final class ReactionMessageCellDescription: ConversationMessageCellDescription {

    // MARK: - Properties

    typealias View = ReactionsCellView
    let configuration: View.Configuration

    init(message: ZMConversationMessage) {
        self.message = message
        self.configuration = View.Configuration(message: message)
    }

    var topMargin: Float = 0

    var isFullWidth: Bool = true

    var supportsActions: Bool = false

    var showEphemeralTimer: Bool = false

    var containsHighlightableContent: Bool = false

    var message: WireDataModel.ZMConversationMessage?

    weak var delegate: ConversationMessageCellDelegate?

    weak var actionController: ConversationMessageActionController?

    var accessibilityIdentifier: String? = "reaction message cell"

    var accessibilityLabel: String? = "reaction message cell"
}

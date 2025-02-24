//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class StackViewCellDescription: ConversationMessageCellDescription {
    typealias View = StackingConversationMessageContentView

    var canBeCombinedWithOtherCells: Bool { false }

    var topMargin: Float
    let isFullWidth: Bool
    let supportsActions: Bool
    var showEphemeralTimer: Bool
    let containsHighlightableContent: Bool
    var message: (any ZMConversationMessage)?
    var delegate: (any ConversationMessageCellDelegate)?
    var actionController: ConversationMessageActionController?
    let configuration: View.Configuration
    let accessibilityIdentifier: String?
    let accessibilityLabel: String?

    init(cellDescriptions: [AnyConversationMessageCellDescription]) {
        fatalError()
    }

    init(
        topMargin: Float,
        isFullWidth: Bool,
        supportsActions: Bool,
        showEphemeralTimer: Bool,
        containsHighlightableContent: Bool,
        configuration: View.Configuration,
        accessibilityIdentifier: String?,
        accessibilityLabel: String?
    ) {
        self.topMargin = topMargin
        self.isFullWidth = isFullWidth
        self.supportsActions = supportsActions
        self.showEphemeralTimer = showEphemeralTimer
        self.containsHighlightableContent = containsHighlightableContent
        self.configuration = configuration
        self.accessibilityIdentifier = accessibilityIdentifier
        self.accessibilityLabel = accessibilityLabel
    }

}

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

final class GroupDetailsInactivityTimeoutCell: GroupDetailsDisclosureOptionsCell {

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.inactivitytimeoutoptions"
        title = "Auto-lock timeout"
        accessibilityHint = L10n.Accessibility.ConversationDetails.OptionButton.hint
        icon = UIImage(systemName: "timer")
        iconColor = SemanticColors.Icon.foregroundDefault
    }

    func configure(with conversation: GroupDetailsConversationType) {
        guard let conversationID = (conversation as? ZMConversation)?.remoteIdentifier else {
            status = InactivityTimeout.thirtySeconds.displayString
            return
        }
        status = InactivityTimeout.stored(for: conversationID).displayString
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? SemanticColors.View.backgroundUserCellHightLighted
                : SemanticColors.View.backgroundUserCell
        }
    }
}

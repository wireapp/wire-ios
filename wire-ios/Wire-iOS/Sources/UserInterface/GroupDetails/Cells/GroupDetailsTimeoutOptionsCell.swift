//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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

final class GroupDetailsTimeoutOptionsCell: GroupDetailsDisclosureOptionsCell {

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.timeoutoptions"
        title = L10n.Localizable.GroupDetails.TimeoutOptionsCell.title
        accessibilityHint = L10n.Accessibility.ConversationDetails.OptionButton.hint

        iconColor = SemanticColors.Icon.foregroundDefault
        guard let iconColor = iconColor else { return }
        icon = StyleKitIcon.hourglass.makeImage(size: .tiny,
                                                color: iconColor).withRenderingMode(.alwaysTemplate)
    }

    func configure(with conversation: GroupDetailsConversationType) {
        let timeout = MessageDestructionTimeoutValue(rawValue: conversation.syncedMessageDestructionTimeout)
        status = timeout.displayString
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
            ? SemanticColors.View.backgroundUserCellHightLighted
            : SemanticColors.View.backgroundUserCell
        }
    }

}

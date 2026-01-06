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

import Foundation
import WireDesign

final class GroupDetailsAccessOptionsCell: GroupDetailsDisclosureOptionsCell {

    override func setUp() {
        super.setUp()
        accessibilityIdentifier = "cell.groupdetails.accessLevel"
        title = L10n.Localizable.GroupDetails.AccessOptionsCell.title
        accessibilityHint = L10n.Accessibility.ConversationDetails.OptionButton.hint

        icon = .init(resource: .access).withRenderingMode(.alwaysTemplate)
        iconColor = SemanticColors.Icon.foregroundDefault
    }

    func configure(with conversation: GroupDetailsConversationType) {
        // as for MVP only private channels are supported
        // TODO: [WPB-16860] https://wearezeta.atlassian.net/browse/WPB-16860
        status = L10n.Localizable.ChannelAccessLevel.private
//        status = conversation.accessLevelPermission == nil ? L10n.Localizable.ChannelAccessLevel.public : L10n
//            .Localizable.ChannelAccessLevel.public
    }

    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted
                ? SemanticColors.View.backgroundUserCellHightLighted
                : SemanticColors.View.backgroundUserCell
        }
    }

}

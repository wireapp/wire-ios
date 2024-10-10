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
import WireCommonComponents
import WireDesign

final class InviteTeamMemberCell: StartUIIconCell {

    override func setupViews() {
        super.setupViews()
        icon = .envelope
        title = PeoplePicker.inviteTeamMembers
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits.insert(.button)
        accessibilityIdentifier = "button.searchui.invite_team"
    }

}

final class CreateGroupCell: StartUIIconCell {

    override func setupViews() {
        super.setupViews()
        icon = .createConversation
        // TODO: fix
        // title = PeoplePicker.QuickAction.createConversation
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits.insert(.button)
        accessibilityIdentifier = "button.searchui.creategroup"
    }

}

final class CreateGuestRoomCell: StartUIIconCell {

    override func setupViews() {
        super.setupViews()
        icon = .guest
        // TODO: fix
        // title = PeoplePicker.QuickAction.createGuestRoom
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits.insert(.button)
        accessibilityIdentifier = "button.searchui.createguestroom"
    }

}

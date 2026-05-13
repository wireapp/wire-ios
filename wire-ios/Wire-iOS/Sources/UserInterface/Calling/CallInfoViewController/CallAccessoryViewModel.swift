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

struct CallAccessoryViewModel {

    struct DisplayState {
        let avatarUser: HashBoxUser?
        let participants: CallParticipantsList?
        let isAvatarHidden: Bool
        let isParticipantsListHidden: Bool
        let isVideoPlaceholderStatusHidden: Bool
    }

    func displayState(for configuration: CallInfoViewControllerInput) -> DisplayState {
        let avatarUser: HashBoxUser?
        let participants: CallParticipantsList?

        switch configuration.accessoryType {
        case let .avatar(user):
            avatarUser = user
            participants = nil
        case let .participantsList(callParticipants):
            avatarUser = nil
            participants = callParticipants
        case .none:
            avatarUser = nil
            participants = nil
        }

        return DisplayState(
            avatarUser: avatarUser,
            participants: participants,
            isAvatarHidden: !configuration.accessoryType.showAvatar,
            isParticipantsListHidden: !configuration.accessoryType.showParticipantList,
            isVideoPlaceholderStatusHidden: configuration.videoPlaceholderState != .statusTextDisplayed
        )
    }
}

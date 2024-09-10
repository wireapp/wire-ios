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

import WireCommonComponents
import WireDataModel
import WireDesign

enum UserTypeIconStyle: String, IconImageStyle {
    case guest
    case external
    case member
    case federated

    var icon: StyleKitIcon? {
        switch self {
        case .guest:
            .guest
        case .external:
            .externalPartner
        case .member:
            .none
        case .federated:
            .federated
        }
    }

    var accessibilitySuffix: String {
        rawValue
    }

    var accessibilityLabel: String {
        typealias ContactsList = L10n.Accessibility.ContactsList

        switch self {
        case .guest:
            return ContactsList.GuestIcon.description
        case .external:
            return ContactsList.ExternalIcon.description
        case .member:
            return ContactsList.MemberIcon.description
        case .federated:
            return ContactsList.FederatedIcon.description
        }
    }
}

extension UserTypeIconStyle {
    init(
        conversation: GroupDetailsConversationType?,
        user: UserType,
        selfUserHasTeam: Bool
    ) {
        if user.isFederated {
            self = .federated
        } else if user.isExternalPartner {
            self = .external
        } else if let conversation {
            self = !user.isGuest(in: conversation) || user.isSelfUser ? .member : .guest
        } else {
            self = !selfUserHasTeam || user.isTeamMember || user.isServiceUser
                ? .member
                : .guest
        }
    }
}

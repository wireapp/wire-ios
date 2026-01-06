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

/// Which users are allowed to be participants in a conversation.

public enum ConversationAccessRole: Sendable {

    /// Members of the owning team.

    case teamMember

    /// Any user outside the owning team.

    case nonTeamMember

    /// Users that are not in the team and are not services.

    case guest

    /// App/service users (aka bots).

    case app

}

enum ConversationAccessRoleV0: String, Sendable, Decodable, ToAPIModelConvertible {
    case teamMember = "team_member"
    case nonTeamMember = "non_team_member"
    case guest
    case app = "service"

    func toAPIModel() -> ConversationAccessRole {
        switch self {
        case .teamMember:
            .teamMember
        case .nonTeamMember:
            .nonTeamMember
        case .guest:
            .guest
        case .app:
            .app
        }
    }
}

extension ConversationAccessRole: ToNetworkConvertible {

    func toNetworkModel() -> ConversationAccessRoleV0 {
        switch self {
        case .teamMember:
            .teamMember
        case .nonTeamMember:
            .nonTeamMember
        case .guest:
            .guest
        case .app:
            .app
        }
    }
}

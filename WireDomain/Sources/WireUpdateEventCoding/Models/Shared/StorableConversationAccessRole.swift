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

import WireAPI

enum StorableConversationAccessRole: String, Equatable, Codable, Sendable {

    case teamMember
    case nonTeamMember
    case guest
    case service

    init(_ value: WireAPI.ConversationAccessRole) {
        switch value {
        case .teamMember:
            self = .teamMember
        case .nonTeamMember:
            self = .nonTeamMember
        case .guest:
            self = .guest
        case .service:
            self = .service
        }
    }

    func toAPIModel() -> WireAPI.ConversationAccessRole {
        switch self {
        case .teamMember:
            return .teamMember
        case .nonTeamMember:
            return .nonTeamMember
        case .guest:
            return .guest
        case .service:
            return .service
        }
    }
}

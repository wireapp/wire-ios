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
import WireNetwork

enum StorableTeamEvent: Equatable, Codable, Sendable {

    case delete
    case memberLeave(StorableTeamMemberLeaveEvent)
    case memberUpdate(StorableTeamMemberUpdateEvent)
    case create(StorableTeamCreateEvent)

    init(_ value: WireNetwork.TeamEvent) {
        switch value {
        case .delete:
            self = .delete
        case let .memberLeave(memberLeave):
            self = .memberLeave(StorableTeamMemberLeaveEvent(memberLeave))
        case let .memberUpdate(memberUpdate):
            self = .memberUpdate(StorableTeamMemberUpdateEvent(memberUpdate))
        case let .create(create):
            self = .create(StorableTeamCreateEvent(create))
        }
    }

    func toAPIModel() -> WireNetwork.TeamEvent {
        switch self {
        case .delete:
            .delete
        case let .memberLeave(memberLeave):
            .memberLeave(memberLeave.toAPIModel())
        case let .memberUpdate(memberUpdate):
            .memberUpdate(memberUpdate.toAPIModel())
        case let .create(create):
            .create(create.toAPIModel())
        }
    }

}

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

import Foundation
import WireAPI

struct StorableTeamMemberLeaveEvent: Equatable, Codable, Sendable {

    private let teamID: UUID
    private let userID: UUID
    private let time: Date

    init(_ value: WireAPI.TeamMemberLeaveEvent) {
        self.teamID = value.teamID
        self.userID = value.userID
        self.time = value.time
    }

    func toAPIModel() -> WireAPI.TeamMemberLeaveEvent {
        .init(
            teamID: teamID,
            userID: userID,
            time: time
        )
    }

}

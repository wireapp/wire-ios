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

import Foundation

struct TeamMemberLeaveEventDecoder {

    func decode(
        from container: KeyedDecodingContainer<TeamEventCodingKeys>
    ) throws -> TeamMemberLeaveEvent {
        let teamID = try container.decode(
            UUID.self,
            forKey: .teamID
        )

        let time = try container.decode(
            UTCTimeMillis.self,
            forKey: .time
        )

        let payload = try container.decode(
            Payload.self,
            forKey: .payload
        )

        return TeamMemberLeaveEvent(
            teamID: teamID,
            userID: payload.userID,
            time: time.date
        )
    }

    private struct Payload: Decodable {

        let userID: UUID

        enum CodingKeys: String, CodingKey {

            case userID = "user"

        }

    }

}

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

extension UpdateEvent {

    init(
        eventType: TeamEventType,
        from decoder: any Decoder
    ) throws {
        let container = try decoder.container(keyedBy: TeamEventCodingKeys.self)

        switch eventType {
        case .conversationCreate:
            self = .team(.conversationCreate)

        case .conversationDelete:
            self = .team(.conversationDelete)

        case .delete:
            self = .team(.delete)

        case .memberLeave:
            let event = try container.decodeMemberLeaveEvent()
            self = .team(.memberLeave(event))

        case .memberUpdate:
            self = .team(.memberUpdate)
        }
    }

}

private enum TeamEventCodingKeys: String, CodingKey {

    case teamID = "team"
    case payload = "data"

}

private extension KeyedDecodingContainer<TeamEventCodingKeys> {

    func decodeTeamID() throws -> UUID {
        try decode(
            UUID.self,
            forKey: .teamID
        )
    }

}

// MARK: - Member leave

private extension KeyedDecodingContainer<TeamEventCodingKeys> {

    func decodeMemberLeaveEvent() throws -> TeamMemberLeaveEventData {
        let payload = try decode(
            TeamMemberLeaveEventPayload.self,
            forKey: .payload
        )

        return try TeamMemberLeaveEventData(
            teamID: decodeTeamID(),
            userID: payload.userID
        )
    }

    private struct TeamMemberLeaveEventPayload: Decodable {

        let userID: UUID

        enum CodingKeys: String, CodingKey {

            case userID = "user"

        }

    }

}

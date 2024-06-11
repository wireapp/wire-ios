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

struct UserConnectionEventDecoder {
    func decode(
        from container: KeyedDecodingContainer<UserEventCodingKeys>
    ) throws -> UserConnectionEvent {
        let user = try container.decode(
            UserPayload.self,
            forKey: .user
        )

        let connection = try container.decode(
            ConnectionPayload.self,
            forKey: .connection
        )

        return UserConnectionEvent(
            userName: user.name,
            connection: Connection(
                senderId: connection.from,
                receiverId: connection.to,
                receiverQualifiedId: connection.qualifiedTo,
                conversationId: connection.conversationID,
                qualifiedConversationId: connection.qualifiedConversationID,
                lastUpdate: connection.lastUpdate,
                status: connection.status
            )
        )
    }

    private struct UserPayload: Decodable {
        let name: String
    }

    private struct ConnectionPayload: Decodable {
        let from: UUID?
        let to: UUID?
        let qualifiedTo: QualifiedID?
        let conversationID: UUID?
        let qualifiedConversationID: QualifiedID?
        let lastUpdate: Date
        let status: ConnectionStatus

        enum CodingKeys: String, CodingKey {
            case from
            case to
            case qualifiedTo = "qualified_to"
            case conversationID = "conversation"
            case qualifiedConversationID = "qualified_conversation"
            case lastUpdate = "last_update"
            case status
        }
    }
}

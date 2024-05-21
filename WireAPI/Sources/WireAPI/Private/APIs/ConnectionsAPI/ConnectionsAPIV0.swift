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

class ConnectionsAPIV0: ConnectionsAPI {

    let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    let path = "/connections/\(userID)"
    let decoder = ResponsePayloadDecoder(decoder: .defaultDecoder)

    func getConnections(for userId: UUID) async throws -> Connection {
        let request = HTTPRequest(
            path: path.append(userId.transportString()),
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch response.code {
        case 200:
            let payload = try decoder.decodePayload(
                from: response,
                as: ConnectionResponseV0.self
            )

            return payload.toParent()

        default:
            let failure = try decoder.decodePayload(
                from: response,
                as: FailureResponse.self
            )

            throw failure
        }
    }

}

struct ConnectionResponseV0: Decodable {

    enum CodingKeys: String, CodingKey {
        case from
        case to
        case qualifiedTo = "qualified_to"
        case conversationID = "conversation"
        case qualifiedConversationID = "qualified_conversation"
        case lastUpdate = "last_update"
        case status
    }

    static var eventType: ZMUpdateEventType {
        return .userConnection
    }

    let from: UUID?
    let to: UUID?
    let qualifiedTo: QualifiedID?
    let conversationID: UUID?
    let qualifiedConversationID: QualifiedID?
    let lastUpdate: Date
    let status: ConnectionStatus

    func toParent() -> Connection {
        .ini
        )
    }
}

enum ConnectionStatus: String, Decodable {

    case accepted = "accepted"
    case blocked = "blocked"
    case pending = "pending"
    case ignored = "ignored"
    case sent = "sent"
    case cancelled = "cancelled"
    case missingLegalholdConsent = "missing-legalhold-consent"
}

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

    func basePath(for qualifiedId: QualifiedID) -> String {
        "\(resourcePath)\(qualifiedId.uuid.transportString())"
    }

    let resourcePath = "/list-connections/"
    let decoder = ResponsePayloadDecoder(decoder: .defaultDecoder)

    func fetchConnections() async throws -> AsyncStream<[Connection]> {

        PayloadPager(start: ...) {
            // Create request using "start" index
            // Execute request
            // Parse response
            return Page(
                element: response.connections,
                hasMore: response.hasMore,
                nextStart: ...
            )
        }
    }    func getConnections(qualifiedId: QualifiedID) async throws -> Connection {
        let userId = qualifiedId.uuid

        let request = HTTPRequest(
            path: basePath(for: qualifiedId),
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: 200, type: ConnectionResponseV0.self)
            .failure(code: 400, error: ConnectionsAPIError.invalidParameters)
            .parse(response)
    }

}

struct ConnectionResponseV0: Decodable, ToAPIModelConvertible {

    enum CodingKeys: String, CodingKey {
        case from
        case to
        case qualifiedTo = "qualified_to"
        case conversationID = "conversation"
        case qualifiedConversationID = "qualified_conversation"
        case lastUpdate = "last_update"
        case status
    }
    
    let from: UUID?
    let to: UUID?
    let qualifiedTo: QualifiedID?
    let conversationID: UUID?
    let qualifiedConversationID: QualifiedID?
    let lastUpdate: Date
    let status: ConnectionStatus

    func toAPIModel() -> Connection {
        Connection(senderId: from,
                   receiverId: to,
                   receiverQualifiedId: qualifiedTo,
                   conversationId: conversationID,
                   qualifiedConversationId: qualifiedConversationID,
                   lastUpdate: lastUpdate,
                   status: status)
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

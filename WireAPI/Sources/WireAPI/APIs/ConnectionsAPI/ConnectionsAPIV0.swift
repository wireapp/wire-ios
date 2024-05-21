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

struct PaginationRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case pagingState = "paging_state"
        case size
    }
    var pagingState: String?
    // Set in case you want specific number of pages, otherwise, the backend will return default per endpoint
    var size: Int?
}

class ConnectionsAPIV0: ConnectionsAPI, VersionedAPI {

    enum Constants {
        static let resourcePath = "/list-connections/"
        static let maxConnectionsCount = 500
    }

    let httpClient: HTTPClient
    let decoder = ResponsePayloadDecoder(decoder: .defaultDecoder)

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    func fetchConnections() async throws -> PayloadPager<Connection> {

        let pager = PayloadPager<Connection> { start in

            // body Params
            let params = PaginationRequest(pagingState: start, size: Constants.maxConnectionsCount)
            let body = try JSONEncoder.defaultEncoder.encode(params)

            // Create request using "start" index
            let request = HTTPRequest(
                path: Constants.resourcePath,
                method: .post,
                body: body
            )

            // Execute request
            let response = try await self.httpClient.executeRequest(request)

            // Parse response
            let responsePayload = try ResponseParser()
                .success(code: 200, type: PaginatedConnectionList.self)
                .failure(code: 400, error: ConnectionsAPIError.invalidBody)
                .parse(response)

            let a = PayloadPager<Connection>.Page(
                element: responsePayload.connections.map { $0.toAPIModel() },
                hasMore: responsePayload.hasMore,
                nextStart: responsePayload.pagingState
            )
            return a
        }

        return pager
    }
}

private struct PaginatedConnectionList: Decodable, ToAPIModelConvertible {

     enum CodingKeys: String, CodingKey {
         case connections
         case pagingState = "paging_state"
         case hasMore = "has_more"
     }

     var nextStartReference: String? {
         return pagingState
     }

     let connections: [ConnectionResponseV0]
     let pagingState: String
     let hasMore: Bool

    func toAPIModel() -> PaginatedConnectionList {
        self
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

public enum ConnectionStatus: String, Decodable, Equatable {

    case accepted = "accepted"
    case blocked = "blocked"
    case pending = "pending"
    case ignored = "ignored"
    case sent = "sent"
    case cancelled = "cancelled"
    case missingLegalholdConsent = "missing-legalhold-consent"
}

/*
 {
   "connections": [
     {
       "conversation": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
       "from": "99db9768-04e3-4b5d-9268-831b6a25c4ab",
       "last_update": "2021-05-12T10:52:02.671Z",
       "qualified_conversation": {
         "domain": "example.com",
         "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
       },
       "qualified_to": {
         "domain": "example.com",
         "id": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
       },
       "status": "accepted",
       "to": "99db9768-04e3-4b5d-9268-831b6a25c4ab"
     }
   ],
   "has_more": true,
   "paging_state": "string"
 }
 */

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

// MARK: - ConnectionsAPIV0

class ConnectionsAPIV0: ConnectionsAPI, VersionedAPI {
    // MARK: Lifecycle

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    // MARK: Internal

    let httpClient: any HTTPClient

    var apiVersion: APIVersion {
        .v0
    }

    var resourcePath: String {
        "\(pathPrefix)/list-connections/"
    }

    func getConnections() async throws -> PayloadPager<Connection> {
        let pager = PayloadPager<Connection> { start in

            // body Params
            let params = PaginationRequest(pagingState: start, size: Constants.batchSize)
            let body = try JSONEncoder.defaultEncoder.encode(params)

            let request = HTTPRequest(
                path: self.resourcePath,
                method: .post,
                body: body
            )
            let response = try await self.httpClient.executeRequest(request)

            return try ResponseParser()
                .success(code: .ok, type: PaginatedConnectionListV0.self)
                .failure(code: .badRequest, error: ConnectionsAPIError.invalidBody)
                .parse(response)
        }

        return pager
    }

    // MARK: Private

    private enum Constants {
        static let batchSize = 500
    }
}

// MARK: - PaginatedConnectionListV0

private struct PaginatedConnectionListV0: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case connections
        case pagingState = "paging_state"
        case hasMore = "has_more"
    }

    let connections: [ConnectionResponseV0]
    let pagingState: String
    let hasMore: Bool

    var nextStartReference: String? {
        pagingState
    }

    func toAPIModel() -> PayloadPager<Connection>.Page {
        PayloadPager<Connection>.Page(
            element: connections.map { $0.toAPIModel() },
            hasMore: hasMore,
            nextStart: pagingState
        )
    }
}

// MARK: - ConnectionResponseV0

private struct ConnectionResponseV0: Decodable, ToAPIModelConvertible {
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
    let lastUpdate: UTCTimeMillis
    let status: ConnectionStatus

    func toAPIModel() -> Connection {
        Connection(
            senderID: from,
            receiverID: to,
            receiverQualifiedID: qualifiedTo,
            conversationID: conversationID,
            qualifiedConversationID: qualifiedConversationID,
            lastUpdate: lastUpdate.date,
            status: status
        )
    }
}

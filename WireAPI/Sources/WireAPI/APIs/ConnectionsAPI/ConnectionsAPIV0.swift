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

class ConnectionsAPIV0: ConnectionsAPI, VersionedAPI {

    private enum Constants {
        static let maxConnectionsCount = 500
    }

    let httpClient: HTTPClient
    let fetchLimit: Int
    let decoder = ResponsePayloadDecoder(decoder: .defaultDecoder)

    convenience init(httpClient: HTTPClient) {
        self.init(httpClient: httpClient, fetchLimit: Constants.maxConnectionsCount)
    }

    init(httpClient: HTTPClient, fetchLimit: Int) {
        self.httpClient = httpClient
        self.fetchLimit = Constants.maxConnectionsCount
    }

    var apiVersion: APIVersion {
        .v0
    }

    var resourcePath: String {
        "\(pathPrefix)/list-connections/"
    }

    func getConnections() async throws -> PayloadPager<Connection> {

        let pager = PayloadPager<Connection> { start in

            // body Params
            let params = PaginationRequest(pagingState: start, size: Constants.maxConnectionsCount)
            let body = try JSONEncoder.defaultEncoder.encode(params)

            let request = HTTPRequest(
                path: self.resourcePath,
                method: .post,
                body: body
            )
            let response = try await self.httpClient.executeRequest(request)

            // Parse response
            let responsePayload = try ResponseParser()
                .success(code: 200, type: PaginatedConnectionListV0.self)
                .failure(code: 400, error: ConnectionsAPIError.invalidBody)
                .parse(response)

            return PayloadPager<Connection>.Page(
                element: responsePayload.connections.map { $0.toAPIModel() },
                hasMore: responsePayload.hasMore,
                nextStart: responsePayload.pagingState
            )
        }

        return pager
    }
}

private struct PaginatedConnectionListV0: Decodable, ToAPIModelConvertible {

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

    func toAPIModel() -> PaginatedConnectionListV0 {
        self
    }
}

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
    let lastUpdate: Date
    let status: ConnectionStatus

    func toAPIModel() -> Connection {
        Connection(
            senderId: from,
            receiverId: to,
            receiverQualifiedId: qualifiedTo,
            conversationId: conversationID,
            qualifiedConversationId: qualifiedConversationID,
            lastUpdate: lastUpdate,
            status: status
        )
    }
}

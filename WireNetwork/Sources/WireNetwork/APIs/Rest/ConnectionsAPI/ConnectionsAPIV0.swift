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

class ConnectionsAPIV0: ConnectionsAPI, VersionedAPI {

    private enum Constants {
        static let batchSize = 500
    }

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    var resourcePath: String {
        "\(pathPrefix)/list-connections"
    }

    func getConnections() throws -> PayloadPager<[Connection]> {
        PayloadPager<[Connection]> { start in

            // body Params
            let params = PaginationRequest(pagingState: start, size: Constants.batchSize)
            let body = try JSONEncoder.defaultEncoder.encode(params)

            let request = try URLRequestBuilder(path: self.resourcePath)
                .withMethod(.post)
                .withBody(body, contentType: .json)
                .build()

            let (data, response) = try await self.apiService.executeRequest(
                request,
                requiringAccessToken: true
            )

            return try ResponseParser()
                .success(code: .ok, type: PaginatedConnectionListV0.self)
                .failure(code: .badRequest, error: ConnectionsAPIError.invalidBody)
                .parse(code: response.statusCode, data: data)
        }
    }

    func sendConnectionRequest(
        domain: String,
        userId: String
    ) async throws {

        let request = try URLRequestBuilder(path: "\(pathPrefix)/connections/\(domain)/\(userId)")
            .withMethod(.post)
            .build()

        let (_, response) = try await apiService.executeRequest(request, requiringAccessToken: true)
        guard response.statusCode == HTTPStatusCode.created.rawValue else {
            throw ConnectionsAPIError.invalidBody
        }
    }

    func acceptConnectionRequest(
        domain: String,
        userId: String
    ) async throws {

        let body = try JSONEncoder.defaultEncoder.encode(RequestBodyAcceptConnectionRequestV0.accepted)

        let request = try URLRequestBuilder(path: "\(pathPrefix)/connections/\(domain)/\(userId)")
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (_, response) = try await apiService.executeRequest(request, requiringAccessToken: true)
        guard response.statusCode == HTTPStatusCode.ok.rawValue else {
            throw ConnectionsAPIError.invalidBody
        }
    }
}

private struct PaginatedConnectionListV0: Decodable, ToAPIModelConvertible {

    enum CodingKeys: String, CodingKey {
        case connections
        case pagingState = "paging_state"
        case hasMore = "has_more"
    }

    var nextStartReference: String? {
        pagingState
    }

    let connections: [ConnectionResponseV0]
    let pagingState: String
    let hasMore: Bool

    func toAPIModel() -> PayloadPager<[Connection]>.Page {
        PayloadPager<[Connection]>.Page(
            element: connections.map { $0.toAPIModel() },
            hasMore: hasMore,
            nextStart: pagingState
        )
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
    let qualifiedTo: QualifiedIDV0?
    let conversationID: UUID?
    let qualifiedConversationID: QualifiedIDV0?
    let lastUpdate: UTCTime
    let status: ConnectionStatusV0

    func toAPIModel() -> Connection {
        Connection(
            senderID: from,
            receiverID: to,
            receiverQualifiedID: qualifiedTo?.toAPIModel(),
            conversationID: conversationID,
            qualifiedConversationID: qualifiedConversationID?.toAPIModel(),
            lastUpdate: lastUpdate.date,
            status: status.toAPIModel()
        )
    }
}

private struct RequestBodyAcceptConnectionRequestV0: Encodable {
    static let accepted = Self()
    let status: String = "accepted"
}

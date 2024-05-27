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

class ConversationsAPIV0: ConversationsAPI, VersionedAPI {

    // MARK: - Constants

    enum Constants {
        static let batchSize = 500
    }

    // MARK: - Properties

    var apiVersion: APIVersion { .v0 }

    let httpClient: HTTPClient
    let batchSize: Int

    // MARK: - Initialize

    init(httpClient: HTTPClient, batchSize: Int = Constants.batchSize) {
        self.httpClient = httpClient
        self.batchSize = batchSize
    }

    public func getConversationIdentifiers() async throws -> PayloadPager<[QualifiedID]> {
        let resourcePath = "/conversations/list-ids/"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<[QualifiedID]> { start in
            // body Params
            let params = PaginationRequest(pagingState: start, size: self.batchSize)
            let body = try jsonEncoder.encode(params)

            let request = HTTPRequest(
                path: resourcePath,
                method: .post,
                body: body
            )
            let response = try await self.httpClient.executeRequest(request)

            return try ResponseParser()
                .success(code: 200, type: PaginatedConversationIDsV0.self)
                .failure(code: 400, error: ConnectionsAPIError.invalidBody)
                .parse(response)
        }
    }

}

private struct PaginatedConversationIDsV0: Decodable, ToAPIModelConvertible {

    enum CodingKeys: String, CodingKey {
        case conversationUUIDs = "conversations"
        case pagingState = "paging_state"
        case hasMore = "has_more"
    }

    let conversationUUIDs: [UUID]
    let pagingState: String
    let hasMore: Bool

    func toAPIModel() -> PayloadPager<[QualifiedID]>.Page {
        let qualifiedIDs = conversationUUIDs.map {
            QualifiedID(uuid: $0, domain: "")
        }

        return PayloadPager<[QualifiedID]>.Page(
            element: [qualifiedIDs], // TODO: why does it need to be an array of arrays?
            hasMore: hasMore,
            nextStart: pagingState
        )
    }
}

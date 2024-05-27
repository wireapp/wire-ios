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

public struct Conversation: ConversationsAPI, VersionedAPI {

    // MARK: - Constants

    private enum Constants {
        static let batchSize = 500
    }

    // MARK: - Properties

    let apiVersion: APIVersion = .v0

    private let httpClient: HTTPClient

    // MARK: - Initialize

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    public func getAllConversations() async throws -> PayloadPager<[QualifiedID]> {
        let resourcePath = "\(pathPrefix)/conversations/list-ids/"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<[QualifiedID]> { start in
            // body Params
            let params = PaginationRequest(pagingState: start, size: Constants.batchSize)
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
        case conversationIDs
        case pagingState = "paging_state"
        case hasMore = "has_more"
    }

    let conversationIDs: [QualifiedID]
    let pagingState: String
    let hasMore: Bool

    func toAPIModel() -> PayloadPager<[QualifiedID]>.Page {
        PayloadPager<[QualifiedID]>.Page(
            element: [conversationIDs], // TODO: why does it need to be an array of arrays?
            hasMore: hasMore,
            nextStart: pagingState
        )
    }
}

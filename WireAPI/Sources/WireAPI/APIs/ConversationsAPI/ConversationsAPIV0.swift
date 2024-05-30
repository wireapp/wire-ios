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

    enum Constant {
        static let batchSize = 500
    }

    // MARK: - Properties

    var apiVersion: APIVersion { .v0 }

    let httpClient: HTTPClient

    private let backendDomain: String

    // MARK: - Initialize

    init(httpClient: HTTPClient, backendDomain: String) {
        self.httpClient = httpClient
        self.backendDomain = backendDomain
    }

    func getLegacyConversationIdentifiers() async throws -> PayloadPager<UUID> {
        let resourcePath = "/conversations/list-ids/"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<UUID> { start in
            // body Params
            let params = PaginationRequest(pagingState: start, size: Constant.batchSize)
            let body = try jsonEncoder.encode(params)

            let request = HTTPRequest(
                path: resourcePath,
                method: .post,
                body: body
            )
            let response = try await self.httpClient.executeRequest(request)

            return try ResponseParser()
                .success(code: 200, type: PaginatedConversationIDsV0.self)
                .parse(response)
        }
    }

    public func getConversationIdentifiers() async throws -> PayloadPager<QualifiedID> {
        assertionFailure("not implemented! use getLegacyConversationIdentifiers() instead")
        throw ConversationsAPIError.notImplemented
    }
}

// MARK: -

private struct PaginatedConversationIDsV0: Decodable, ToAPIModelConvertible {

    enum CodingKeys: String, CodingKey {
        case conversationIdentifiers = "conversations"
        case pagingState = "paging_state"
        case hasMore = "has_more"
    }

    let conversationIdentifiers: [UUID]
    let pagingState: String
    let hasMore: Bool

    func toAPIModel() -> PayloadPager<UUID>.Page {
        .init(
            element: conversationIdentifiers,
            hasMore: hasMore,
            nextStart: pagingState
        )
    }
}

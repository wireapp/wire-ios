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

// MARK: - ConversationsAPIV1

class ConversationsAPIV1: ConversationsAPIV0 {
    override var apiVersion: APIVersion { .v1 }

    override func getLegacyConversationIdentifiers() async throws -> PayloadPager<UUID> {
        assertionFailure("not implemented! use getConversationIdentifiers() instead")
        throw ConversationsAPIError.notImplemented
    }

    override func getConversationIdentifiers() async throws -> PayloadPager<QualifiedID> {
        let resourcePath = "\(pathPrefix)/conversations/list-ids/"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<QualifiedID> { start in
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
                .success(code: .ok, type: PaginatedConversationIDsV1.self)
                .parse(response)
        }
    }
}

// MARK: - PaginatedConversationIDsV1

private struct PaginatedConversationIDsV1: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case conversationIDs = "qualified_conversations"
        case pagingState = "paging_state"
        case hasMore = "has_more"
    }

    let conversationIDs: [QualifiedID]
    let pagingState: String
    let hasMore: Bool

    func toAPIModel() -> PayloadPager<QualifiedID>.Page {
        PayloadPager<QualifiedID>.Page(
            element: conversationIDs,
            hasMore: hasMore,
            nextStart: pagingState
        )
    }
}

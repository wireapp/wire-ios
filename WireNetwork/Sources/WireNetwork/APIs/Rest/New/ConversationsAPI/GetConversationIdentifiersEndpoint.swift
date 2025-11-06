//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

struct GetConversationIdentifiersEndpoint {

    let apiVersion: APIVersion
    let apiService: APIService

    enum Constants {
        static let batchSize = 500
    }

    func callAsFunction() async throws -> PayloadPager<[QualifiedID]> {
        guard apiVersion >= .v5 else {
            throw RestAPIError.unsupportedAPIVersion(apiVersion)
        }

        let path = "/v\(apiVersion.rawValue)/conversations/list-ids"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<[QualifiedID]> { start in
            // body Params
            let params = PaginationRequest(pagingState: start, size: Constants.batchSize)
            let body = try jsonEncoder.encode(params)

            let request = try URLRequestBuilder(path: path)
                .withMethod(.post)
                .withBody(body, contentType: .json)
                .build()

            let (data, response) = try await self.apiService.executeRequest(
                request,
                requiringAccessToken: true
            )

            return try ResponseParser()
                .success(code: .ok, type: PaginatedConversationIDsV5.self)
                .parse(code: response.statusCode, data: data)
        }
    }

    private struct PaginatedConversationIDsV5: Decodable, ToAPIModelConvertible {

        enum CodingKeys: String, CodingKey {
            case conversationIDs = "qualified_conversations"
            case pagingState = "paging_state"
            case hasMore = "has_more"
        }

        let conversationIDs: [QualifiedIDV0]
        let pagingState: String
        let hasMore: Bool

        func toAPIModel() -> PayloadPager<[QualifiedID]>.Page {
            PayloadPager<[QualifiedID]>.Page(
                element: conversationIDs.map { $0.toAPIModel() },
                hasMore: hasMore,
                nextStart: pagingState
            )
        }
    }

}

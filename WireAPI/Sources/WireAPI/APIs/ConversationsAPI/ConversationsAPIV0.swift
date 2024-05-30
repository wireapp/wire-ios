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

    public func getConversationIdentifiers() async throws -> PayloadPager<QualifiedID> {
        let resourcePath = "/conversations/list-ids/"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<QualifiedID> { start in
            // body Params
            let params = PaginationRequest(pagingState: start, size: Constant.batchSize)
            let body = try jsonEncoder.encode(params)

            let request = HTTPRequest(
                path: resourcePath,
                method: .post,
                body: body
            )
            let response = try await self.httpClient.executeRequest(request)

            return try self.decodeConversationIdentifiers(from: response)
        }
    }

    private func decodeConversationIdentifiers(from response: HTTPResponse) throws -> PayloadPager<QualifiedID>.Page {
        guard let data = response.payload else {
            throw ResponseParserError.missingPayload
        }

        let decoder = JSONDecoder.defaultDecoder

        switch response.code {
        case 200..<400:
            let payload = try decoder.decode(PaginatedConversationIDsV0.self, from: data)
            return payload.toAPIModel(domain: backendDomain)
        default:
            throw try decoder.decode(FailureResponse.self, from: data)
        }
    }

}

private struct PaginatedConversationIDsV0: Decodable {

    enum CodingKeys: String, CodingKey {
        case conversationUUIDs = "conversations"
        case pagingState = "paging_state"
        case hasMore = "has_more"
    }

    let conversationUUIDs: [UUID]
    let pagingState: String
    let hasMore: Bool

    func toAPIModel(domain: String) -> PayloadPager<QualifiedID>.Page {
        let qualifiedIDs = conversationUUIDs.map {
            QualifiedID(uuid: $0, domain: domain)
        }

        return PayloadPager<QualifiedID>.Page(
            element: qualifiedIDs,
            hasMore: hasMore,
            nextStart: pagingState
        )
    }
}

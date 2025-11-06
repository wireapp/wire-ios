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

struct GetConversationsEndpoint {

    let apiVersion: APIVersion
    let apiService: any APIServiceProtocol

    func callAsFunction(
        for identifiers: [QualifiedID]
    ) async throws -> ConversationList {
        guard apiVersion >= .v5 else {
            throw RestAPIError.unsupportedAPIVersion(apiVersion)
        }

        guard 1 ... 1000 ~= identifiers.count else {
            throw RestAPIError.illegalArgument(
                message: "identifiers must contain between 1 and 1000 elements, got  \(identifiers.count)"
            )
        }

        let path = "/v\(apiVersion.rawValue)/conversations/list"
        let body = BodyV5(ids: identifiers.map { $0.toNetworkModel() })
        let bodyData = try JSONEncoder.defaultEncoder.encode(body)

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(bodyData, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        switch apiVersion {
        case .v5...(.v7):
            return try ResponseParser()
                .success(code: .ok, type: ResponseV5.self)
                .parse(code: response.statusCode, data: data)
        default:
            return try ResponseParser()
                .success(code: .ok, type: ResponseV8.self)
                .parse(code: response.statusCode, data: data)
        }
    }

    // MARK: - Request payload

    private struct BodyV5: Encodable {

        let ids: [QualifiedIDV0]

        enum CodingKeys: String, CodingKey {
            case ids = "qualified_ids"
        }

    }

    // MARK: - Response payload

    private struct ResponseV5: Decodable, ToAPIModelConvertible {

        let found: [ConversationV5]
        let notFound: [QualifiedIDV0]
        let failed: [QualifiedIDV0]

        func toAPIModel() -> ConversationList {
            ConversationList(
                found: found.map { $0.toAPIModel() },
                notFound: notFound.map { $0.toAPIModel() },
                failed: failed.map { $0.toAPIModel() }
            )
        }

        enum CodingKeys: String, CodingKey {
            case found
            case notFound = "not_found"
            case failed
        }

    }

    private struct ResponseV8: Decodable, ToAPIModelConvertible {
        enum CodingKeys: String, CodingKey {
            case found
            case notFound = "not_found"
            case failed
        }

        let found: [ConversationV8] // in v8, decode (if present) the add_permission value
        let notFound: [QualifiedIDV0]
        let failed: [QualifiedIDV0]

        func toAPIModel() -> ConversationList {
            ConversationList(
                found: found.map { $0.toAPIModel() },
                notFound: notFound.map { $0.toAPIModel() },
                failed: failed.map { $0.toAPIModel() }
            )
        }
    }

}

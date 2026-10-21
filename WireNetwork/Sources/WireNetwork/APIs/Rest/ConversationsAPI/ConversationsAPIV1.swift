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

class ConversationsAPIV1: ConversationsAPIV0 {
    override var apiVersion: APIVersion { .v1 }

    override func getLegacyConversationIdentifiers() throws -> PayloadPager<[UUID]> {
        assertionFailure("not implemented! use getConversationIdentifiers() instead")
        throw ConversationsAPIError.notImplemented
    }

    override func getConversationIdentifiers() throws -> PayloadPager<[QualifiedID]> {
        let path = "\(pathPrefix)\(basePath)/list-ids/"
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
                .success(code: .ok, type: PaginatedConversationIDsV1.self)
                .parse(code: response.statusCode, data: data)
        }
    }

    override func updateConversationName(
        _ name: String,
        for conversationID: QualifiedID
    ) async throws -> ConversationRenameEvent? {
        let parameters = UpdateConversationNameParametersV1(name: name)
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/\(conversationID.domain)/\(conversationID.id)/name"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        guard response.statusCode != HTTPStatusCode.noContent.rawValue else {
            return nil
        }

        return try ResponseParser()
            .success(code: .ok, type: ConversationRenameResponseV1.self)
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(
                code: .forbidden,
                label: "action-denied",
                error: ConversationsAPIError.insufficientAuthorization
            )
            .failure(code: .forbidden, label: "operation-denied", error: ConversationsAPIError.operationDenied)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .parse(code: response.statusCode, data: data)
    }

    override func removeParticipant(
        userID: UserID,
        conversationID: ConversationID
    ) async throws {
        let path = "\(pathPrefix)\(basePath)/\(conversationID.domain)/\(conversationID.id)/members/\(userID.domain)/\(userID.id)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.delete)
            .build()

        let (_, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        guard response.statusCode == HTTPStatusCode.ok.rawValue else {
            throw ConversationsAPIError.invalidBody
        }
    }
}

// MARK: -

private struct PaginatedConversationIDsV1: Decodable, ToAPIModelConvertible {

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

private struct UpdateConversationNameParametersV1: Encodable {
    let name: String
}

private struct ConversationRenameResponseV1: Decodable, ToAPIModelConvertible {

    let event: ConversationRenameEvent

    init(from decoder: any Decoder) throws {
        let updateEvent = try UpdateEventDecodingProxy(from: decoder).updateEvent

        guard case let .conversation(.rename(event)) = updateEvent else {
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Expected a conversation rename event")
            )
        }

        self.event = event
    }

    func toAPIModel() -> ConversationRenameEvent {
        event
    }
}

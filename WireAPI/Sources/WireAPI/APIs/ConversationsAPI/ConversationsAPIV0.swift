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

    let apiService: any APIServiceProtocol

    var apiVersion: APIVersion { .v0 }

    var basePath: String {
        "/conversations"
    }

    // MARK: - Initialize

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    func getLegacyConversationIdentifiers() async throws -> PayloadPager<UUID> {
        // This function needs to be used in APIVersion.v0 instead of `getConversationIdentifiers`,
        // because the backend API returns only `UUID`s instead of `QualifiedID`s in later versions.
        // We are missing the related domain to map the UUID to a valid `QualifiedID` object.
        //
        // For design reasons, we decided to implement two functions rather than passing the domain from the outside
        // and manually mapping `QualifiedID`. This task can be performed by the caller.
        // As soon as APIVersion.v0 is removed, the legacy function can be deleted, making the code clean and easy to
        // understand.

        let path = "\(basePath)/list-ids/"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<UUID> { start in
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
                .success(code: .ok, type: PaginatedConversationIDsV0.self)
                .parse(code: response.statusCode, data: data)
        }
    }

    func getConversationIdentifiers() async throws -> PayloadPager<QualifiedID> {
        assertionFailure("not implemented! use getLegacyConversationIdentifiers() instead")
        throw ConversationsAPIError.notImplemented
    }

    func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers)
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/list/v2"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: QualifiedConversationListV0.self)
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .parse(code: response.statusCode, data: data)
    }

    func getMLSOneToOneConversation(
        userID: String,
        in domain: String
    ) async throws -> Conversation {
        throw ConversationsAPIError.unsupportedEndpointForAPIVersion
    }

    func getConversationGuestLink(
        conversationID: String
    ) async throws -> String? {
        let path = "\(pathPrefix)\(basePath)/\(conversationID)/code"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ConversationCodeV0.self)
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(code: .notFound, label: "cnv", error: ConversationsAPIError.invalidConversationID)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .failure(
                code: .notFound,
                label: "no-conversation-code",
                error: ConversationsAPIError.conversationCodeNotFound
            )
            .failure(code: .conflict, label: "guest-links-disabled", error: ConversationsAPIError.guestLinksDisabled)
            .parse(code: response.statusCode, data: data)
    }

}

// MARK: Encodables

struct GetConversationsParametersV0: Encodable {
    enum CodingKeys: String, CodingKey {
        case qualifiedIdentifiers = "qualified_ids"
    }

    let qualifiedIdentifiers: [QualifiedID]
}

// MARK: - Decodables

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

// MARK: -

struct QualifiedConversationListV0: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case found
        case notFound = "not_found"
        case failed
    }

    let found: [ConversationV0]
    let notFound: [QualifiedID]
    let failed: [QualifiedID]

    func toAPIModel() -> ConversationList {
        ConversationList(
            found: found.map { $0.toAPIModel() },
            notFound: notFound,
            failed: failed
        )
    }
}

// MARK: -

struct ConversationV0: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case access
        case legacyAccessRole = "access_role"
        case accessRoles = "access_role_v2"
        case creator
        case epoch
        case id
        case lastEvent = "last_event"
        case lastEventTime = "last_event_time"
        case members
        case messageProtocol = "protocol"
        case messageTimer = "message_timer"
        case mlsGroupID = "group_id"
        case name
        case qualifiedID = "qualified_id"
        case readReceiptMode = "receipt_mode"
        case teamID = "team"
        case type
    }

    var access: Set<ConversationAccessMode>?
    var accessRoles: Set<ConversationAccessRole>?
    var creator: UUID?
    var epoch: UInt?
    var id: UUID?
    var lastEvent: String?
    var lastEventTime: UTCTimeMillis?
    var legacyAccessRole: ConversationAccessRoleLegacy?
    var members: QualifiedConversationMembers?
    var messageProtocol: ConversationMessageProtocol?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedID?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: ConversationType?

    func toAPIModel() -> Conversation {
        Conversation(
            id: id,
            qualifiedID: qualifiedID,
            teamID: teamID,
            type: type,
            messageProtocol: messageProtocol,
            mlsGroupID: mlsGroupID,
            cipherSuite: nil,
            epoch: epoch,
            epochTimestamp: nil,
            creator: creator,
            members: members.map { $0.toAPIModel() },
            name: name,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            access: access,
            accessRoles: accessRoles,
            legacyAccessRole: legacyAccessRole,
            lastEvent: lastEvent,
            lastEventTime: lastEventTime?.date
        )
    }
}

struct ConversationCodeV0: Decodable, ToAPIModelConvertible {

    let code: String
    let key: String
    let uri: String?

    func toAPIModel() -> String? {
        uri
    }
}

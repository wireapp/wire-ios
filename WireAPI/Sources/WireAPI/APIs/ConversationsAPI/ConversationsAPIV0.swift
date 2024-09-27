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

// MARK: - ConversationsAPIV0

class ConversationsAPIV0: ConversationsAPI, VersionedAPI {
    // MARK: - Constants

    enum Constants {
        static let batchSize = 500
    }

    // MARK: - Properties

    var apiVersion: APIVersion { .v0 }

    let httpClient: any HTTPClient

    // MARK: - Initialize

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
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

        let resourcePath = "/conversations/list-ids/"
        let jsonEncoder = JSONEncoder.defaultEncoder

        return PayloadPager<UUID> { start in
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
                .success(code: .ok, type: PaginatedConversationIDsV0.self)
                .parse(response)
        }
    }

    func getConversationIdentifiers() async throws -> PayloadPager<QualifiedID> {
        assertionFailure("not implemented! use getLegacyConversationIdentifiers() instead")
        throw ConversationsAPIError.notImplemented
    }

    func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers)
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let resourcePath = "\(pathPrefix)/conversations/list/v2"

        let request = HTTPRequest(
            path: resourcePath,
            method: .post,
            body: body
        )
        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: QualifiedConversationListV0.self)
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .parse(response)
    }
}

// MARK: - GetConversationsParametersV0

struct GetConversationsParametersV0: Encodable {
    enum CodingKeys: String, CodingKey {
        case qualifiedIdentifiers = "qualified_ids"
    }

    let qualifiedIdentifiers: [QualifiedID]
}

// MARK: - PaginatedConversationIDsV0

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

// MARK: - QualifiedConversationListV0

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

// MARK: - ConversationV0

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

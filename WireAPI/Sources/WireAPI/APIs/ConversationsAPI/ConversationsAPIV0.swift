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

    // MARK: - Initialize

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func getLegacyConversationIdentifiers() async throws -> PayloadPager<UUID> {
        // This function needs to be used in APIVersion.v0 instead of `getConversationIdentifiers`,
        // because the backend API returns only `UUID`s instead of `QualifiedID`s in later versions.
        // We are missing the related domain to map the UUID to a valid `QualifiedID` object.
        //
        // For design reasons, we decided to implement two functions rather than passing the domain from the outside
        // and manually mapping `QualifiedID`. This task can be performed by the caller.
        // As soon as APIVersion.v0 is removed, the legacy function can be deleted, making the code clean and easy to understand.

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
                .success(code: 200, type: PaginatedConversationIDsV0.self)
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
        let resourcePath = "/conversations/list/v2"

        let request = HTTPRequest(
            path: resourcePath,
            method: .post,
            body: body
        )
        let response = try await self.httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: 200, type: QualifiedConversationListV0.self)
            .failure(code: 400, error: ConversationsAPIError.invalidBody)
            .parse(response)
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
        case found = "found"
        case notFound = "not_found"
        case failed = "failed"
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
        case accessRole = "access_role"
        case accessRoleV2 = "access_role_v2"
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

    var access: [String]?
    var accessRoles: [String]?
    var creator: UUID?
    var epoch: UInt?
    var id: UUID?
    var lastEvent: String?
    var lastEventTime: String?
    var legacyAccessRole: String?
    var members: QualifiedConversationMembers?
    var messageProtocol: String?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedID?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: Int?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        access = try container.decodeIfPresent([String].self, forKey: .access)
        creator = try container.decodeIfPresent(UUID.self, forKey: .creator)
        epoch = try container.decodeIfPresent(UInt.self, forKey: .epoch)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        lastEvent = try container.decodeIfPresent(String.self, forKey: .lastEvent)
        lastEventTime = try container.decodeIfPresent(String.self, forKey: .lastEventTime)
        members = try container.decodeIfPresent(QualifiedConversationMembers.self, forKey: .members)
        messageProtocol = try container.decodeIfPresent(String.self, forKey: .messageProtocol)
        messageTimer = try container.decodeIfPresent(TimeInterval.self, forKey: .messageTimer)
        mlsGroupID = try container.decodeIfPresent(String.self, forKey: .mlsGroupID)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        qualifiedID = try container.decodeIfPresent(QualifiedID.self, forKey: .qualifiedID)
        readReceiptMode = try container.decodeIfPresent(Int.self, forKey: .readReceiptMode)
        teamID = try container.decodeIfPresent(UUID.self, forKey: .teamID)
        type = try container.decodeIfPresent(Int.self, forKey: .type)

        // parsing for v0
        legacyAccessRole = try container.decodeIfPresent(String.self, forKey: .accessRole)
        accessRoles = try container.decodeIfPresent([String].self, forKey: .accessRoleV2)
    }

    func toAPIModel() -> Conversation {
        Conversation(
            access: access,
            accessRoles: accessRoles,
            cipherSuite: nil,
            creator: creator,
            epoch: epoch,
            epochTimestamp: nil,
            id: id,
            lastEvent: lastEvent,
            lastEventTime: lastEventTime,
            legacyAccessRole: legacyAccessRole,
            members: members.map { $0.toAPIModel() },
            messageProtocol: messageProtocol,
            messageTimer: messageTimer,
            mlsGroupID: mlsGroupID,
            name: name,
            qualifiedID: qualifiedID,
            readReceiptMode: readReceiptMode,
            teamID: teamID,
            type: type
        )
    }
}

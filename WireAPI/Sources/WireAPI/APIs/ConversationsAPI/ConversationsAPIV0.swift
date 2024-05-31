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

    func getConversations(for identifiers: [QualifiedID]) async throws -> [ConversationList] {
        // /conversations/list/v2
        fatalError("not implemented")
    }
}

// MARK: Decodables

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

// MARK: - Decodables

private struct ConversationListV0<Conversation: Decodable>: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case found = "found"
        case notFound = "not_found"
        case failed = "failed"
    }

    let found: [Conversation]
    let notFound: [QualifiedID]
    let failed: [QualifiedID]

    func toAPIModel() -> [Conversation] {
        // TODO: implement
        return []
    }
}

private struct ConversationV0: Decodable {
    enum CodingKeys: String, CodingKey {
        case qualifiedID = "qualified_id"
        case id
        case type
        case creator
        case cipherSuite = "cipher_suite"
        case access
        case accessRole = "access_role"
        case accessRoleV2 = "access_role_v2"
        case name
        case members
        case lastEvent = "last_event"
        case lastEventTime = "last_event_time"
        case teamID = "team"
        case messageTimer = "message_timer"
        case readReceiptMode = "receipt_mode"
        case messageProtocol = "protocol"
        case mlsGroupID = "group_id"
        case epoch
        case epochTimestamp = "epoch_timestamp"
    }

    var qualifiedID: QualifiedID?
    var id: UUID?
    var type: Int?
    var creator: UUID?
    var access: [String]?
    var accessRoles: [String]?
    var legacyAccessRole: String?
    var name: String?
    var members: QualifiedConversationMembers?
    var lastEvent: String?
    var lastEventTime: String?
    var teamID: UUID?
    var messageTimer: TimeInterval?
    var readReceiptMode: Int?
    var messageProtocol: String?
    var mlsGroupID: String?
    var epoch: UInt?

    init(
        qualifiedID: QualifiedID? = nil,
        id: UUID?  = nil,
        type: Int? = nil,
        creator: UUID? = nil,
        cipherSuite: UInt16? = nil,
        access: [String]? = nil,
        legacyAccessRole: String? = nil,
        accessRoles: [String]? = nil,
        name: String? = nil,
        members: QualifiedConversationMembers? = nil,
        lastEvent: String? = nil,
        lastEventTime: String? = nil,
        teamID: UUID? = nil,
        messageTimer: TimeInterval? = nil,
        readReceiptMode: Int? = nil,
        messageProtocol: String? = nil,
        mlsGroupID: String? = nil,
        epoch: UInt? = nil,
        epochTimestamp: Date? = nil
    ) {
        self.qualifiedID = qualifiedID
        self.id = id
        self.type = type
        self.creator = creator
        self.access = access
        self.legacyAccessRole = legacyAccessRole
        self.accessRoles = accessRoles
        self.name = name
        self.members = members
        self.lastEvent = lastEvent
        self.lastEventTime = lastEventTime
        self.teamID = teamID
        self.messageTimer = messageTimer
        self.readReceiptMode = readReceiptMode
        self.messageProtocol = messageProtocol
        self.mlsGroupID = mlsGroupID
        self.epoch = epoch
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        qualifiedID = try container.decodeIfPresent(QualifiedID.self, forKey: .qualifiedID)
        id = try container.decodeIfPresent(UUID.self, forKey: .id)
        type = try container.decodeIfPresent(Int.self, forKey: .type)
        creator = try container.decodeIfPresent(UUID.self, forKey: .creator)
        access = try container.decodeIfPresent([String].self, forKey: .access)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        members = try container.decodeIfPresent(QualifiedConversationMembers.self, forKey: .members)
        lastEvent = try container.decodeIfPresent(String.self, forKey: .lastEvent)
        lastEventTime = try container.decodeIfPresent(String.self, forKey: .lastEventTime)
        teamID = try container.decodeIfPresent(UUID.self, forKey: .teamID)
        messageTimer = try container.decodeIfPresent(TimeInterval.self, forKey: .messageTimer)
        readReceiptMode = try container.decodeIfPresent(Int.self, forKey: .readReceiptMode)
        messageProtocol = try container.decodeIfPresent(String.self, forKey: .messageProtocol)
        mlsGroupID = try container.decodeIfPresent(String.self, forKey: .mlsGroupID)
        epoch = try container.decodeIfPresent(UInt.self, forKey: .epoch)

        legacyAccessRole = try container.decodeIfPresent(String.self, forKey: .accessRole)
        accessRoles = try container.decodeIfPresent([String].self, forKey: .accessRoleV2)
    }
}

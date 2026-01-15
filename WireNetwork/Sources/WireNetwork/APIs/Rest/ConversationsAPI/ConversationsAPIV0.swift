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

    func getLegacyConversationIdentifiers() async throws -> PayloadPager<[UUID]> {
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

        return PayloadPager<[UUID]> { start in
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

    func getConversationIdentifiers() async throws -> PayloadPager<[QualifiedID]> {
        throw ConversationsAPIError.notImplemented
    }

    func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        guard 1 ... 1000 ~= identifiers.count else {
            throw ConversationsAPIError.illegalArgument(
                message: "identifiers must contain between 1 and 1000 elements, got  \(identifiers.count)"
            )
        }

        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers.map { $0.toNetworkModel() })
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
    ) async throws -> (Conversation, MLSPublicKeys?) {
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

    func createGroupConversation(
        parameters: CreateGroupConversationParameters
    ) async throws -> Conversation {
        guard parameters.groupType != .channel else {
            throw ConversationsAPIError.unsupportedChannelCreationForAPIEndpoint
        }

        let input = CreateGroupConversationParametersV0(from: parameters)
        let body = try JSONEncoder.defaultEncoder.encode(input)
        let path = "\(pathPrefix)\(basePath)"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ConversationV0.self)
            .success(code: .created, type: ConversationV0.self)
            .failure(code: .badRequest, label: "non-empty-member-list", error: ConversationsAPIError.nonEmptyMemberList)
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .failure(
                code: .forbidden,
                label: "missing-legalhold-consent",
                error: ConversationsAPIError.missingLegalHoldConsent
            )
            .failure(code: .forbidden, label: "operation-denied", error: ConversationsAPIError.operationDenied)
            .failure(code: .forbidden, label: "no-team-member", error: ConversationsAPIError.noTeamMember)
            .failure(code: .forbidden, label: "not-connected", error: ConversationsAPIError.notConnected)
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .parse(code: response.statusCode, data: data)
    }

    func addChannelPermission(
        conversationID: String,
        conversationDomain: String,
        permission: ChannelPermission
    ) async throws -> ChannelPermission {
        throw ConversationsAPIError.unsupportedEndpointForAPIVersion
    }

    func updateConversationAccess(
        conversationID: QualifiedID,
        allowGuests: Bool,
        allowApps: Bool
    ) async throws {

        // Build access roles based on allowGuests and allowApps
        var accessRoles: Set<ConversationAccessRole> = [.teamMember]
        if allowGuests {
            accessRoles.insert(.guest)
            accessRoles.insert(.nonTeamMember)
        }
        if allowApps {
            accessRoles.insert(.app)
        }

        // Build access modes based on allowGuests
        var accessModes: Set<ConversationAccessMode> = [.invite]
        if allowGuests {
            accessModes.insert(.code)
        }

        let parameters = UpdateConversationAccessParametersV0(
            accessModes: accessModes.map { $0.toNetworkModel() }.sorted { $0.rawValue < $1.rawValue },
            accessRoles: accessRoles.map { $0.toNetworkModel() }.sorted { $0.rawValue < $1.rawValue }
        )
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/\(conversationID.id)/access" // no domain in path compared to v3

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        try ResponseParser()
            .success(code: .ok, type: DummyPayload.self)
            .success(code: .noContent)
            .failure(code: .forbidden, label: "invalid-op", error: ConversationsAPIError.invalidOperation)
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(code: .forbidden, label: "action-denied", error: ConversationsAPIError.insufficientAuthorization)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .parse(code: response.statusCode, data: data)

        struct DummyPayload: Decodable, ToAPIModelConvertible {
            func toAPIModel() -> Void {}
        }

    }

}

// MARK: Encodables

struct CreateGroupConversationParametersV0: Encodable {
    let users: [UUID]?
    let qualifiedUsers: [QualifiedIDV0]?
    let access: [String]?
    let legacyAccessRole: String?
    let accessRoles: [String]?
    let name: String?
    let team: CreateGroupConversationTeamInfoV0?
    let messageTimer: TimeInterval?
    let readReceiptMode: Int?
    let conversationRole: String?
    let messageProtocol: String

    enum CodingKeys: String, CodingKey {
        case users
        case qualifiedUsers = "qualified_users"
        case access
        case legacyAccessRole = "access_role"
        case accessRoles = "access_role_v2"
        case name
        case team
        case messageTimer = "message_timer"
        case readReceiptMode = "receipt_mode"
        case conversationRole = "conversation_role"
        case messageProtocol = "protocol"
    }

    init(from parameters: CreateGroupConversationParameters) {
        self.users = parameters.messageProtocol == .proteus ? parameters.unqualifiedUserIDs : nil
        self.qualifiedUsers = parameters.messageProtocol == .proteus ? parameters.qualifiedUserIDs
            .map { $0.toNetworkModel() } : nil
        self.access = parameters.accessMode.map { $0.toNetworkModel().rawValue }
        self.legacyAccessRole = parameters.legacyAccessRole?.toNetworkModel().rawValue
        self.accessRoles = parameters.accessRoles.map { $0.toNetworkModel().rawValue }
        self.name = parameters.name
        self.team = parameters.teamID.map { .init(teamID: $0) }
        self.messageTimer = nil
        self.readReceiptMode = parameters.isReadReceiptsEnabled ? 1 : 0
        self.conversationRole = "wire_member"
        self.messageProtocol = parameters.messageProtocol.toNetworkModel().rawValue
    }

}

struct CreateGroupConversationTeamInfoV0: Encodable {
    let teamID: UUID
    let managed: Bool = false

    enum CodingKeys: String, CodingKey {
        case teamID = "teamid"
        case managed
    }
}

struct GetConversationsParametersV0: Encodable {
    enum CodingKeys: String, CodingKey {
        case qualifiedIdentifiers = "qualified_ids"
    }

    let qualifiedIdentifiers: [QualifiedIDV0]
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

    func toAPIModel() -> PayloadPager<[UUID]>.Page {
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

    var access: Set<ConversationAccessModeV0>?
    var accessRoles: Set<ConversationAccessRoleV0>?
    var creator: UUID?
    var epoch: UInt?
    var id: UUID?
    var lastEvent: String?
    var lastEventTime: UTCTime?
    var legacyAccessRole: ConversationAccessRoleLegacyV0?
    var members: QualifiedConversationMembersV0?
    var messageProtocol: ConversationMessageProtocolV0?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedIDV0?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: ConversationTypeV0?

    func toAPIModel() -> Conversation {
        let access = access?.map { $0.toAPIModel() }
        let accessRoles = accessRoles?.map { $0.toAPIModel() }
        return Conversation(
            id: id,
            qualifiedID: qualifiedID?.toAPIModel(),
            teamID: teamID,
            type: type?.toAPIModel(),
            messageProtocol: messageProtocol?.toAPIModel(),
            mlsGroupID: mlsGroupID,
            cipherSuite: nil,
            epoch: epoch,
            epochTimestamp: nil,
            creator: creator,
            members: members.map { $0.toAPIModel() },
            name: name,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            access: access.flatMap { Set($0) },
            accessRoles: accessRoles.flatMap { Set($0) },
            legacyAccessRole: legacyAccessRole?.toAPIModel(),
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

private struct UpdateConversationAccessParametersV0: Encodable {
    let accessModes: [ConversationAccessModeV0]
    let accessRoles: [ConversationAccessRoleV0]

    enum CodingKeys: String, CodingKey {
        case accessModes = "access"
        case accessRoles = "access_role_v2" // different name compared to v3
    }
}

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

class ConversationsAPIV3: ConversationsAPIV2 {
    override var apiVersion: APIVersion { .v3 }

    override func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        guard 1 ... 1000 ~= identifiers.count else {
            throw ConversationsAPIError.illegalArgument(
                message: "identifiers must contain between 1 and 1000 elements, got  \(identifiers.count)"
            )
        }

        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers.map { $0.toNetworkModel() })
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
        let path = "\(pathPrefix)\(basePath)/list"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: QualifiedConversationListV3.self) // Change in v3
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .parse(code: response.statusCode, data: data)
    }

    override func createGroupConversation(
        parameters: CreateGroupConversationParameters
    ) async throws -> Conversation {
        guard parameters.groupType != .channel else {
            throw ConversationsAPIError.unsupportedChannelCreationForAPIEndpoint
        }

        let input = CreateGroupConversationParametersV3(from: parameters)
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
            .success(code: .ok, type: ConversationV3.self)
            .success(code: .created, type: ConversationV3.self)
            .failure(
                code: .badRequest,
                label: "mls-not-enabled",
                error: ConversationsAPIError.mlsNotEnabled
            ) // Introduced in v3
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
}

// MARK: - Encodables

struct CreateGroupConversationParametersV3: Encodable {
    let users: [UUID]?
    let qualifiedUsers: [QualifiedIDV0]?
    let access: [String]?
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
        // Changed: replace "access_role_v2" with "access_role".
        case accessRoles = "access_role"
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
        self.accessRoles = parameters.accessRoles.map { $0.toNetworkModel().rawValue }
        self.name = parameters.name
        self.team = parameters.teamID.map { .init(teamID: $0) }
        self.messageTimer = nil
        self.readReceiptMode = parameters.isReadReceiptsEnabled ? 1 : 0
        self.conversationRole = "wire_member"
        self.messageProtocol = parameters.messageProtocol.toNetworkModel().rawValue
    }

}

// MARK: Decodables

private struct QualifiedConversationListV3: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case found
        case notFound = "not_found"
        case failed
    }

    let found: [ConversationV3]
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

struct ConversationV3: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case access
        // Changed: replace "access_role_v2" with "access_role".
        case accessRoles = "access_role"
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
            legacyAccessRole: nil, // Removed: `var legacyAccessRole`
            lastEvent: lastEvent,
            lastEventTime: lastEventTime?.date
        )
    }
}

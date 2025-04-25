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
import WireFoundation

final class ConversationsAPIV8: ConversationsAPIV7 {
    override var apiVersion: APIVersion { .v8 }

    override func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers)
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
            .success(code: .ok, type: QualifiedConversationListV8.self)
            .parse(code: response.statusCode, data: data)
    }

    override func createGroupConversation(
        parameters: CreateGroupConversationParameters
    ) async throws -> Conversation {
        // removed `guard` condition in api v8 since conversation group can be either `channel` or `group_conversation`
        let input = CreateGroupConversationParametersV8(from: parameters)
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

        do {
            return try ResponseParser()
                .success(code: .ok, type: ConversationV8.self)
                .success(code: .created, type: ConversationV8.self)
                .failure(code: .badRequest, label: "mls-not-enabled", error: ConversationsAPIError.mlsNotEnabled)
                .failure(
                    code: .badRequest,
                    label: "non-empty-member-list",
                    error: ConversationsAPIError.nonEmptyMemberList
                )
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
                .failure(code: .conflict, decodableError: NonFederatingBackendErrorResponseV4.self)
                .failure(code: .unreachable, error: ConversationsAPIError.unreachableBackends)
                .parse(code: response.statusCode, data: data)
        } catch {
            if let nonFederatingDomains = error as? NonFederatingBackendErrorResponseV4 {
                throw ConversationsAPIError.nonFederatingBackends(
                    nonFederatingDomains.nonFederatingBackends
                )
            } else {
                throw error
            }
        }
    }

    override func addChannelPermission(
        conversationID: String,
        conversationDomain: String,
        permission: ChannelPermission
    ) async throws -> ChannelPermission {
        let input = ChannelPermissionParametersV8(from: permission)
        let body = try JSONEncoder.defaultEncoder.encode(input)
        let path = "\(pathPrefix)/conversations/\(conversationDomain)/\(conversationID)/add-permission"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.put)
            .withBody(body, contentType: .json)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        do {
            return try ResponseParser()
                .success(code: .ok, type: ChannelPermissionResponseV8.self) // Add permissions updated
                .failure(
                    code: .noContent,
                    error: ConversationsAPIError
                        .permissionsUnchanged
                ) // Add permissions unchanged, note: this is not ideal to treat this as a failure but we can't
                // currently have multiple success cases.
                .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
                .failure(code: .notFound, label: "no-team", error: ConversationsAPIError.teamNotFound)
                .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
                .failure(
                    code: .forbidden,
                    label: "action-denied",
                    error: ConversationsAPIError.insufficienAuthorization
                )
                .failure(code: .forbidden, label: "invalid-op", error: ConversationsAPIError.invalidOperation)
                .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
                .failure(code: .forbidden, label: "no-team-member", error: ConversationsAPIError.noTeamMember)
                .failure(code: .forbidden, label: "not-connected", error: ConversationsAPIError.usersNotConnected)
                .failure(
                    code: .forbidden,
                    label: "operation-denied",
                    error: ConversationsAPIError.insufficientPermissions
                )
                .failure(code: .conflict, decodableError: NonFederatingBackendErrorResponseV4.self)
                .failure(code: .unreachable, error: ConversationsAPIError.unreachableBackends)
                .parse(code: response.statusCode, data: data)
        } catch {
            if let nonFederatingDomains = error as? NonFederatingBackendErrorResponseV4 {
                throw ConversationsAPIError.nonFederatingBackends(
                    nonFederatingDomains.nonFederatingBackends
                )
            } else {
                throw error
            }
        }

    }
}

// MARK: - Encodables

private struct QualifiedConversationListV8: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case found
        case notFound = "not_found"
        case failed
    }

    let found: [ConversationV8] // in v8, decode (if present) the add_permission value
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

private struct ChannelPermissionResponseV8: Decodable, ToAPIModelConvertible {
    let conversationID: UUID
    let senderID: UUID
    let conversationQualifiedID: QualifiedID
    let senderQualifiedID: QualifiedID
    let payload: Payload

    struct Payload: Decodable {

        let addPermission: ChannelPermission

        enum CodingKeys: String, CodingKey {
            case addPermission = "add_permission"
        }

    }

    enum CodingKeys: String, CodingKey {

        case conversationID = "conversation"
        case senderID = "from"
        case conversationQualifiedID = "qualified_conversation"
        case senderQualifiedID = "qualified_from"
        case payload = "data"

    }

    func toAPIModel() -> ChannelPermission {
        payload.addPermission
    }

}

struct ChannelPermissionParametersV8: Encodable {
    let addPermission: ChannelPermission

    init(from channelPermission: ChannelPermission) {
        self.addPermission = channelPermission
    }

    enum CodingKeys: String, CodingKey {
        case addPermission = "add_permission"
    }
}

struct CreateGroupConversationParametersV8: Encodable {
    let users: [UUID]?
    let qualifiedUsers: [QualifiedID]?
    let access: [String]?
    let accessRoles: [String]?
    let name: String?
    let team: CreateGroupConversationTeamInfoV0?
    let messageTimer: TimeInterval?
    let readReceiptMode: Int?
    let conversationRole: String?
    let messageProtocol: String
    let conversationGroupType: ConversationGroupType // Introduced in v8

    enum CodingKeys: String, CodingKey {
        case users
        case qualifiedUsers = "qualified_users"
        case access
        case accessRoles = "access_role"
        case name
        case team
        case messageTimer = "message_timer"
        case readReceiptMode = "receipt_mode"
        case conversationRole = "conversation_role"
        case messageProtocol = "protocol"
        case conversationGroupType = "group_conv_type"
    }

    init(from parameters: CreateGroupConversationParameters) {
        self.users = parameters.messageProtocol == .proteus ? parameters.unqualifiedUserIDs : nil
        self.qualifiedUsers = parameters.messageProtocol == .proteus ? parameters.qualifiedUserIDs : nil
        self.access = parameters.accessMode.map(\.rawValue)
        self.accessRoles = parameters.accessRoles.map(\.rawValue)
        self.name = parameters.name
        self.team = parameters.teamID.map { .init(teamID: $0) }
        self.messageTimer = nil
        self.readReceiptMode = parameters.isReadReceiptsEnabled ? 1 : 0
        self.conversationRole = "wire_member"
        self.messageProtocol = parameters.messageProtocol.rawValue
        self.conversationGroupType = parameters.groupType
    }

}

// MARK: - Decodables

struct ConversationV8: Decodable, ToAPIModelConvertible {
    enum CodingKeys: String, CodingKey {
        case access
        case accessRoles = "access_role"
        case cipherSuite = "cipher_suite"
        case creator
        case epoch
        case epochTimestamp = "epoch_timestamp"
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
        case groupType = "group_conv_type"
        case addPermission = "add_permission"
    }

    var access: Set<ConversationAccessMode>?
    var accessRoles: Set<ConversationAccessRole>?
    var cipherSuite: MLSCipherSuite?
    var creator: UUID?
    var epoch: UInt?
    var epochTimestamp: UTCTime?
    var id: UUID?
    var lastEvent: String?
    var lastEventTime: UTCTime?
    var members: QualifiedConversationMembers?
    var messageProtocol: ConversationMessageProtocol?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedID?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: ConversationType?
    var groupType: ConversationGroupType? // Introduced in v8
    var addPermission: ChannelPermission? // Introduced in v8

    func toAPIModel() -> Conversation {
        Conversation(
            id: id,
            qualifiedID: qualifiedID,
            teamID: teamID,
            type: type,
            messageProtocol: messageProtocol,
            mlsGroupID: mlsGroupID,
            cipherSuite: cipherSuite,
            epoch: epoch,
            epochTimestamp: epochTimestamp?.date,
            creator: creator,
            members: members.map { $0.toAPIModel() },
            name: name,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            access: access,
            accessRoles: accessRoles,
            legacyAccessRole: nil,
            lastEvent: lastEvent,
            lastEventTime: lastEventTime?.date,
            groupType: groupType,
            addPermission: addPermission
        )
    }
}

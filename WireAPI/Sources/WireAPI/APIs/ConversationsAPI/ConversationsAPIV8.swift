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

final class ConversationsAPIV8: ConversationsAPIV7 {
    override var apiVersion: APIVersion { .v8 }
    
    override func createGroupConversation(
        groupType: ConversationGroupType,
        messageProtocol: ConversationMessageProtocol,
        creatorClientID: String,
        qualifiedUserIDs: [QualifiedID],
        unqualifiedUserIDs: [UUID],
        name: String?,
        accessMode: Set<ConversationAccessMode>,
        accessRoles: Set<ConversationAccessRole>,
        legacyAccessRole: ConversationAccessRole?,
        teamID: UUID?,
        isReadReceiptsEnabled: Bool
    ) async throws -> Conversation {
        // removed `guard` condition in api v8 since conversation group can be either `channel` or `group_conversation`
        let parameters = CreateGroupConversationParametersV8(
            users: messageProtocol == .proteus ? unqualifiedUserIDs : nil,
            qualifiedUsers: messageProtocol == .proteus ? qualifiedUserIDs : nil,
            access: accessMode.map(\.rawValue),
            accessRoles: accessRoles.map(\.rawValue),
            name: name,
            team: teamID.map { .init(teamID: $0) },
            messageTimer: nil,
            readReceiptMode: isReadReceiptsEnabled ? 1: 0,
            conversationRole: "wire_member",
            messageProtocol: messageProtocol.rawValue,
            conversationGroupType: groupType
        )
        
        let body = try JSONEncoder.defaultEncoder.encode(parameters)
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
                .failure(code: .badRequest, label: "non-empty-member-list", error: ConversationsAPIError.nonEmptyMemberList)
                .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
                .failure(code: .forbidden, label: "missing-legalhold-consent", error: ConversationsAPIError.missingLegalHoldConsent)
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
}

// MARK: - Encodables

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
        case conversationGroupType = "group_conv_type"
    }

    var access: Set<ConversationAccessMode>?
    var accessRoles: Set<ConversationAccessRole>?
    var cipherSuite: MLSCipherSuite?
    var creator: UUID?
    var epoch: UInt?
    var epochTimestamp: UTCTime?
    var id: UUID?
    var lastEvent: String?
    var lastEventTime: UTCTimeMillis?
    var members: QualifiedConversationMembers?
    var messageProtocol: ConversationMessageProtocol?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedID?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: ConversationType?
    var conversationGroupType: ConversationGroupType // Introduced in v8

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
            lastEventTime: lastEventTime?.date
        )
    }
}

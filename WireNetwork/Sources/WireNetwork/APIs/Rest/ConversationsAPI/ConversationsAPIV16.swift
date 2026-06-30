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

final class ConversationsAPIV16: ConversationsAPIV15 {

    override var apiVersion: APIVersion { .v16 }

    override func createGroupConversation(
        parameters: CreateGroupConversationParameters
    ) async throws -> Conversation {
        // New payload in v16.
        let input = CreateGroupConversationParametersV16(from: parameters)
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
                // New payload in v16.
                .success(code: .created, type: ConversationV16.self)
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

}

struct CreateGroupConversationParametersV16: Encodable {
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
    let conversationGroupType: ConversationGroupTypeV16 // changed in v16
    let cells: Bool
    let skipCreator: Bool?

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
        case skipCreator = "skip_creator"
        case cells
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
        self.conversationGroupType = parameters.groupType.toV16()
        self.skipCreator = parameters.skipCreator
        self.cells = parameters.cells ?? false
    }

}

extension ConversationGroupType {

    func toV16() -> ConversationGroupTypeV16 {
        switch self {
        case .group:
                .group
        case .channel:
                .channel
        case .meeting:
                .meeting
        }
    }

}

struct ConversationV16: Decodable, ToAPIModelConvertible, DecodableConversation {
    enum CodingKeys: String, CodingKey {
        case access
        case accessRoles = "access_role"
        case cipherSuite = "cipher_suite"
        case creator
        case epoch
        case epochTimestamp = "epoch_timestamp"
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
        case cellsState = "cells_state"
    }

    var access: Set<ConversationAccessModeV0>?
    var accessRoles: Set<ConversationAccessRoleV0>?
    var cipherSuite: MLSCipherSuiteV0?
    var creator: UUID?
    var epoch: UInt?
    var epochTimestamp: UTCTime?
    var lastEvent: String?
    var lastEventTime: UTCTime?
    var members: QualifiedConversationMembersV10?
    var messageProtocol: ConversationMessageProtocolV0?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedIDV0?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: ConversationTypeV0?
    var groupType: ConversationGroupTypeV16? // Changed in v16.
    var addPermission: ChannelPermissionV8?
    var cellsState: CellsStateV8

    func toAPIModel() -> Conversation {
        let access = access?.map { $0.toAPIModel() }
        let accessRoles = accessRoles?.map { $0.toAPIModel() }
        return Conversation(
            id: qualifiedID?.uuid,
            qualifiedID: qualifiedID?.toAPIModel(),
            teamID: teamID,
            type: type?.toAPIModel(),
            messageProtocol: messageProtocol?.toAPIModel(),
            mlsGroupID: mlsGroupID,
            cipherSuite: cipherSuite?.toAPIModel(),
            epoch: epoch,
            epochTimestamp: epochTimestamp?.date,
            creator: creator,
            members: members.map { $0.toAPIModel() },
            name: name,
            messageTimer: messageTimer,
            readReceiptMode: readReceiptMode,
            access: access.flatMap { Set($0) },
            accessRoles: accessRoles.flatMap { Set($0) },
            legacyAccessRole: nil,
            lastEvent: lastEvent,
            lastEventTime: lastEventTime?.date,
            groupType: groupType?.toAPIModel(),
            addPermission: addPermission?.toAPIModel(),
            cellsState: cellsState.toAPIModel()
        )
    }
}

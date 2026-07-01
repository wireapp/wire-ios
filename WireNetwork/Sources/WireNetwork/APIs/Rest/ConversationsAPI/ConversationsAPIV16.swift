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

    override func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        guard 1 ... 1000 ~= identifiers.count else {
            throw ConversationsAPIError.illegalArgument(
                message: "identifiers must contain between 1 and 1000 elements, got \(identifiers.count)"
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
            .success(code: .ok, type: QualifiedConversationListV16.self)
            .parse(code: response.statusCode, data: data)
    }

}

// MARK: - Decodables

private struct QualifiedConversationListV16: Decodable, ToAPIModelConvertible {

    enum CodingKeys: String, CodingKey {
        case found
        case notFound = "not_found"
        case failed
    }

    let found: [ConversationV16]
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

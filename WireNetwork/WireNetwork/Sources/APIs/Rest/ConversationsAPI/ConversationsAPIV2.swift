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

class ConversationsAPIV2: ConversationsAPIV1 {
    override var apiVersion: APIVersion { .v2 }

    override func getConversations(for identifiers: [QualifiedID]) async throws -> ConversationList {
        guard 1 ... 1000 ~= identifiers.count else {
            throw ConversationsAPIError.illegalArgument(
                message: "identifiers must contain between 1 and 1000 elements, got  \(identifiers.count)"
            )
        }

        let parameters = GetConversationsParametersV0(qualifiedIdentifiers: identifiers.map { $0.toNetworkModel() })
        let body = try JSONEncoder.defaultEncoder.encode(parameters)

        // New change for v2
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
            .success(code: .ok, type: QualifiedConversationListV0.self)
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .parse(code: response.statusCode, data: data)
    }

    override func createGroupConversation(
        parameters: CreateGroupConversationParameters
    ) async throws -> Conversation {
        guard parameters.groupType != .channel else {
            throw ConversationsAPIError.unsupportedChannelCreationForAPIEndpoint
        }

        let input = CreateGroupConversationParametersV2(from: parameters)
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
}

// MARK: Encodables

struct CreateGroupConversationParametersV2: Encodable {
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
    let creatorClient: String? // v2 only

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
        case creatorClient = "creator_client"
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
        self.creatorClient = parameters.creatorClientID
    }

}

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

class ConversationsAPIV4: ConversationsAPIV3 {
    override var apiVersion: APIVersion { .v4 }

    override func getConversationGuestLink(
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
            .success(code: .ok, type: ConversationCodeV4.self) // New change in v4
            .failure(
                code: .badRequest,
                label: "cnv",
                error: ConversationsAPIError.invalidConversationID
            ) // Dedicated error code in v4
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(code: .notFound, label: "no-conversation", error: ConversationsAPIError.conversationNotFound)
            .failure(
                code: .notFound,
                label: "no-conversation-code",
                error: ConversationsAPIError.conversationCodeNotFound
            )
            .failure(code: .conflict, label: "guest-links-disabled", error: ConversationsAPIError.guestLinksDisabled)
            .parse(code: response.statusCode, data: data)
    }
    
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
        guard groupType != .channel else {
            throw ConversationsAPIError.unsupportedChannelCreationForAPIEndpoint
        }
        
        let parameters = CreateGroupConversationParametersV3(
            users: messageProtocol == .proteus ? unqualifiedUserIDs : nil,
            qualifiedUsers: messageProtocol == .proteus ? qualifiedUserIDs : nil,
            access: accessMode.map(\.rawValue),
            accessRoles: accessRoles.map(\.rawValue),
            name: name,
            team: teamID.map { .init(teamID: $0) },
            messageTimer: nil,
            readReceiptMode: isReadReceiptsEnabled ? 1: 0,
            conversationRole: "wire_member",
            messageProtocol: messageProtocol.rawValue
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
        
        return try ResponseParser()
            .success(code: .ok, type: ConversationV3.self)
            .success(code: .created, type: ConversationV3.self)
            .failure(code: .badRequest, label: "mls-not-enabled", error: ConversationsAPIError.mlsNotEnabled)
            .failure(code: .badRequest, label: "non-empty-member-list", error: ConversationsAPIError.nonEmptyMemberList)
            .failure(code: .badRequest, error: ConversationsAPIError.invalidBody)
            .failure(code: .forbidden, label: "missing-legalhold-consent", error: ConversationsAPIError.missingLegalHoldConsent)
            .failure(code: .forbidden, label: "operation-denied", error: ConversationsAPIError.operationDenied)
            .failure(code: .forbidden, label: "no-team-member", error: ConversationsAPIError.noTeamMember)
            .failure(code: .forbidden, label: "not-connected", error: ConversationsAPIError.notConnected)
            .failure(code: .forbidden, label: "access-denied", error: ConversationsAPIError.accessDenied)
            .failure(code: .conflict, error: ConversationsAPIError.nonFederatingBackends) // Introduced in v4
            .failure(code: .unreachable, error: ConversationsAPIError.unreachableBackends) // Introduced in v4
            .parse(code: response.statusCode, data: data)
    }
    
}

struct ConversationCodeV4: Decodable, ToAPIModelConvertible {

    let code: String
    let hasPassword: Bool // Introduced in v4
    let key: String
    let uri: String?

    enum CodingKeys: String, CodingKey {
        case code
        case hasPassword = "has_password"
        case key
        case uri
    }

    func toAPIModel() -> String? {
        uri
    }
}

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

class TeamsAPIV0: TeamsAPI, VersionedAPI {

    let httpClient: any HTTPClient

    init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    func basePath(for teamID: Team.ID) -> String {
        "\(pathPrefix)/teams/\(teamID.transportString())"
    }

    // MARK: - Get team

    func getTeam(for teamID: Team.ID) async throws -> Team {
        let request = HTTPRequest(
            path: basePath(for: teamID),
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: TeamResponseV0.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidTeamID)
            .failure(code: .notFound, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(response)
    }

    // MARK: - Get team roles

    func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        let request = HTTPRequest(
            path: "\(basePath(for: teamID))/conversations/roles",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: ConversationRolesListResponseV0.self)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: .notFound, error: TeamsAPIError.teamNotFound)
            .parse(response)
    }

    // MARK: - Get team members

    func getTeamMembers(
        for teamID: Team.ID,
        maxResults: UInt
    ) async throws -> [TeamMember] {
        var components = URLComponents(string: "\(basePath(for: teamID))/members")
        components?.queryItems = [URLQueryItem(name: "maxResults", value: "2000")]

        guard let path = components?.url?.absoluteString else {
            throw TeamsAPIError.failedToGenerateRequest
        }

        let request = HTTPRequest(
            path: path,
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: TeamMemberListResponseV0.self)
            .failure(code: .badRequest, error: TeamsAPIError.invalidQueryParmeter)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: .notFound, error: TeamsAPIError.teamNotFound)
            .parse(response)
    }

    // MARK: - Get team member legalhold

    func getLegalhold(
        for teamID: Team.ID,
        userID: UUID
    ) async throws -> TeamMemberLegalHold {
        let request = HTTPRequest(
            path: "\(basePath(for: teamID))/legalhold/\(userID.transportString())",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: .ok, type: TeamMemberLegalHoldResponseV0.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidRequest)
            .failure(code: .notFound, label: "no-team-member", error: TeamsAPIError.teamMemberNotFound)
            .parse(response)
    }

}

struct TeamResponseV0: Decodable, ToAPIModelConvertible {

    let id: UUID
    let name: String
    let creator: UUID
    let icon: String
    let iconKey: String?
    let binding: Bool?

    enum CodingKeys: String, CodingKey {

        case id
        case name
        case creator
        case icon
        case iconKey = "icon_key"
        case binding

    }

    func toAPIModel() -> Team {
        Team(
            id: id,
            name: name,
            creatorID: creator,
            logoID: icon,
            logoKey: iconKey,
            splashScreenID: nil
        )
    }

}

struct ConversationRolesListResponseV0: Decodable, ToAPIModelConvertible {

    let conversationRoles: [ConversationRoleResponseV0]

    enum CodingKeys: String, CodingKey {
        case conversationRoles = "conversation_roles"
    }

    func toAPIModel() -> [ConversationRole] {
        conversationRoles.map { $0.toAPIModel() }
    }

}

struct ConversationRoleResponseV0: Decodable {

    let conversationRole: String?
    let actions: [ConversationActionResponseV0]

    enum CodingKeys: String, CodingKey {

        case conversationRole = "conversation_role"
        case actions

    }

    func toAPIModel() -> ConversationRole {
        ConversationRole(
            name: conversationRole ?? "unknown",
            actions: Set(actions.map {
                $0.toAPIModel()
            })
        )
    }

}

enum ConversationActionResponseV0: String, Decodable {

    case addConversationMember = "add_conversation_member"
    case removeConversationMember = "remove_conversation_member"
    case modifyConversationName = "modify_conversation_name"
    case modifyConversationMessageTimer = "modify_conversation_message_timer"
    case modifyConversationReceiptMode = "modify_conversation_receipt_mode"
    case modifyConversationAccess = "modify_conversation_access"
    case modifyOtherConversationMember = "modify_other_conversation_member"
    case leaveConversation = "leave_conversation"
    case deleteConversation = "delete_conversation"

    func toAPIModel() -> ConversationAction {
        switch self {
        case .addConversationMember:
            .addConversationMember
        case .removeConversationMember:
            .removeConversationMember
        case .modifyConversationName:
            .modifyConversationName
        case .modifyConversationMessageTimer:
            .modifyConversationMessageTimer
        case .modifyConversationReceiptMode:
            .modifyConversationReceiptMode
        case .modifyConversationAccess:
            .modifyConversationAccess
        case .modifyOtherConversationMember:
            .modifyOtherConversationMember
        case .leaveConversation:
            .leaveConversation
        case .deleteConversation:
            .deleteConversation
        }
    }

}

struct TeamMemberListResponseV0: Decodable, ToAPIModelConvertible {

    let hasMore: Bool
    let members: [TeamMemberResponseV0]

    func toAPIModel() -> [TeamMember] {
        members.map {
            $0.toAPIModel()
        }
    }

}

struct TeamMemberResponseV0: Decodable {

    let user: UUID
    let permissions: PermissionsResponseV0?
    let createdBy: UUID?
    let createdAt: UTCTimeMillis?
    let legalholdStatus: LegalholdStatusV0?

    enum CodingKeys: String, CodingKey {

        case user
        case permissions
        case createdBy = "created_by"
        case createdAt = "created_at"
        case legalholdStatus = "legalhold_status"

    }

    func toAPIModel() -> TeamMember {
        TeamMember(
            userID: user,
            creationDate: createdAt?.date,
            creatorID: createdBy,
            legalholdStatus: legalholdStatus?.toAPIModel(),
            permissions: permissions?.toAPIModel()
        )
    }

}

struct PermissionsResponseV0: Decodable {

    let copy: Int64
    let `self`: Int64

    func toAPIModel() -> TeamMemberPermissions {
        TeamMemberPermissions(
            copyPermissions: copy,
            selfPermissions: self.`self`
        )
    }

}

enum LegalholdStatusV0: String, Decodable {

    case enabled
    case pending
    case disabled
    case noConsent = "no_consent"
    
    func toAPIModel() -> LegalholdStatus {
        switch self {
        case .enabled:
            .enabled
        case .pending:
            .pending
        case .disabled:
            .disabled
        case .noConsent:
            .noConsent
        }
    }
}

struct LegalHoldLastPrekeyV0: Decodable, ToAPIModelConvertible {
    let id: Int
    let key: String
    
    func toAPIModel() -> Prekey {
        Prekey(
            id: id,
            base64EncodedKey: key
        )
    }
}

struct TeamMemberLegalHoldResponseV0: Decodable, ToAPIModelConvertible {

    let lastPrekey: LegalHoldLastPrekeyV0
    let status: LegalholdStatusV0
    
    enum CodingKeys: String, CodingKey {
        case status
        case lastPrekey = "last_prekey"
    }

    func toAPIModel() -> TeamMemberLegalHold {
        TeamMemberLegalHold(
            status: status.toAPIModel(),
            prekey: lastPrekey.toAPIModel()
        )
    }

}

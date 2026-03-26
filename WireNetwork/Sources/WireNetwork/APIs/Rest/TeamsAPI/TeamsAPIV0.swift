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

class TeamsAPIV0: TeamsAPI, VersionedAPI {

    let apiService: any APIServiceProtocol

    init(apiService: any APIServiceProtocol) {
        self.apiService = apiService
    }

    var apiVersion: APIVersion {
        .v0
    }

    func basePath(for teamID: Team.ID) -> String {
        "\(pathPrefix)/teams/\(teamID.transportString())"
    }

    // MARK: - Get team

    func getTeam(for teamID: Team.ID) async throws -> Team {
        let request = try URLRequestBuilder(path: basePath(for: teamID))
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: TeamResponseV0.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidTeamID)
            .failure(code: .notFound, label: "no-team", error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team roles

    func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        let path = "\(basePath(for: teamID))/conversations/roles"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ConversationRolesListResponseV0.self)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: .notFound, error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team members

    func getTeamMembers(
        for teamID: Team.ID,
        maxResults: UInt
    ) async throws -> [TeamMember] {
        let path = "\(basePath(for: teamID))/members"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .withQueryItem(name: "maxResults", value: "2000")
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: TeamMemberListResponseV0.self)
            .failure(code: .badRequest, error: TeamsAPIError.invalidQueryParmeter)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: .notFound, error: TeamsAPIError.teamNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get team members for ids

    func getTeamMembers(
        of teamID: Team.ID,
        for userIDs: [UUID]
    ) async throws -> [TeamMember] {
        throw TeamsAPIError.unsupportedEndpointForAPIVersion
    }

    // MARK: - Get team member legalhold

    func getLegalholdInfo(
        for teamID: Team.ID,
        userID: UUID
    ) async throws -> TeamMemberLegalholdInfo {
        let path = "\(basePath(for: teamID))/legalhold/\(userID.transportString())"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: TeamMemberLegalholdResponseV0.self)
            .failure(code: .notFound, error: TeamsAPIError.invalidRequest)
            .failure(code: .notFound, label: "no-team-member", error: TeamsAPIError.teamMemberNotFound)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Invite memeber to Team

    func inviteMemberToTeam(
        access_token: String,
        teamID: UUID,
        memberName: String,
        memberEmail: String
    ) async throws -> UUID {
        let path = "\(basePath(for: teamID))/invitations"

        let body = try JSONEncoder.defaultEncoder.encode(
            InviteMemberToTeamBodyV0(
                email: memberEmail,
                name: memberName,
                role: "member"
            )
        )

        let request = try URLRequestBuilder(path: path)
            .withMethod(.post)
            .withBody(body, contentType: .json)
            .withAcceptType(.json)
            .addingHeader(field: "Authorization", value: "Bearer \(access_token)")
            .build()

        let (data, response) = try await apiService.executeRequest(request, requiringAccessToken: false)

        let payload = try ResponseParser()
            .success(code: .created, type: InviteMemeberToTeamResponseV0.self)
            .parse(code: response.statusCode, data: data)

        return payload.id
    }

    // MARK: - Get whitelisted bots

    func getWhitelistedBots(
        for teamID: Team.ID,
        with prefix: String
    ) throws -> PayloadPager<[WhitelistedBotProfile]> {
        throw TeamsAPIError.unsupportedEndpointForAPIVersion
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
    case deleteConversation = "delete_conversation"
    case leaveConversation = "leave_conversation"
    case modifyAddPermission = "modify_add_permission"
    case modifyConversationAccess = "modify_conversation_access"
    case modifyConversationMessageTimer = "modify_conversation_message_timer"
    case modifyConversationName = "modify_conversation_name"
    case modifyConversationReceiptMode = "modify_conversation_receipt_mode"
    case modifyOtherConversationMember = "modify_other_conversation_member"
    case removeConversationMember = "remove_conversation_member"

    func toAPIModel() -> ConversationAction {
        switch self {
        case .addConversationMember:
            .addConversationMember
        case .deleteConversation:
            .deleteConversation
        case .leaveConversation:
            .leaveConversation
        case .modifyAddPermission:
            .modifyAddPermission
        case .modifyConversationAccess:
            .modifyConversationAccess
        case .modifyConversationMessageTimer:
            .modifyConversationMessageTimer
        case .modifyConversationName:
            .modifyConversationName
        case .modifyConversationReceiptMode:
            .modifyConversationReceiptMode
        case .modifyOtherConversationMember:
            .modifyOtherConversationMember
        case .removeConversationMember:
            .removeConversationMember
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

struct InviteMemeberToTeamResponseV0: Decodable, ToAPIModelConvertible {

    let id: UUID

    func toAPIModel() -> InvitationIdToJoinTeam {
        InvitationIdToJoinTeam(id: id)
    }

}

struct TeamMemberResponseV0: Decodable {

    let user: UUID
    let permissions: PermissionsResponseV0?
    let createdBy: UUID?
    let createdAt: UTCTime?
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

struct TeamMemberLegalholdResponseV0: Decodable, ToAPIModelConvertible {

    let status: LegalholdStatusV0
    let client: LegalholdClientV0?
    let lastPrekey: LegalHoldLastPrekeyV0?

    enum CodingKeys: String, CodingKey {

        case status
        case client
        case lastPrekey = "last_prekey"

    }

    func toAPIModel() -> TeamMemberLegalholdInfo {
        TeamMemberLegalholdInfo(
            status: status.toAPIModel(),
            clientID: client.map(\.id),
            prekey: lastPrekey.map { $0.toAPIModel() }
        )
    }

}

struct LegalholdClientV0: Decodable {

    let id: String

}

private struct InviteMemberToTeamBodyV0: Encodable {
    var email: String
    var name: String
    var role: String
}

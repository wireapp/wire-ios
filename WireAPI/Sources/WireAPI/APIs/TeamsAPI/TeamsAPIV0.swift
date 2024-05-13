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

class TeamsAPIV0: TeamsAPI {

    let httpClient: HTTPClient
    let decoder = ResponsePayloadDecoder(decoder: .defaultDecoder)

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    var apiVersion: APIVersion {
        .v0
    }

    func basePath(for teamID: Team.ID) -> String {
        switch apiVersion {
        case .v0:
            "/teams/\(teamID.transportString())"
        default:
            "/v\(apiVersion.rawValue)/teams/\(teamID.transportString())"
        }
    }

    // MARK: - Get team

    func getTeam(for teamID: Team.ID) async throws -> Team {
        let request = HTTPRequest(
            path: basePath(for: teamID),
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: 200, type: TeamResponseV0.self)
            .failure(code: 404, error: TeamsAPIError.invalidTeamID)
            .failure(code: 404, label: "no-team", error: TeamsAPIError.teamNotFound)
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
            .success(code: 200, type: ConversationRolesListResponseV0.self)
            .failure(code: 403, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: 404, error: TeamsAPIError.teamNotFound)
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
            .success(code: 200, type: TeamMemberListResponseV0.self)
            .failure(code: 400, error: TeamsAPIError.invalidQueryParmeter)
            .failure(code: 403, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .failure(code: 404, error: TeamsAPIError.teamNotFound)
            .parse(response)
    }

    // MARK: - Get legalhold status

    func getLegalholdStatus(
        for teamID: Team.ID,
        userID: UUID
    ) async throws -> LegalholdStatus {
        let request = HTTPRequest(
            path: "\(basePath(for: teamID))/legalhold/\(userID.transportString())",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        return try ResponseParser()
            .success(code: 200, type: LegalholdStatusResponseV0.self)
            .failure(code: 404, error: TeamsAPIError.invalidRequest)
            .failure(code: 404, label: "no-team-member", error: TeamsAPIError.teamMemberNotFound)
            .parse(response)
    }

}

struct TeamResponseV0: Decodable, ToAPIModelConvertible {

    let id: UUID
    let name: String
    let creator: UUID
    let icon: String
    let icon_key: String?
    let binding: Bool?

    func toAPIModel() -> Team {
        Team(
            id: id,
            name: name,
            creatorID: creator,
            logoID: icon,
            logoKey: icon_key,
            splashScreenID: nil
        )
    }

}

struct ConversationRolesListResponseV0: Decodable, ToAPIModelConvertible {

    let conversation_roles: [ConversationRoleResponseV0]

    func toAPIModel() -> [ConversationRole] {
        conversation_roles.map { $0.toAPIModel() }
    }

}

struct ConversationRoleResponseV0: Decodable {

    let conversation_role: String?
    let actions: [ConversationActionResponseV0]

    func toAPIModel() -> ConversationRole {
        ConversationRole(
            name: conversation_role ?? "unknown",
            actions: Set(actions.map {
                $0.toAPIModel()
            })
        )
    }

}

enum ConversationActionResponseV0: String, Decodable {

    case add_conversation_member
    case remove_conversation_member
    case modify_conversation_name
    case modify_conversation_message_timer
    case modify_conversation_receipt_mode
    case modify_conversation_access
    case modify_other_conversation_member
    case leave_conversation
    case delete_conversation

    func toAPIModel() -> ConversationAction {
        switch self {
        case .add_conversation_member:
            return .addConversationMember
        case .remove_conversation_member:
            return .removeConversationMember
        case .modify_conversation_name:
            return .modifyConversationName
        case .modify_conversation_message_timer:
            return .modifyConversationMessageTimer
        case .modify_conversation_receipt_mode:
            return .modifyConversationReceiptMode
        case .modify_conversation_access:
            return .modifyConversationAccess
        case .modify_other_conversation_member:
            return .modifyOtherConversationMember
        case .leave_conversation:
            return .leaveConversation
        case .delete_conversation:
            return .deleteConversation
        }
    }

}

struct TeamMemberListResponseV0: Decodable, ToAPIModelConvertible {

    let hasMore: Bool
    let members: [TeamMemberResponseV0]

    func toAPIModel() -> [TeamMember] {
        return members.map {
            $0.toAPIModel()
        }
    }

}

struct TeamMemberResponseV0: Decodable {

    let user: UUID
    let permissions: PermissionsResponseV0?
    let created_by: UUID?
    let created_at: Date?
    let legalhold_status: LegalholdStatusV0?

    func toAPIModel() -> TeamMember {
        TeamMember(
            userID: user,
            creationDate: created_at,
            creatorID: created_by,
            legalholdStatus: legalhold_status?.toAPIModel(),
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
    case no_consent

    func toAPIModel() -> LegalholdStatus {
        switch self {
        case .enabled:
            return .enabled
        case .pending:
            return .pending
        case .disabled:
            return .disabled
        case .no_consent:
            return .noConsent
        }
    }

}

struct LegalholdStatusResponseV0: Decodable, ToAPIModelConvertible {

    let status: LegalholdStatusV0

    func toAPIModel() -> LegalholdStatus {
        return status.toAPIModel()
    }

}

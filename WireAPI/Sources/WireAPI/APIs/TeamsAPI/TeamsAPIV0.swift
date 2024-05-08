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

public enum TeamsAPIError: Error {

    case invalidTeamID
    case teamNotFound
    case selfUserIsNotTeamMember

}

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

        switch response.code {
        case 200:
            let payload = try decoder.decodePayload(
                from: response,
                as: TeamResponseV0.self
            )

            return payload.toParent()

        default:
            let failure = try decoder.decodePayload(
                from: response,
                as: FailureResponse.self
            ) 

            switch (failure.code, failure.label) {
            case (404, ""):
                throw TeamsAPIError.invalidTeamID

            case (404, "no-team"):
                throw TeamsAPIError.teamNotFound

            default:
                throw failure
            }
        }
    }

    // MARK: - Get team roles

    func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        let request = HTTPRequest(
            path: "\(basePath(for: teamID))/conversations/roles",
            method: .get
        )

        let response = try await httpClient.executeRequest(request)

        switch response.code {
        case 200:
            let payload = try decoder.decodePayload(
                from: response,
                as: ConversationRolesListResponseV0.self
            )

            return payload.conversation_roles.map {
                $0.toParent()
            }

        default:
            let failure = try decoder.decodePayload(
                from: response,
                as: FailureResponse.self
            )

            switch (failure.code, failure.label) {
            case (403, "no-team-member"):
                throw TeamsAPIError.selfUserIsNotTeamMember

            case (404, ""):
                throw TeamsAPIError.teamNotFound

            default:
                throw failure
            }
        }
    }

}

struct TeamResponseV0: Decodable {

    let id: UUID
    let name: String
    let creator: UUID
    let icon: String
    let icon_key: String?
    let binding: Bool?

    func toParent() -> Team {
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

struct ConversationRolesListResponseV0: Decodable {

    let conversation_roles: [ConversationRoleResponseV0]

}

struct ConversationRoleResponseV0: Decodable {

    let conversation_role: String?
    let actions: [ConversationActionResponseV0]

    func toParent() -> ConversationRole {
        ConversationRole(
            name: conversation_role ?? "unknown",
            actions: Set(actions.map {
                $0.toParent()
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

    func toParent() -> ConversationAction {
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

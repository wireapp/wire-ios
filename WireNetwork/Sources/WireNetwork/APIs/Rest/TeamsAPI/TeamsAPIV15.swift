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

final class TeamsAPIV15: TeamsAPIV14 {

    override var apiVersion: APIVersion { .v15 }

    // MARK: - Get team roles

    override func getTeamRoles(for teamID: Team.ID) async throws -> [ConversationRole] {
        let path = "\(basePath(for: teamID))/conversations/roles"

        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: ConversationRolesListResponseV15.self)
            .failure(code: .forbidden, label: "no-team-member", error: TeamsAPIError.selfUserIsNotTeamMember)
            .parse(code: response.statusCode, data: data)
    }

    // MARK: - Get apps

    override func getApps(
        for teamID: Team.ID
    ) async throws -> [App] {

        let path = "\(basePath(for: teamID))/apps"
        let request = try URLRequestBuilder(path: path)
            .withMethod(.get)
            .build()

        let (data, response) = try await apiService.executeRequest(
            request,
            requiringAccessToken: true
        )

        return try ResponseParser()
            .success(code: .ok, type: GetAppsResponseV15.self)
            .parse(code: response.statusCode, data: data)

    }

}

struct ConversationRolesListResponseV15: Decodable, ToAPIModelConvertible {

    let conversationRoles: [ConversationRoleResponseV15]

    enum CodingKeys: String, CodingKey {
        case conversationRoles = "conversation_roles"
    }

    func toAPIModel() -> [ConversationRole] {
        conversationRoles.map { $0.toAPIModel() }
    }

}

struct ConversationRoleResponseV15: Decodable {

    let conversationRole: String?
    let actions: [ConversationActionResponseV15]

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

enum ConversationActionResponseV15: String, Decodable {

    case addConversationMember = "add_conversation_member"
    case deleteConversation = "delete_conversation"
    case leaveConversation = "leave_conversation"
    case modifyAddPermission = "modify_add_permission"
    case modifyConversationAccess = "modify_conversation_access"
    case modifyConversationHistory = "modify_conversation_history" // added in v15
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
        case .modifyConversationHistory:
            .modifyConversationHistory
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

private struct GetAppsResponseV15: Decodable, ToAPIModelConvertible {

    var apps: [GetAppResponseV14]

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.apps = try container.decode([GetAppResponseV14].self)
    }

    func toAPIModel() -> [App] {
        apps.map { $0.toAPIModel() }
    }

}

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
import WireAPI
import WireDataModel

/// Facilitate access to team related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.

protocol TeamRepositoryProtocol {
    
    /// Pull self team metadata frmo the server and store locally.

    func pullSelfTeam() async throws
    
    /// Pull team roles for the self team from the server and store locally.

    func pullSelfTeamRoles() async throws

    /// Pull team members for the self team from the server and store locally.

    func pullSelfTeamMembers() async throws

    ///Fetch the legalhold status for the self user from the server.

    func fetchSelfLegalholdStatus() async throws -> LegalholdStatus

}

final class TeamRepository: TeamRepositoryProtocol {

    private let selfTeamID: UUID
    private let teamsAPI: any TeamsAPI
    private let context: NSManagedObjectContext

    init(
        selfTeamID: UUID,
        teamsAPI: any TeamsAPI,
        context: NSManagedObjectContext
    ) {
        self.selfTeamID = selfTeamID
        self.teamsAPI = teamsAPI
        self.context = context
    }

    // MARK: - Pull self team

    func pullSelfTeam() async throws {
        let team = try await fetchSelfTeamRemotely()
        await storeTeamLocally(team)
    }

    private func fetchSelfTeamRemotely () async throws -> WireAPI.Team {
        do {
            return try await teamsAPI.getTeam(for: selfTeamID)
        } catch {
            throw TeamRepositoryError.failedToFetchRemotely(error)
        }
    }

    private func storeTeamLocally(_ teamAPIModel: WireAPI.Team) async {
        await context.perform { [context] in
            let team = WireDataModel.Team.fetchOrCreate(
                with: teamAPIModel.id,
                in: context
            )

            let selfUser = ZMUser.selfUser(in: context)

            _ = WireDataModel.Member.getOrUpdateMember(
                for: selfUser,
                in: team,
                context: context
            )

            team.name = teamAPIModel.name
            team.creator = ZMUser.fetchOrCreate(
                with: teamAPIModel.creatorID,
                domain: nil,
                in: context
            )
            team.pictureAssetId = teamAPIModel.logoID
            team.pictureAssetKey = teamAPIModel.logoKey
            team.needsToBeUpdatedFromBackend = false
        }
    }

    // MARK: - Pull self team roles

    func pullSelfTeamRoles() async throws {
        let teamRoles = try await fetchSelfTeamRolesRemotely()
        try await storeTeamRolesLocally(teamRoles)
    }

    private func fetchSelfTeamRolesRemotely() async throws -> [WireAPI.ConversationRole] {
        do {
            return try await teamsAPI.getTeamRoles(for: selfTeamID)
        } catch {
            throw TeamRepositoryError.failedToFetchRemotely(error)
        }
    }

    private func storeTeamRolesLocally(_ roles: [WireAPI.ConversationRole]) async throws {
        try await context.perform { [context, selfTeamID] in
            guard let team = WireDataModel.Team.fetch(
                with: selfTeamID,
                in: context
            ) else {
                throw TeamRepositoryError.teamNotFoundLocally
            }

            let existingRoles = team.roles

            let localRoles = roles.map { role in
                let localRole = Role.fetchOrCreate(
                    name: role.name,
                    teamOrConversation: .team(team),
                    context: context
                )

                localRole.name = role.name
                localRole.team = team

                for action in role.actions {
                    let action = Action.fetchOrCreate(
                        name: action.name,
                        in: context
                    )

                    localRole.actions.insert(action)
                }

                return localRole
            }

            for roleToDelete in existingRoles.subtracting(localRoles) {
                context.delete(roleToDelete)
            }

            team.needsToDownloadRoles = false
        }
    }

    // MARK: - Pull self team members

    func pullSelfTeamMembers() async throws {
        let teamMembers = try await fetchSelfTeamMembersRemotely()
        try await storeTeamMembersLocally(teamMembers)
    }

    private func fetchSelfTeamMembersRemotely() async throws -> [WireAPI.TeamMember] {
        do {
            return try await teamsAPI.getTeamMembers(
                for: selfTeamID,
                maxResults: 2000
            )
        } catch {
            throw TeamRepositoryError.failedToFetchRemotely(error)
        }
    }

    private func storeTeamMembersLocally(_ teamMembers: [WireAPI.TeamMember]) async throws {
        try await context.perform { [context, selfTeamID] in
            guard let team = WireDataModel.Team.fetch(
                with: selfTeamID,
                in: context
            ) else {
                throw TeamRepositoryError.teamNotFoundLocally
            }

            for member in teamMembers {
                let user = ZMUser.fetchOrCreate(
                    with: member.userID,
                    domain: nil,
                    in: context
                )

                let membership = Member.getOrUpdateMember(
                    for: user,
                    in: team,
                    context: context
                )

                if let permissions = member.permissions {
                    membership.permissions = Permissions(rawValue: permissions.selfPermissions)
                }

                if let creatorID = member.creatorID {
                    membership.createdBy = ZMUser.fetchOrCreate(
                        with: creatorID,
                        domain: nil,
                        in: context
                    )
                }

                membership.createdAt = member.creationDate
                membership.needsToBeUpdatedFromBackend = false
            }
        }
    }

    // MARK: - Fetch self legalhold status

    func fetchSelfLegalholdStatus() async throws -> LegalholdStatus {
        let selfUserID: UUID = await context.perform { [context] in
            ZMUser.selfUser(in: context).remoteIdentifier
        }

        return try await teamsAPI.getLegalholdStatus(
            for: selfTeamID,
            userID: selfUserID
        )
    }

}

private extension ConversationAction {

    var name: String {
        switch self {
        case .addConversationMember:
            "add_conversation_member"
        case .removeConversationMember:
            "remove_conversation_member"
        case .modifyConversationName:
            "modify_conversation_name"
        case .modifyConversationMessageTimer:
            "modify_conversation_message_timer"
        case .modifyConversationReceiptMode:
            "modify_conversation_receipt_mode"
        case .modifyConversationAccess:
            "modify_conversation_access"
        case .modifyOtherConversationMember:
            "modify_other_conversation_member"
        case .leaveConversation:
            "leave_conversation"
        case .deleteConversation:
            "delete_conversation"
        }
    }

}

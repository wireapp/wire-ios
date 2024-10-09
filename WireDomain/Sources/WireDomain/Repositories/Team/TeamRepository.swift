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

// sourcery: AutoMockable
/// Facilitate access to team related domain objects.
///
/// A repository provides an abstraction for the access and storage
/// of domain models, concealing how and where the models are stored
/// as well as the possible source(s) of the models.
public protocol TeamRepositoryProtocol {

    /// Pull self team metadata from the server and store locally.

    func pullSelfTeam() async throws

    /// Pull team roles for the self team from the server and store locally.

    func pullSelfTeamRoles() async throws

    /// Pull team members for the self team from the server and store locally.

    func pullSelfTeamMembers() async throws

    /// Fetch the legalhold for the self user from the server.

    func fetchSelfLegalhold() async throws -> TeamMemberLegalHold

    /// Deletes the member of a team.
    /// - Parameter userID: The ID of the team member.
    /// - Parameter teamID: The ID of the team.
    /// - Parameter time: The time the member left the team.

    func deleteMembership(
        forUser userID: UUID,
        fromTeam teamID: UUID,
        at time: Date
    ) async throws

    /// Sets the team member `needsToBeUpdatedFromBackend` flag to true.
    /// - Parameter membershipID: The id of the team member.

    func storeTeamMemberNeedsBackendUpdate(membershipID: UUID) async throws

    func pullSelfLegalHoldStatus() async throws

}

public final class TeamRepository: TeamRepositoryProtocol {

    // MARK: - Properties

    private let selfTeamID: UUID
    private let userRepository: any UserRepositoryProtocol
    private let teamsAPI: any TeamsAPI
    private let context: NSManagedObjectContext

    // MARK: - Object lifecycle

    public init(
        selfTeamID: UUID,
        userRepository: any UserRepositoryProtocol,
        teamsAPI: any TeamsAPI,
        context: NSManagedObjectContext
    ) {
        self.selfTeamID = selfTeamID
        self.userRepository = userRepository
        self.teamsAPI = teamsAPI
        self.context = context
    }

    // MARK: - Public

    public func pullSelfTeam() async throws {
        let team = try await fetchSelfTeamRemotely()
        await storeTeamLocally(team)
    }

    public func deleteMembership(
        forUser userID: UUID,
        fromTeam teamID: UUID,
        at time: Date
    ) async throws {
        let user = try await userRepository.fetchUser(with: userID, domain: nil)

        let member = try await context.perform {
            guard let member = user.membership else {
                throw TeamRepositoryError.userNotAMemberInTeam(user: userID, team: teamID)
            }

            return member
        }

        await userRepository.deleteUserAccount(
            for: user,
            at: time
        )

        await context.perform { [context] in
            context.delete(member)
        }
    }

    public func storeTeamMemberNeedsBackendUpdate(membershipID: UUID) async throws {
        try await context.perform { [context] in

            guard let member = Member.fetch(
                with: membershipID,
                in: context
            ) else {
                throw TeamRepositoryError.failedToFindTeamMember(membershipID)
            }

            member.needsToBeUpdatedFromBackend = true

            try context.save()
        }
    }

    public func pullSelfTeamRoles() async throws {
        let teamRoles = try await fetchSelfTeamRolesRemotely()
        try await storeTeamRolesLocally(teamRoles)
    }

    public func pullSelfTeamMembers() async throws {
        let teamMembers = try await fetchSelfTeamMembersRemotely()
        try await storeTeamMembersLocally(teamMembers)
    }

    public func pullSelfLegalHoldStatus() async throws {
        let (selfUserID, selfClientID) = await context.perform { [userRepository] in
            let selfUser = userRepository.fetchSelfUser()
            let selfUserID: UUID = selfUser.remoteIdentifier
            let selfClientID = selfUser.selfClient()?.remoteIdentifier

            return (selfUserID, selfClientID)
        }

        let selfUserLegalHold = try await fetchSelfLegalhold()

        switch selfUserLegalHold.status {
        case .pending:
            guard let selfClientID else {
                return
            }

            await userRepository.addLegalHoldRequest(
                for: selfUserID,
                clientID: selfClientID,
                lastPrekey: selfUserLegalHold.prekey
            )

        case .disabled:
            try await userRepository.disableUserLegalHold()

        default:
            break
        }
    }

    public func fetchSelfLegalhold() async throws -> TeamMemberLegalHold {
        let selfUserID: UUID = await context.perform { [userRepository] in
            userRepository.fetchSelfUser().remoteIdentifier
        }

        return try await teamsAPI.getLegalhold(
            for: selfTeamID,
            userID: selfUserID
        )
    }

    // MARK: - Private

    private func fetchSelfTeamRemotely() async throws -> WireAPI.Team {
        do {
            return try await teamsAPI.getTeam(for: selfTeamID)
        } catch {
            throw TeamRepositoryError.failedToFetchRemotely(error)
        }
    }

    private func storeTeamLocally(_ teamAPIModel: WireAPI.Team) async {
        await context.perform { [context, userRepository] in
            let team = WireDataModel.Team.fetchOrCreate(
                with: teamAPIModel.id,
                in: context
            )

            let selfUser = userRepository.fetchSelfUser()

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

    private func fetchSelfTeamMembersRemotely() async throws -> [WireAPI.TeamMember] {
        do {
            return try await teamsAPI.getTeamMembers(
                for: selfTeamID,
                maxResults: 2_000
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

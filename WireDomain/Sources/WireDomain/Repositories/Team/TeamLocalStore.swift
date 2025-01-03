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

import WireDataModel

// sourcery: AutoMockable
public protocol TeamLocalStoreProtocol {

    func fetchMember(
        id: UUID
    ) async -> Member?

    /// Fetches the self user ID.
    /// - returns: The self user ID.

    func selfUserID() async -> UUID

    /// Fetches the user membership.
    /// - parameter user: A given user.
    /// - returns: The user membership.

    func userMembership(
        user: ZMUser
    ) async -> Member?

    /// Fetches the user domain.
    /// - parameter user: A given user.
    /// - returns: The user domain.

    func userDomain(
        user: ZMUser
    ) async -> String?

    /// Deletes the member locally.
    /// - parameter member: A given member.

    func deleteMember(
        _ member: Member
    ) async

    /// Stores a flag whether the member needs backend update.
    /// - parameters:
    ///     - needsBackendUpdate: The flag to update.
    ///     - member: A given member.

    func storeMember(
        needsBackendUpdate: Bool,
        member: Member
    ) async

    /// Stores a team locally.
    /// - Parameters:
    ///     - id: The team ID.
    ///     - name: The team name.
    ///     - creatorID: The team creator ID.
    ///     - logoID: The team logo ID.
    ///     - logoKey: The team logo key.

    func storeTeam(
        id: UUID,
        name: String,
        creatorID: UUID,
        logoID: String?,
        logoKey: String?
    ) async

    /// Stores team roles locally.
    /// - parameters:
    ///     - selfTeamID: The self team ID.
    ///     - teamRolesInfo: A list of role and actions.

    func storeTeamRoles(
        selfTeamID: UUID,
        teamRolesInfo: [TeamRoleInfo]
    ) async throws

    /// Stores team members locally.
    /// - parameters:
    ///     - selfTeamID: The self team ID.
    ///     - teamMembersInfo: A list of member info (id, permission, creator id, date)

    func storeTeamMembers(
        selfTeamID: UUID,
        teamMembersInfo: [TeamMemberInfo]
    ) async throws

    /// Fetches self user info : user ID and client ID.
    /// - returns: the user ID and the client ID.

    func selfUserInfo() async -> (id: UUID, clientId: String?)
}

public final class TeamLocalStore: TeamLocalStoreProtocol {

    // MARK: - Error

    enum Error: Swift.Error {
        /// The local team instance was not found in the database.

        case teamNotFoundLocally
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let userLocalStore: any UserLocalStoreProtocol

    // MARK: - Object lifecycle

    public init(
        context: NSManagedObjectContext,
        userLocalStore: any UserLocalStoreProtocol
    ) {
        self.context = context
        self.userLocalStore = userLocalStore
    }

    // MARK: - Public

    public func fetchMember(
        id: UUID
    ) async -> Member? {
        await context.perform { [context] in
            Member.fetch(
                with: id,
                in: context
            )
        }
    }

    public func selfUserID() async -> UUID {
        let selfUser = await userLocalStore.fetchSelfUser()

        return await context.perform {
            selfUser.remoteIdentifier
        }
    }

    public func userMembership(
        user: ZMUser
    ) async -> Member? {
        await context.perform {
            user.membership
        }
    }

    public func userDomain(
        user: ZMUser
    ) async -> String? {
        await context.perform {
            user.domain
        }
    }

    public func deleteMember(
        _ member: Member
    ) async {
        await context.perform { [context] in
            context.delete(member)
        }
    }

    public func storeMember(
        needsBackendUpdate: Bool,
        member: Member
    ) async {
        await context.perform { [context] in
            member.needsToBeUpdatedFromBackend = true
            context.saveOrRollback()
        }
    }

    public func storeTeam(
        id: UUID,
        name: String,
        creatorID: UUID,
        logoID: String?,
        logoKey: String?
    ) async {
        let selfUser = await userLocalStore.fetchSelfUser()

        await context.perform { [context] in
            let team = WireDataModel.Team.fetchOrCreate(
                with: id,
                in: context
            )

            _ = WireDataModel.Member.getOrUpdateMember(
                for: selfUser,
                in: team,
                context: context
            )

            team.name = name
            team.creator = ZMUser.fetchOrCreate(
                with: creatorID,
                domain: nil,
                in: context
            )
            team.pictureAssetId = logoID
            team.pictureAssetKey = logoKey
            team.needsToBeUpdatedFromBackend = false
        }
    }

    public func storeTeamRoles(
        selfTeamID: UUID,
        teamRolesInfo: [TeamRoleInfo]
    ) async throws {
        try await context.perform { [context, selfTeamID] in
            guard let team = WireDataModel.Team.fetch(
                with: selfTeamID,
                in: context
            ) else {
                throw Error.teamNotFoundLocally
            }

            let existingRoles = team.roles

            let localRoles = teamRolesInfo.map { teamRoleInfo in
                let localRole = WireDataModel.Role.fetchOrCreate(
                    name: teamRoleInfo.role,
                    teamOrConversation: .team(team),
                    context: context
                )

                localRole.name = teamRoleInfo.role
                localRole.team = team

                for action in teamRoleInfo.actions {
                    let action = Action.fetchOrCreate(
                        name: action,
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

    public func storeTeamMembers(
        selfTeamID: UUID,
        teamMembersInfo: [TeamMemberInfo]
    ) async throws {
        try await context.perform { [context, selfTeamID] in
            guard let team = WireDataModel.Team.fetch(
                with: selfTeamID,
                in: context
            ) else {
                throw Error.teamNotFoundLocally
            }

            for teamMemberInfo in teamMembersInfo {
                let user = ZMUser.fetchOrCreate(
                    with: teamMemberInfo.id,
                    domain: nil,
                    in: context
                )

                let membership = Member.getOrUpdateMember(
                    for: user,
                    in: team,
                    context: context
                )

                if let selfPermission = teamMemberInfo.selfPermission {
                    membership.permissions = Permissions(rawValue: selfPermission)
                }

                if let creatorID = teamMemberInfo.creatorID {
                    membership.createdBy = ZMUser.fetchOrCreate(
                        with: creatorID,
                        domain: nil,
                        in: context
                    )
                }

                membership.createdAt = teamMemberInfo.creationDate
                membership.needsToBeUpdatedFromBackend = false
            }
        }
    }

    public func selfUserInfo() async -> (id: UUID, clientId: String?) {
        await userLocalStore.selfUserInfo()
    }

}

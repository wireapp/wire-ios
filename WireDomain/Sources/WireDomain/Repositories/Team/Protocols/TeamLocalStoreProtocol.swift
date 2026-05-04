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
import WireDataModel

// sourcery: AutoMockable
public protocol TeamLocalStoreProtocol {

    func fetchMember(
        id: UUID
    ) async -> Member?

    /// Fetches the self user ID.
    /// - returns: The self user ID.

    func selfUserID() async -> UUID

    /// Fetches the self team ID, if it exist.
    /// - returns: The id of the self user's team.

    func selfTeamID() async -> UUID?

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

    /// Creates or updates a team locally.
    /// - Parameters
    ///     - identifier: The team ID.
    ///     - name: The team name.
    ///     - creator: The team creator.
    ///     - icon: The team icon.
    ///     - iconKey: The team iconKey.

    func createOrUpdateTeam(
        identifier: UUID,
        name: String,
        creator: UUID,
        icon: String,
        iconKey: String?
    ) async
}

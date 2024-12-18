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

    /// Fetches the legalhold info for the self user from the server.
    /// - returns: The legalhold info.

    func fetchSelfLegalholdInfo() async throws -> TeamMemberLegalholdInfo

    /// Deletes the member of a team.
    /// - Parameter userID: The ID of the team member.
    /// - Parameter domain: The domain of the team member.
    /// - Parameter date: The time the member left the team.

    func deleteMembership(
        userID: UUID,
        domain: String?,
        date: Date
    ) async throws

    /// Sets the team member `needsToBeUpdatedFromBackend` flag to true.
    /// - Parameter membershipID: The id of the team member.

    func storeTeamMemberNeedsBackendUpdate(
        membershipID: UUID
    ) async throws

    /// Pulls and stores legalhold info locally.

    func pullSelfLegalholdInfo() async throws

}

public class TeamRepository: TeamRepositoryProtocol {

    // MARK: - Properties

    private let selfTeamID: UUID
    private let userRepository: any UserRepositoryProtocol
    private let teamsAPI: any TeamsAPI
    private let teamLocalStore: any TeamLocalStoreProtocol

    private let pullSelfTeamSync: PullSelfTeamSync

    // MARK: - Object lifecycle

    public init(
        selfTeamID: UUID,
        userRepository: any UserRepositoryProtocol,
        teamLocalStore: any TeamLocalStoreProtocol,
        teamsAPI: any TeamsAPI
    ) {
        self.selfTeamID = selfTeamID
        self.userRepository = userRepository
        self.teamLocalStore = teamLocalStore
        self.teamsAPI = teamsAPI
        self.pullSelfTeamSync = PullSelfTeamSync(
            api: teamsAPI,
            store: teamLocalStore
        )
    }

    // MARK: - Public

    public func pullSelfTeam() async throws {
        try await pullSelfTeamSync.pull(selfTeamID: selfTeamID)
    }

    public func pullSelfTeamRoles() async throws {
        let teamRoles = try await fetchSelfTeamRolesRemotely()

        let teamRolesInfo = teamRoles.map {
            $0.toDomainModel()
        }

        try await teamLocalStore.storeTeamRoles(
            selfTeamID: selfTeamID,
            teamRolesInfo: teamRolesInfo
        )
    }

    public func pullSelfTeamMembers() async throws {
        let teamMembers = try await fetchSelfTeamMembersRemotely()

        let teamMembersInfo = teamMembers.map {
            $0.toDomainModel()
        }

        try await teamLocalStore.storeTeamMembers(
            selfTeamID: selfTeamID,
            teamMembersInfo: teamMembersInfo
        )
    }

    public func fetchSelfLegalholdStatus() async throws -> LegalholdStatus {
        let selfUserID = await teamLocalStore.selfUserID()

        return try await teamsAPI.getLegalholdInfo(
            for: selfTeamID,
            userID: selfUserID
        ).status
    }

    public func deleteMembership(
        userID: UUID,
        domain: String?,
        date: Date
    ) async throws {
        let user = try await userRepository.fetchUser(
            id: userID,
            domain: domain
        )

        guard let member = await teamLocalStore.userMembership(
            user: user
        ) else {
            throw TeamRepositoryError.userNotAMemberInTeam(user: userID)
        }

        let domain = await teamLocalStore.userDomain(user: user)

        try await userRepository.deleteUserAccount(
            id: userID,
            domain: domain,
            at: date
        )

        await teamLocalStore.deleteMember(member)
    }

    public func storeTeamMemberNeedsBackendUpdate(membershipID: UUID) async throws {
        guard let member = await teamLocalStore.fetchMember(
            id: membershipID
        ) else {
            throw TeamRepositoryError.failedToFindTeamMember(membershipID)
        }

        await teamLocalStore.storeMember(
            needsBackendUpdate: true,
            member: member
        )
    }

    public func pullSelfLegalholdInfo() async throws {
        let selfUser = await userRepository.fetchSelfUser()

        let (selfUserID, selfClientID) = await teamLocalStore.selfUserInfo()

        let selfUserLegalHold = try await fetchSelfLegalholdInfo()

        switch selfUserLegalHold.status {
        case .pending:
            guard let selfClientID else {
                return
            }

            await userRepository.addLegalHoldRequest(
                userID: selfUserID,
                clientID: selfClientID,
                lastPrekey: selfUserLegalHold.prekey
            )

        case .disabled:
            await userRepository.disableUserLegalHold()

        default:
            break
        }
    }

    public func fetchSelfLegalholdInfo() async throws -> TeamMemberLegalholdInfo {
        let (selfUserID, _) = await teamLocalStore.selfUserInfo()

        return try await teamsAPI.getLegalholdInfo(
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

    private func fetchSelfTeamRolesRemotely() async throws -> [WireAPI.ConversationRole] {
        do {
            return try await teamsAPI.getTeamRoles(for: selfTeamID)
        } catch {
            throw TeamRepositoryError.failedToFetchRemotely(error)
        }
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

}

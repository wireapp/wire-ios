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
import WireNetwork

public class TeamRepository: TeamRepositoryProtocol {

    // MARK: - Properties

    private let userRepository: any UserRepositoryProtocol
    private let teamsAPI: any TeamsAPI
    private let teamLocalStore: any TeamLocalStoreProtocol

    private let pullSelfTeamSync: PullSelfTeamSync
    private let pullSelfTeamRolesSync: PullSelfTeamRolesSync
    private let pullSelfTeamMembersSync: PullSelfTeamMembersSync

    // MARK: - Object lifecycle

    public init(
        userRepository: any UserRepositoryProtocol,
        teamLocalStore: any TeamLocalStoreProtocol,
        teamsAPI: any TeamsAPI
    ) {
        self.userRepository = userRepository
        self.teamLocalStore = teamLocalStore
        self.teamsAPI = teamsAPI
        self.pullSelfTeamSync = PullSelfTeamSync(
            api: teamsAPI,
            store: teamLocalStore
        )
        self.pullSelfTeamRolesSync = PullSelfTeamRolesSync(
            api: teamsAPI,
            store: teamLocalStore
        )
        self.pullSelfTeamMembersSync = PullSelfTeamMembersSync(
            api: teamsAPI,
            store: teamLocalStore
        )
    }

    // MARK: - Public

    public func pullSelfTeam() async throws {
        let selfTeamID = try await getSelfTeamID()
        try await pullSelfTeamSync.pull(selfTeamID: selfTeamID)
    }

    public func pullSelfTeamRoles() async throws {
        let selfTeamID = try await getSelfTeamID()
        try await pullSelfTeamRolesSync.pull(selfTeamID: selfTeamID)
    }

    public func pullSelfTeamMembers() async throws {
        let selfTeamID = try await getSelfTeamID()
        try await pullSelfTeamMembersSync.pull(selfTeamID: selfTeamID)
    }

    public func fetchSelfLegalholdStatus() async throws -> LegalholdStatus {
        let selfTeamID = try await getSelfTeamID()
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
        let (selfUserID, _) = await teamLocalStore.selfUserInfo()
        let selfUserLegalHold = try await fetchSelfLegalholdInfo()

        switch selfUserLegalHold.status {
        case .pending:
            guard
                let clientID = selfUserLegalHold.clientID,
                let lastPrekey = selfUserLegalHold.prekey
            else {
                return
            }

            await userRepository.addLegalHoldRequest(
                userID: selfUserID,
                clientID: clientID,
                lastPrekey: lastPrekey
            )

        case .disabled:
            await userRepository.disableUserLegalHold()

        default:
            break
        }
    }

    public func fetchSelfLegalholdInfo() async throws -> TeamMemberLegalholdInfo {
        let selfTeamID = try await getSelfTeamID()
        let (selfUserID, _) = await teamLocalStore.selfUserInfo()

        return try await teamsAPI.getLegalholdInfo(
            for: selfTeamID,
            userID: selfUserID
        )
    }

    public func createOrUpdateTeam(
        identifier: UUID,
        name: String,
        creator: UUID,
        icon: String,
        iconKey: String?
    ) async {
        await teamLocalStore.createOrUpdateTeam(
            identifier: identifier,
            name: name,
            creator: creator,
            icon: icon,
            iconKey: iconKey
        )
    }

    // MARK: - Private

    private func getSelfTeamID() async throws -> UUID {
        guard let selfTeamID = await teamLocalStore.selfTeamID() else {
            throw TeamRepositoryError.selfUserIsNotATeamMember
        }
        return selfTeamID
    }

}

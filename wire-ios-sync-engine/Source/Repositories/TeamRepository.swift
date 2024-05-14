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

enum TeamRepositoryError: Error {

    case failedToFetchRemotely(Error)

}

protocol TeamRepositoryProtocol {

    func fetchSelfTeam() async throws

}

// TODO: document
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

    // MARK: - Fetch self team

    func fetchSelfTeam() async throws {
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

}

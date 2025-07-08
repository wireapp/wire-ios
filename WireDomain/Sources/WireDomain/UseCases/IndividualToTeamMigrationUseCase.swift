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

import Foundation
import WireDataModel
import WireDomainPackage
import WireLogging
import WireNetwork
import WireSystem

public struct IndividualToTeamMigrationUseCase: IndividualToTeamMigrationUseCaseProtocol {

    private let accountsAPI: AccountsAPI
    private let context: NSManagedObjectContext
    private let logger: WireLogger = .individualToTeamMigration

    public init(
        accountsAPI: AccountsAPI,
        context: NSManagedObjectContext
    ) {
        self.accountsAPI = accountsAPI
        self.context = context
    }

    public func invoke(teamName: String) async throws -> IndividualToTeamMigrationResult {
        logger.debug("Migrating individual account to team account")
        do {
            let upgradeResult = try await accountsAPI.upgradeToTeam(teamName: teamName)
            logger.debug("Individual account migrated to team account, storing team locally...")
            try await createTeamLocally(id: upgradeResult.teamId, name: upgradeResult.teamName)
            logger.debug("Individual to team migration completed successfully")
            return IndividualToTeamMigrationResult(teamID: upgradeResult.teamId, teamName: upgradeResult.teamName)
        } catch {
            logger.error("Failed to migrate individual account to team account: \(error.localizedDescription)")
            switch error {
            case AccountsAPIError.userAlreadyInATeam:
                throw IndividualToTeamMigrationError.userAlreadyInTeam
            default:
                throw IndividualToTeamMigrationError.generic(error)
            }
        }
    }

    private func createTeamLocally(
        id: UUID,
        name: String
    ) async throws {
        try await context.perform { [context] in
            let team = Team.fetchOrCreate(
                with: id,
                in: context
            )

            team.name = name
            team.needsToBeUpdatedFromBackend = true

            // Probably there's nothing to fetch since it's a brand
            // new team, but just in case.
            team.needsToDownloadRoles = true
            team.needsToRedownloadMembers = true

            let selfUser = ZMUser.selfUser(in: context)

            _ = Member.getOrUpdateMember(
                for: selfUser,
                in: team,
                context: context
            )

            try context.save()
        }
    }
}

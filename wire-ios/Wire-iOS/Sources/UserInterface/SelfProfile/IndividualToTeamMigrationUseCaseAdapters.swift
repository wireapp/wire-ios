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

import WireDomain
import WireIndividualToTeamMigrationUI

// These adapters are required because WireDomain is an Xcode project and contains the protocol, result+error types and
// the implementation of the `IndividualToTeamMigrationUseCase` while WireUI is a Swift package and cannot depend on
// Xcode projects. Therefore the types are duplicated and these adapters bridge from WireDomain to
// WireIndividualToTeamMigrationUI.

struct IndividualToTeamMigrationUseCaseAdapter: WireIndividualToTeamMigrationUI
    .IndividualToTeamMigrationUseCaseProtocol {

    let individualToTeamMigrationUseCase: any WireDomain.IndividualToTeamMigrationUseCaseProtocol

    init(_ individualToTeamMigrationUseCase: any WireDomain.IndividualToTeamMigrationUseCaseProtocol) {
        self.individualToTeamMigrationUseCase = individualToTeamMigrationUseCase
    }

    func invoke(teamName: String) async throws -> WireIndividualToTeamMigrationUI.IndividualToTeamMigrationResult {
        do {
            let result = try await individualToTeamMigrationUseCase.invoke(teamName: teamName)
            return WireIndividualToTeamMigrationUI.IndividualToTeamMigrationResult(result)
        } catch let error as WireDomain.IndividualToTeamMigrationError {
            throw WireIndividualToTeamMigrationUI.IndividualToTeamMigrationError(error)
        }
    }

}

extension WireIndividualToTeamMigrationUI.IndividualToTeamMigrationResult {

    init(_ result: WireDomain.IndividualToTeamMigrationResult) {
        self.init(
            teamID: result.teamID,
            teamName: result.teamName
        )
    }

}

extension WireIndividualToTeamMigrationUI.IndividualToTeamMigrationError {

    init(_ error: WireDomain.IndividualToTeamMigrationError) {
        switch error {
        case .userAlreadyInTeam:
            self = .userAlreadyInTeam
        case let .generic(error):
            self = .generic(error)
        }
    }

}

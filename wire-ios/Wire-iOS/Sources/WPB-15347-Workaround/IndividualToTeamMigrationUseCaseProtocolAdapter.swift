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
import WireAnalytics
import WireDomainPkg
import WireIndividualToTeamMigrationUI

// TODO: [WPB-15347] delete this workaround

// Instead of linking WireDomainPkg into WireUI targets several symlinks have been created.
// Therefore many types exist twice, once in their original target (WireDomainPkg) and once in WireUI.
typealias IndividualToTeamMigrationError = WireDomainPkg.IndividualToTeamMigrationError
typealias IndividualToTeamMigrationResult = WireDomainPkg.IndividualToTeamMigrationResult
typealias IndividualToTeamMigrationUseCaseProtocol = WireDomainPkg.IndividualToTeamMigrationUseCaseProtocol
struct IndividualToTeamMigrationUseCaseProtocolAdapter: WireIndividualToTeamMigrationUI
    .IndividualToTeamMigrationUseCaseProtocol {

    private let individualToTeamMigrationUseCase: any IndividualToTeamMigrationUseCaseProtocol

    fileprivate init(_ individualToTeamMigrationUseCase: any IndividualToTeamMigrationUseCaseProtocol) {
        self.individualToTeamMigrationUseCase = individualToTeamMigrationUseCase
    }

    func invoke(teamName: String) async throws -> WireIndividualToTeamMigrationUI.IndividualToTeamMigrationResult {
        do {
            let result = try await individualToTeamMigrationUseCase.invoke(teamName: teamName)
            return .init(result)
        } catch let error as IndividualToTeamMigrationError {
            switch error {
            case .userAlreadyInTeam:
                throw WireIndividualToTeamMigrationUI.IndividualToTeamMigrationError.userAlreadyInTeam
            case let .generic(error):
                throw WireIndividualToTeamMigrationUI.IndividualToTeamMigrationError.generic(error)
            }
        }
    }

}

func IndividualToTeamMigrationViewController(
    privacyPolicyURL: String,
    termsOfUseURL: String,
    useCase: any IndividualToTeamMigrationUseCaseProtocol,
    userProfileName: String,
    analyticsEventTracker: (any AnalyticsEventTracker)?,
    actionCallback: @escaping (IndividualToTeamMigrationViewController.Action) -> Void
) -> WireIndividualToTeamMigrationUI.IndividualToTeamMigrationViewController {

    let useCase = IndividualToTeamMigrationUseCaseProtocolAdapter(useCase)

    return .init(
        privacyPolicyURL: privacyPolicyURL,
        termsOfUseURL: termsOfUseURL,
        useCase: useCase,
        userProfileName: userProfileName,
        analyticsEventTracker: analyticsEventTracker,
        actionCallback: actionCallback
    )

}

extension WireIndividualToTeamMigrationUI.IndividualToTeamMigrationResult {

    init(_ migrationResult: IndividualToTeamMigrationResult) {
        self.init(
            teamID: migrationResult.teamID,
            teamName: migrationResult.teamName
        )
    }
}

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

import SwiftUI
import WireDomainPackage

public struct MockUseCase: IndividualToTeamMigrationUseCaseProtocol {
    let error: (any Error)?

    private init(error: (any Error)? = nil) {
        self.error = error
    }

    public func invoke(teamName: String) async throws -> IndividualToTeamMigrationResult {
        try await Task.sleep(nanoseconds: NSEC_PER_SEC * 5)
        if let error { throw error }
        return IndividualToTeamMigrationResult(teamID: UUID(), teamName: teamName)
    }

    public static func success() -> MockUseCase {
        MockUseCase()
    }

    static func alreadyInTeam() -> MockUseCase {
        MockUseCase(error: IndividualToTeamMigrationError.userAlreadyInTeam)
    }

    static func genericFailure(error: any Error) -> MockUseCase {
        MockUseCase(error: IndividualToTeamMigrationError.generic(error))
    }
}

private struct FeaturePreviewContainer: UIViewControllerRepresentable {

    typealias UIViewControllerType = IndividualToTeamMigrationViewController
    let features: [TeamPlanFeature]

    func makeUIViewController(context: Context) -> IndividualToTeamMigrationViewController {

        IndividualToTeamMigrationViewController(
            features: features,
            privacyPolicyURL: "https://wire.com/privacy-policy",
            termsOfUseURL: "https://wire.com/en/terms-of-use-business",
            useCase: MockUseCase.success(),
            userProfileName: "Some User",
            analyticsEventTracker: nil,
            actionCallback: { _ in }
        )
    }

    func updateUIViewController(_ uiViewController: IndividualToTeamMigrationViewController, context: Context) {
        // Updates the state of the specified view controller with new information from SwiftUI.
    }
}

@MainActor
@ViewBuilder
func featurePreview() -> some View {
    FeaturePreviewContainer(features: .features)
}

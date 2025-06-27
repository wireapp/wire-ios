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

// TODO: delete if not needed

import WireDomainPackage
import WireIndividualToTeamMigrationUI
import UIKit

struct PersonalToTeamMigrationBuilder {

    var privacyPolicyURL = WireURLs.shared.privacyPolicy
    var termsOfUseURL = WireURLs.shared.legal
    var useCase: any IndividualToTeamMigrationUseCaseProtocol
    var userProfileName: String
    var analyticsEventTracker: (any AccountMigrationAnalyticsTrackerProtocol)?
    var actionCallback: @Sendable (IndividualToTeamMigrationViewController.Action) -> Void

    func build() -> UIViewController {
        IndividualToTeamMigrationViewController(
            privacyPolicyURL: privacyPolicyURL.absoluteString,
            termsOfUseURL: termsOfUseURL.absoluteString,
            useCase: useCase,
            userProfileName: userProfileName,
            analyticsEventTracker: analyticsEventTracker,
            actionCallback: actionCallback
        )
    }

}

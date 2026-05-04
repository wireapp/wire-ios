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

import WireFoundation
import WireIndividualToTeamMigrationUI

struct AccountMigrationAnalyticsTracker: AccountMigrationAnalyticsTrackerProtocol {

    let analyticsEventTracker: any AnalyticsEventTrackerProtocol

    func trackMigrationReachedDisclaimerStep() {
        analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowStarted(at: .disclaimer))
    }

    func trackMigrationReachedTeamNameStep() {
        analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowStarted(at: .teamName))
    }

    func trackMigrationReachedConfirmationStep() {
        analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowStarted(at: .confirmation))
    }

    func trackMigrationDroppedAtDisclaimerStep() {
        analyticsEventTracker.trackEvent(.User.personalToTeamMigrationFlowStopped(at: .disclaimer))
    }

    func trackMigrationDroppedAtTeamNameStep() {
        analyticsEventTracker.trackEvent(.User.personalToTeamMigrationFlowStopped(at: .teamName))
    }

    func trackMigrationDroppedAtConfirmationStep() {
        analyticsEventTracker.trackEvent(.User.personalToTeamMigrationFlowStopped(at: .confirmation))
    }

    func trackMigrationCancelAttempt(choice: CancelAccountMigrationChoice) {
        switch choice {
        case .confirm:
            analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowCancel(action: .leave))
        case .backOut:
            analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowCancel(action: .continue))
        }
    }

    func trackMigrationCompleted(postAction: PostAccountMigrationAction?) {
        switch postAction {
        case .returnToApp:
            analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowCompleted(action: .backToWire))
        case .openTeamManagement:
            analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowCompleted(action: .openTeamManagement))
        case .none:
            analyticsEventTracker.trackEvent(.User.personalTeamCreationFlowCompleted(action: .none))
        }
    }

}

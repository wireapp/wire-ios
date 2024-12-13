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

import WireAnalytics

extension AnalyticsEvent.User {

    /// Count of user reaching for each modal step (Step 1 through 3)
    ///
    /// Segmentation: app_name; app_version

    static func personalTeamCreationFlowStarted(
        step: IndividualToTeamMigrationViewController.Step
    ) -> AnalyticsEvent! {

        let index: Int
        switch step {
        case .teamPlanSelection:
            index = 1
        case .teamName:
            index = 2
        case .confirmation:
            index = 3
        case .completion:
            return .none
        }

        return AnalyticsEvent("user.personal-team-creation-flow-started") {
            SegmentationEntry("step_modalcreateteam", index)
        }
    }

    static func personalToTeamMigrationFlowStopped(
        at step: IndividualToTeamMigrationViewController.Step
    ) -> AnalyticsEvent! {
        switch step {
        case .teamPlanSelection:
            personalTeamCreationFlowStopped(atDisclaimersStep: true, atTeamNameStep: false, atConfirmationStep: false)
        case .teamName:
            personalTeamCreationFlowStopped(atDisclaimersStep: false, atTeamNameStep: true, atConfirmationStep: false)
        case .confirmation:
            personalTeamCreationFlowStopped(atDisclaimersStep: false, atTeamNameStep: false, atConfirmationStep: true)
        case .completion:
            .none
        }
    }

    /// Count of user dropping at each modal step (Step 1 through 3)
    ///
    /// Segmentation: app_name; app_version; modal_disclaimers; modal_team-name; modal_confirmation

    private static func personalTeamCreationFlowStopped(
        atDisclaimersStep: Bool,
        atTeamNameStep: Bool,
        atConfirmationStep: Bool
    ) -> AnalyticsEvent {
        AnalyticsEvent("user.personal-team-creation-flow-stopped") {
            if atDisclaimersStep {
                SegmentationEntry("modal_disclaimers", true)
            }
            if atTeamNameStep {
                SegmentationEntry("modal_team-name", true)
            }
            if atConfirmationStep {
                SegmentationEntry("modal_confirmation", true)
            }
        }
    }

    /// Count of user reaching the cancellation modal
    ///
    /// Segmentation: app_name; app_version; modal_continue-clicked; modal_leave-clicked

    static func personalTeamCreationFlowCancel(
        tappedContinueButton: Bool,
        tappedLeaveButton: Bool
    ) -> AnalyticsEvent {
        AnalyticsEvent("user.personal-team-creation-flow-cancelled") {
            if tappedContinueButton {
                SegmentationEntry("modal_continue-clicked", true)
            }
            if tappedLeaveButton {
                SegmentationEntry("modal_leave-clicked", true)
            }
        }
    }

    /// Count of user reach the final stage (Step 4)
    ///
    /// Segmentation: app_name; app_version; modal_back-to-wire-clicked; modal_open-tm-clicked

    static func personalTeamCreationFlowCompleted(
        usingBackToWireButton: Bool,
        usingGoToTeamManagementButton: Bool
    ) -> AnalyticsEvent {
        AnalyticsEvent("user.personal-team-creation-flow-completed") {
            if usingBackToWireButton {
                SegmentationEntry("modal_back-to-wire-clicked", true)
            }
            if usingGoToTeamManagementButton {
                SegmentationEntry("modal_open-tm-clicked", true)
            }
        }
    }
}

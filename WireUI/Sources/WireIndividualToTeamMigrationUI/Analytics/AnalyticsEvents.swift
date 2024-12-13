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

    /// Count of user dropping at each modal step (Step 1 through 3)
    ///
    /// Segmentation: app_name; app_version; modal_disclaimers; modal_team-name; modal_confirmation

    static func personalTeamCreationFlowStopped( // TODO: implement
        teamName: String,
        todo_modal_disclaimers: Void,
        todo_modal_confirmation: Void
    ) -> AnalyticsEvent { // TODO: implement
        fatalError("user.personal-team-creation-flow-stopped")
    }

    /// Count of user reaching the cancellation modal
    ///
    /// Segmentation: app_name; app_version; modal_continue-clicked; modal_leave-clicked

    static func personalTeamCreationFlowCancelled( // TODO: implement
        teamName: String,
        modalLeaveClicked: Bool,
        modalContinueClicked: Bool // TODO: rename arguments properly
    ) -> AnalyticsEvent {
        AnalyticsEvent("user.personal-team-creation-flow-cancelled") {
            SegmentationEntry("modal_team-name", teamName)
            SegmentationEntry("modal_leave-clicked", modalLeaveClicked)
            SegmentationEntry("modal_continue-clicked", modalContinueClicked)
        }
    }

    /// Count of user reach the final stage (Step 4)
    ///
    /// Segmentation: app_name; app_version; modal_back-to-wire-clicked; modal_open-tm-clicked

    static func personalTeamCreationFlowCompleted(
        teamName: String,
        modalOpenTeamManagementButtonClicked: Bool, // TODO: rename arguments properly
        backToWireButtonClicked: Bool
    ) -> AnalyticsEvent {
        AnalyticsEvent("user.personal-team-creation-flow-completed") {
            SegmentationEntry("modal_team-name", teamName)
            SegmentationEntry("modal_open-tm-clicked", modalOpenTeamManagementButtonClicked)
            SegmentationEntry("modal_back-to-wire-clicked", backToWireButtonClicked)
        }
    }
}

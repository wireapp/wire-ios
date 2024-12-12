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

public extension AnalyticsEvent.UI {

    /// Tap on the Notification dot to see the CTA.
    ///
    /// Segmentation: app_name; app_version; migration_dot_active;

    static func clickedProfile(isMigrationDotActive: Bool) -> AnalyticsEvent { // TODO: implement
        AnalyticsEvent("ui.clicked-profile") {
            SegmentationEntry("migration_dot_active", isMigrationDotActive)
        }
    }

    /// Tap on the create a team CTA
    ///
    /// Segmentation: app_name; app_version; clicked_create_team; clicked_dismiss_cta

    static func triggeredPersonalMigrationCTA(
        isCreateTeamButtonUsed: Bool,
        isDismissCTAButtonUsed: Bool
    ) -> AnalyticsEvent {
        AnalyticsEvent("ui.clicked-personal-migration-cta") {
            SegmentationEntry("clicked_create_team", isCreateTeamButtonUsed)
            SegmentationEntry("clicked_dismiss_cta", isDismissCTAButtonUsed)
        }
    }
}

public extension AnalyticsEvent.User {

    /// Count of user reaching for each modal step (Step 1 through 3)
    ///
    /// Segmentation: app_name; app_version

    static func personalTeamCreationFlowStarted(step: Int) -> AnalyticsEvent {
        AnalyticsEvent("user.personal-team-creation-flow-started") {
            SegmentationEntry("step_modalcreateteam", step)
        }
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

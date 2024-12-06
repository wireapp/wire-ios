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

extension AnalyticsEvent.UI {

    /// Tap on the Notification dot to see the CTA.
    ///
    /// Segmentation: app_name; app_version; migration_dot_active;

    static let clickedProfile = AnalyticsEvent(name: "ui.clicked-profile")

    /// Tap on the create a team CTA
    ///
    /// Segmentation: app_name; app_version; clicked_create_team; clicked_dismiss_cta

    static let clickedPersonalMigrationCTA = AnalyticsEvent(name: "ui.clicked-personal-migration-cta")

    /// Count of user reaching for each modal step (Step 1 through 3)
    ///
    /// Segmentation: app_name; app_version

    static let clickedPersonalMigrationCTA = AnalyticsEvent(name: "user.personal-team-creation-flow-started")

    /// Count of user dropping for at each modal step (Step 1 through 3)
    ///
    /// Segmentation: app_name; app_version; modal_disclaimers; modal_team-name; modal_confirmation

    static let clickedPersonalMigrationCTA = AnalyticsEvent(name: "user.personal-team-creation-flow-stopped")

    /// Count of user reaching the cancellation modal
    ///
    /// Segmentation: app_name; app_version; modal_continue-clicked; modal_leave-clicked

    static let clickedPersonalMigrationCTA = AnalyticsEvent(name: "user.personal-team-creation-flow-cancelled")

    /// Count of user reach the final stage (Step 4)
    ///
    /// Segmentation: app_name; app_version; modal_back-to-wire-clicked; modal_open-tm-clicked

    static let clickedPersonalMigrationCTA = AnalyticsEvent(name: "user.personal-team-creation-flow-completed")


    // TODO: Count of user click on the "Open Team Management" button on the final stage
    // (see event and segmentation “user.personal-team-creation-flow-completed”)
}

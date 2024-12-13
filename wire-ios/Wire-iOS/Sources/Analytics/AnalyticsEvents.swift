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

    static func triggerOpenProfile(isMigrationDotActive: Bool) -> AnalyticsEvent {
        AnalyticsEvent("ui.clicked-profile") {
            SegmentationEntry("migration_dot_active", isMigrationDotActive)
        }
    }

    /// User tapped the "Create Wire Team" button.
    static func triggeredPersonalMigrationCTA() -> AnalyticsEvent {
        personalMigrationCTA(
            isCreateTeamButtonUsed: true,
            isDismissCTAButtonUsed: false
        )
    }

    /// User probably saw the banner, but dismissed the profile screen.
    static func dismissedSelfProfileWithPersonalMigrationCTA() -> AnalyticsEvent {
        personalMigrationCTA(
            isCreateTeamButtonUsed: false,
            isDismissCTAButtonUsed: true
        )
    }

    /// Tap on the create a team CTA
    ///
    /// Segmentation: app_name; app_version; clicked_create_team; clicked_dismiss_cta

    private static func personalMigrationCTA(
        isCreateTeamButtonUsed: Bool,
        isDismissCTAButtonUsed: Bool
    ) -> AnalyticsEvent {
        AnalyticsEvent("ui.clicked-personal-migration-cta") {
            SegmentationEntry("clicked_create_team", isCreateTeamButtonUsed)
            SegmentationEntry("clicked_dismiss_cta", isDismissCTAButtonUsed)
        }
    }
}

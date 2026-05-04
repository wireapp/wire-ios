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

public import WireFoundation

public extension AnalyticsEvent {

    enum UI {

        /// An event tracking when the user opens the self profile.

        public static func openSelfProfile(isMigrationDotActive: Bool) -> AnalyticsEvent {
            AnalyticsEvent(name: "ui.clicked-profile") {
                if isMigrationDotActive {
                    Segmentation(key: "migration_dot_active", value: true)
                }
            }
        }

        /// An event tracking when the user taps the "Create Wire Team" button on the profile.

        public static var personalToTeamMigrationCTA: AnalyticsEvent {
            personalMigrationCTA(
                isCreateTeamButtonUsed: true
            )
        }

        /// An event tracking when the user dismisses the self profile and the personal to team migration banner was
        /// visible.

        public static var dismissedSelfProfileWithToTeamMigrationBanner: AnalyticsEvent {
            personalMigrationCTA(
                isCreateTeamButtonUsed: false
            )
        }

        private static func personalMigrationCTA(
            isCreateTeamButtonUsed: Bool
        ) -> AnalyticsEvent {
            AnalyticsEvent(name: "ui.clicked-personal-migration-cta") {
                if isCreateTeamButtonUsed {
                    Segmentation(key: "clicked_create_team", value: true)
                } else {
                    Segmentation(key: "clicked_dismiss_cta", value: true)
                }
            }
        }
    }

}

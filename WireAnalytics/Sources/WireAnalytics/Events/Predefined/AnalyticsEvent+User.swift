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

    enum User {

        public enum IndividualToTeamMigration {

            /// The various steps of the individual to team migration flow.

            public enum Step: Int {
                case disclaimer = 1
                case teamName
                case confirmation
            }

            /// The actions a user can choose on the dismiss confirmation alert.

            public enum CancelConfirmationAction {
                case `continue`
                case leave
            }

            /// The actions a user can choose on the final confirmation screen.

            public enum CompletedAction {
                case backToWire
                case openTeamManagement
            }

        }

        /// An event tracking when the user reaches a certain step of the individual to team migration flow.

        public static func personalTeamCreationFlowStarted(at step: IndividualToTeamMigration.Step) -> AnalyticsEvent {
            AnalyticsEvent(name: "user.personal-team-creation-flow-started") {
                Segmentation(key: "step_modalcreateteam", value: step.rawValue)
            }
        }

        /// An event tracking when the user dismisses the individual to team migration flow at a certain step.

        public static func personalToTeamMigrationFlowStopped(
            at step: IndividualToTeamMigration
                .Step
        ) -> AnalyticsEvent {
            AnalyticsEvent(name: "user.personal-team-creation-flow-stopped") {
                switch step {
                case .disclaimer:
                    Segmentation(key: "modal_disclaimers", value: true)
                case .teamName:
                    Segmentation(key: "modal_team-name", value: true)
                case .confirmation:
                    Segmentation(key: "modal_confirmation", value: true)
                }
            }
        }

        /// An event tracking when the user taps a button in the cancellation alert.

        public static func personalTeamCreationFlowCancel(
            action: IndividualToTeamMigration.CancelConfirmationAction
        ) -> AnalyticsEvent {
            AnalyticsEvent(name: "user.personal-team-creation-flow-cancelled") {
                switch action {
                case .continue:
                    Segmentation(key: "modal_continue-clicked", value: true)
                case .leave:
                    Segmentation(key: "modal_leave-clicked", value: true)
                }
            }
        }

        /// An event tracking when the user taps a button in the final confirmation screen.

        public static func personalTeamCreationFlowCompleted(
            action: IndividualToTeamMigration.CompletedAction?
        ) -> AnalyticsEvent {
            let segment: [Segmentation] = switch action {
            case .none:
                []
            case .backToWire:
                [Segmentation(key: "modal_back-to-wire-clicked", value: true)]
            case .openTeamManagement:
                [Segmentation(key: "modal_open-tm-clicked", value: true)]
            }
            return AnalyticsEvent(name: "user.personal-team-creation-flow-completed", segmentation: segment)
        }
    }
}

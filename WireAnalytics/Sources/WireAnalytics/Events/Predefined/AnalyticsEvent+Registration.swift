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

    enum Registration {

        /// An event tracking when the user submits the initial personal account creation form.

        public static var accountSetupStep0: AnalyticsEvent {
            AnalyticsEvent(name: "registration.account_setup_screen_1")
        }

        /// An event tracking when the user is dialog to agree to, view or disagree to the terms of use.

        public static var accountSetupStep1: AnalyticsEvent {
            AnalyticsEvent(name: "registration.account_ToU_screen_1.5")
        }

        /// An event tracking when the user is presented the form for entering the validation code.

        public static var accountSetupStep2: AnalyticsEvent {
            AnalyticsEvent(name: "registration.account_verification_screen_2")
        }

        /// An event tracking when the validation code is invalid.

        public static var accountSetupStep3: AnalyticsEvent {
            AnalyticsEvent(name: "registration.account_verification_failed_screen_2.5")
        }

        /// An event tracking when the user is presented the form for entering a username.

        public static var accountSetupStep4: AnalyticsEvent {
            AnalyticsEvent(name: "registration.account_username_screen_3")
        }

        /// An event tracking when choosing a username was successful.

        public static var accountSetupStep5: AnalyticsEvent {
            AnalyticsEvent(name: "registration.account_completion_screen_4")
        }

    }

}

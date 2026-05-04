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

extension AnalyticsEvent.Segmentation {

    enum Call {

        /// Creates a ``Segmentation`` for indicating whether a call is a video call.
        ///
        /// - Parameter value: A boolean indicating if the call is a video call.
        /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

        static func isVideoCall(_ value: Bool) -> AnalyticsEvent.Segmentation {
            .init(key: "call_video", value: value)
        }

        /// Creates a ``Segmentation`` providing the information if the user has toggled the video during the call.

        static func callAVSwitchToggled(_ value: Bool) -> AnalyticsEvent.Segmentation {
            .init(key: "call_av_switch_toggle", value: value)
        }

        /// Creates a ``AnalyticsEvent.Segmentation`` for indicating whether any screen sharing happened during the
        /// call. (including
        /// other participants)

        static func wasScreenShared(_ value: Bool) -> AnalyticsEvent.Segmentation {
            .init(key: "call_screen_share", value: value)
        }

        /// Creates a ``Segmentation`` for providing the total time in seconds any screen sharing happened in the
        /// call.

        static func totalScreenSharingDuration(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "call_screen_share_duration", value: value)
        }

        /// Creates a ``Segmentation`` for the number of unique users who shared the screen during the call.

        static func uniqueScreenSharingUsers(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "call_screen_share_unique", value: value)
        }

        /// Creates a ``Segmentation`` providing the information if the call was incoming or outgoing.

        static func callDirection(_ value: String) -> AnalyticsEvent.Segmentation {
            .init(key: "call_direction", value: value)
        }

        /// Creates a ``Segmentation`` for the length of the call in seconds.

        static func callDuration(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "call_duration", value: value)
        }

        /// Creates a ``Segmentation`` for the maximum number of users in the call.

        static func callParticipants(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "call_participants", value: value)
        }

        /// Creates a ``Segmentation`` for the reason a call has ended.

        static func callEndReason(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "call_end_reason", value: value)
        }
    }
}

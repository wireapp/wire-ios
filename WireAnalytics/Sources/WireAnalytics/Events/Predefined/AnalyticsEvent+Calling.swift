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

//public import Foundation

public extension AnalyticsEvent {

    enum Calling {

        /// An event tracking when the user initiates a call.
        ///
        /// - Parameters:
        ///   - isVideo: Whether video is enabled.
        ///   - conversationType: The type of conversation.
        ///
        /// - Returns: A call initialized analytics event.

        public static func initiatedCall(
            isVideo: Bool,
            conversationType: ConversationType
        ) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "calling.initiated_call",
                segmentation: [
                    .isVideoCall(isVideo),
                    .groupType(conversationType)
                ]
            )
        }

        /// An event tracking when the user joins a call.
        ///
        /// - Parameters:
        ///   - isVideo: Whether video is enabled.
        ///   - conversationType: The type of conversation.
        ///
        /// - Returns: A call joined analytics event.

        public static func joinedCall(
            isVideo: Bool,
            conversationType: ConversationType
        ) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "calling.joined_call",
                segmentation: [
                    .isVideoCall(isVideo),
                    .groupType(conversationType)
                ]
            )
        }

        /// An event tracking the call quality when the user end the call.
        /// - Parameter review: The Review containing score, reason or duration related to the call
        /// - Returns: A callQualitySurvey analytics event.

        public static func callQualitySurvey(_ review: CallQualitySurveyReview) -> AnalyticsEvent {
            .init(name: "calling.call_quality_review", segmentation: review.segmentation)
        }

        // TODO: parameters

        /// An event tracking when the user ends a call.
        ///
        /// - Parameters:
        ///   - todo: TODO
        ///
        /// - Returns: A call joined analytics event.

        public static func endedCall(
            deviceModel: String,
            deviceOS: String,
            wasScreenShared: Bool,
            totalScreenSharingDuration: Int,
            uniqueScreenSharingUsers: Int,
            callDirection: CallDirection,
            callDuration: Int,
            conversationType: ConversationType_,
            participantCount: UInt,
            callEndReason: String
        ) -> AnalyticsEvent {
            AnalyticsEvent(name: "calling.ended_call", segmentation: [
                .deviceModel(deviceModel),
                .deviceOS(deviceOS),
                .wasScreenShared(wasScreenShared),
                .totalScreenSharingDuration(totalScreenSharingDuration),
                .uniqueScreenSharingUsers(uniqueScreenSharingUsers),
                .callDirection(callDirection.rawValue),
                .callDuration(callDuration),
                .conversationType(conversationType),
                .conversationSize(participantCount),
                // TODO: implement
                // conversation_guests
                // conversation_guest_pro
                // call_participants
                .callEndReason(callEndReason)
                // conversation_services
                // call_av_switch_toggle
                // call_video
                // team_is_team
            ].compactMap(\.self))
        }

        public enum CallDirection: String {
            case outgoing
            case incoming
        }

    }
}

private extension SegmentationEntry {

    /// Creates a `SegmentationEntry` for indicating whether any screen sharing happened during the call. (including other participants)

    static func wasScreenShared(_ value: Bool) -> Self {
        .init(key: "call_screen_share", value: value)
    }

    /// Creates a `SegmentationEntry` for providing the total time in seconds any screen sharing happened in the call.

    static func totalScreenSharingDuration(_ value: Int) -> Self {
        .init(key: "call_screen_share_duration", value: value)
    }

    /// Creates a `SegmentationEntry` for the number of unique users who shared the screen during the call.

    static func uniqueScreenSharingUsers(_ value: Int) -> Self {
        .init(key: "call_screen_share_unique", value: value)
    }

    /// Creates a `SegmentationEntry` providing the information if the call was incoming or outgoing.

    static func callDirection(_ value: String) -> Self {
        .init(key: "call_direction", value: value)
    }

    /// Creates a `SegmentationEntry` for the length of the call in seconds.

    static func callDuration(_ value: Int) -> Self {
        .init(key: "call_duration", value: value)
    }

    // TODO: add more

    static func callEndReason(_ value: String) -> Self {
        .init(key: "call_end_reason", value: value)
    }

}

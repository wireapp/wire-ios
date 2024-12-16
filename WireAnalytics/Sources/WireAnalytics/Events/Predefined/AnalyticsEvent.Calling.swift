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
            isVideo: Bool,
            conversationType: ConversationType
        ) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "calling.ended_call",
                segmentation: [
//                    .isVideoCall(isVideo),
//                    .groupType(conversationType)
                ]
            )
        }

    }
}

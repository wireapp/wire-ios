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
            conversationType: Segmentation.Conversation.ConversationType
        ) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "calling.initiated_call",
                segmentation: [
                    .Call.isVideoCall(isVideo),
                    .Conversation.conversationType(conversationType),
                    .Removed.groupType(conversationType.mapToConversationType())
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
            conversationType: Segmentation.Conversation.ConversationType
        ) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "calling.joined_call",
                segmentation: [
                    .Call.isVideoCall(isVideo),
                    .Conversation.conversationType(conversationType),
                    .Removed.groupType(conversationType.mapToConversationType())
                ]
            )
        }

        /// An event tracking the call quality when the user end the call.
        /// - Parameter review: The Review containing score, reason or duration related to the call
        /// - Returns: A callQualitySurvey analytics event.

        public static func callQualitySurvey(_ review: CallQualitySurveyReview) -> AnalyticsEvent {
            .init(name: "calling.call_quality_review", segmentation: review.segmentation)
        }

        /// An event tracking when a call ends.

        public static func endedCall(
            callEndReason: CallEndedReason,
            callDetails: CallDetails,
            conversationDetails: ConversationDetails,
            isTeamMember: Bool
        ) -> AnalyticsEvent {
            AnalyticsEvent(name: "calling.ended_call", segmentation: [
                .Call.wasScreenShared(callDetails.wasScreenShared),
                .Call.totalScreenSharingDuration(callDetails.totalScreenSharingDuration),
                .Call.uniqueScreenSharingUsers(callDetails.uniqueScreenSharingUsers),
                .Call.callDirection(callDetails.callDirection.rawValue),
                .Call.callDuration(callDetails.callDuration),
                .Conversation.conversationType(conversationDetails.conversationType),
                .Conversation.conversationSize(conversationDetails.conversationSize),
                .Conversation.conversationGuestsNonTeam(conversationDetails.conversationGuestsNonTeam),
                .Conversation.conversationGuestsTeam(conversationDetails.conversationGuestsTeam),
                .Call.callParticipants(callDetails.callParticipantCount),
                .Call.callEndReason(callEndReason.value),
                .Conversation.conversationServices(callDetails.conversationServiceCount),
                .Call.callAVSwitchToggled(callDetails.hasAVSwitchToggled),
                .Call.isVideoCall(callDetails.isVideoCall),
                .Team.teamIsTeam(isTeamMember)
            ])
        }

        public enum CallDirection: String {
            case outgoing
            case incoming
        }

        public struct CallEndedReason {

            /// The value AVS uses.
            var value: Int

            /// - Parameter value: The value AVS uses.
            public init(value: Int) {
                self.value = value
            }
        }

        public struct CallDetails {

            var wasScreenShared: Bool
            var totalScreenSharingDuration: Int
            var uniqueScreenSharingUsers: Int
            var callDirection: CallDirection
            var callDuration: Int
            var callParticipantCount: Int
            var conversationServiceCount: Int
            var hasAVSwitchToggled: Bool
            var isVideoCall: Bool

            public init(
                wasScreenShared: Bool,
                totalScreenSharingDuration: Int,
                uniqueScreenSharingUsers: Int,
                callDirection: CallDirection,
                callDuration: Int,
                callParticipantCount: Int,
                conversationServiceCount: Int,
                hasAVSwitchToggled: Bool,
                isVideoCall: Bool
            ) {
                self.wasScreenShared = wasScreenShared
                self.totalScreenSharingDuration = totalScreenSharingDuration
                self.uniqueScreenSharingUsers = uniqueScreenSharingUsers
                self.callDirection = callDirection
                self.callDuration = callDuration
                self.callParticipantCount = callParticipantCount
                self.conversationServiceCount = conversationServiceCount
                self.hasAVSwitchToggled = hasAVSwitchToggled
                self.isVideoCall = isVideoCall
            }
        }

        public struct ConversationDetails {

            var conversationType: Segmentation.Conversation.ConversationType
            var conversationSize: Int
            var conversationGuestsNonTeam: Int
            var conversationGuestsTeam: Int

            public init(
                conversationType: Segmentation.Conversation.ConversationType,
                conversationSize: Int,
                conversationGuestsNonTeam: Int,
                conversationGuestsTeam: Int
            ) {
                self.conversationType = conversationType
                self.conversationSize = conversationSize
                self.conversationGuestsNonTeam = conversationGuestsNonTeam
                self.conversationGuestsTeam = conversationGuestsTeam
            }
        }

    }
}

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
            conversationType: SegmentationEntry.Conversation.ConversationType
        ) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "calling.initiated_call",
                segmentation: [
                    .isVideoCall(isVideo),
                    .conversationType(conversationType),
                    .groupType(conversationType.mapToConversationType())
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
            conversationType: SegmentationEntry.Conversation.ConversationType
        ) -> AnalyticsEvent {
            AnalyticsEvent(
                name: "calling.joined_call",
                segmentation: [
                    .isVideoCall(isVideo),
                    .conversationType(conversationType),
                    .groupType(conversationType.mapToConversationType())
                ]
            )
        }

        /// An event tracking the call quality when the user end the call.
        /// - Parameter review: The Review containing score, reason or duration related to the call
        /// - Returns: A callQualitySurvey analytics event.

        public static func callQualitySurvey(_ review: CallQualitySurveyReview) -> AnalyticsEvent {
            .init(name: "calling.call_quality_review", segmentation: review.segmentation)
        }

        // TODO: finish documentation
        /// An event tracking when a call ends.
        /// - Parameters:
        ///   - deviceModel: <#deviceModel description#>
        ///   - deviceOS: <#deviceOS description#>
        ///   - wasScreenShared: <#wasScreenShared description#>
        ///   - totalScreenSharingDuration: <#totalScreenSharingDuration description#>
        ///   - uniqueScreenSharingUsers: <#uniqueScreenSharingUsers description#>
        ///   - callDirection: <#callDirection description#>
        ///   - callDuration: <#callDuration description#>
        ///   - conversationType: <#conversationType description#>
        ///   - conversationSize: <#participantCount description#>
        ///   - conversationGuestsNonTeam: <#conversationGuestsNonTeam description#>
        ///   - conversationGuestsTeam: <#conversationGuestsTeam description#>
        ///   - callParticipants: <#callParticipants description#>
        ///   - callEndReason: <#callEndReason description#>
        ///   - conversationServices: <#conversationServices description#>
        ///   - hasAVSwitchToggled: <#hasAVSwitchToggled description#>
        ///   - isVideoCall: <#isVideoCall description#>
        ///   - isTeamMember: <#isTeamMember description#>

        public static func endedCall( // TODO: apply similar structure: https://github.com/wireapp/wire-android/pull/3756/files#diff-911099b2239b176e83580216da2c915a1a8f2561d8d37812c8245d9168989602R978
            deviceModel: String,
            deviceOS: String,
            wasScreenShared: Bool,
            totalScreenSharingDuration: Int,
            uniqueScreenSharingUsers: Int,
            callDirection: CallDirection,
            callDuration: Int,
            conversationType: SegmentationEntry.Conversation.ConversationType,
            conversationSize: Int,
            conversationGuestsNonTeam: Int,
            conversationGuestsTeam: Int,
            callParticipants: Int,
            callEndReason: String,
            conversationServices: Int,
            hasAVSwitchToggled: Bool,
            isVideoCall: Bool,
            isTeamMember: Bool
        ) -> AnalyticsEvent {
            AnalyticsEvent(name: "calling.ended_call", segmentation: [
                .deviceModel(deviceModel),
                .deviceOS(deviceOS),
                .Call.wasScreenShared(wasScreenShared),
                .Call.totalScreenSharingDuration(totalScreenSharingDuration),
                .Call.uniqueScreenSharingUsers(uniqueScreenSharingUsers),
                .Call.callDirection(callDirection.rawValue),
                .Call.callDuration(callDuration),
                .conversationType(conversationType),
                .conversationSize(conversationSize),
                .conversationGuestsNonTeam(conversationGuestsNonTeam),
                .conversationGuestsTeam(conversationGuestsTeam),
                .Call.callParticipants(callParticipants),
                .Call.callEndReason(callEndReason),
                .conversationServices(conversationServices),
                .Call.callAVSwitchToggled(hasAVSwitchToggled),
                .isVideoCall(isVideoCall),
                .Team.teamIsTeam(isTeamMember)
            ])
        }

        public enum CallDirection: String {
            case outgoing
            case incoming
        }

    }
}

private extension SegmentationEntry { // TODO: consider moving to nested enum/namespace `Conversation` if needed

    /// Creates a `SegmentationEntry` for the number of guests in a conversation which are not members of any team (free
    /// users).

    static func conversationGuestsNonTeam(_ value: Int) -> Self {
        .init(key: "conversation_guests", value: value)
    }

    /// Creates a `SegmentationEntry` for the number of guests in a conversation which are members of a team.

    static func conversationGuestsTeam(_ value: Int) -> Self {
        .init(key: "conversation_guests_pro", value: value)
    }

    /// Creates a `SegmentationEntry` for the number of services (members) of the conversation.

    static func conversationServices(_ value: Int) -> Self {
        .init(key: "conversation_services", value: value)
    }

}

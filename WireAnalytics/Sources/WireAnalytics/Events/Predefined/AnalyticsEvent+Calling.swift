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

        public static func endedCall( // TODO: apply similar structure: https://github.com/wireapp/wire-android/pull/3756/files
            deviceModel: String,
            deviceOS: String,
            wasScreenShared: Bool,
            totalScreenSharingDuration: Int,
            uniqueScreenSharingUsers: Int,
            callDirection: CallDirection,
            callDuration: Int,
            conversationType: ConversationType_,
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
                .wasScreenShared(wasScreenShared),
                .totalScreenSharingDuration(totalScreenSharingDuration),
                .uniqueScreenSharingUsers(uniqueScreenSharingUsers),
                .callDirection(callDirection.rawValue),
                .callDuration(callDuration),
                .conversationType(conversationType),
                .conversationSize(conversationSize),
                .conversationGuestsNonTeam(conversationGuestsNonTeam),
                .conversationGuestsTeam(conversationGuestsTeam),
                .callParticipants(callParticipants),
                .callEndReason(callEndReason),
                .conversationServices(conversationServices),
                .callAVSwitchToggled(hasAVSwitchToggled),
                .isVideoCall(isVideoCall),
                .teamIsTeam(isTeamMember)
            ])
        }

        public enum CallDirection: String {
            case outgoing
            case incoming
        }

    }
}

private extension SegmentationEntry { // TODO: consider nested enum/namespace `Call`

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

    /// Creates a `SegmentationEntry` for the maximum number of users in the call.

    static func callParticipants(_ value: Int) -> Self {
        .init(key: "call_participants", value: value)
    }

    /// Creates a `SegmentationEntry` for the reason a call has ended.

    static func callEndReason(_ value: String) -> Self {
        .init(key: "call_end_reason", value: value)
    }

    /// Creates a `SegmentationEntry` providing the information if the user has toggled the video during the call.

    static func callAVSwitchToggled(_ value: Bool) -> Self {
        .init(key: "call_av_switch_toggle", value: value)
    }

    /// Creates a `SegmentationEntry` providing the information if the user is part of a team (redundant to `is_team_member`).

    static func teamIsTeam(_ value: Bool) -> Self {
        .init(key: "team_is_team", value: value)
    }

}

private extension SegmentationEntry { // TODO: consider nested enum/namespace `Conversation`

    /// Creates a `SegmentationEntry` for the number of guests in a conversation which are not members of any team (free users).

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

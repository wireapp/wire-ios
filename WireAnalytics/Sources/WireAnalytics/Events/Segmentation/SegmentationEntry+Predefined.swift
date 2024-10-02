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

// MARK: - Predefined entries

extension SegmentationEntry {

    /// Creates a `SegmentationEntry` for indicating whether a call is a video call.
    ///
    /// - Parameter value: A string indicating device OS version of the user
    /// - Returns: A `SegmentationEntry` instance with the appropriate key and value.

    static func deviceOS(_ value: String) -> Self {
        .init(key: "os_version", value: value)
    }

    /// Creates a `SegmentationEntry` for indicating whether a call is a video call.
    ///
    /// - Parameter value: A string indicating device model of the user
    /// - Returns: A `SegmentationEntry` instance with the appropriate key and value.

    static func deviceModel(_ value: String) -> Self {
        .init(key: "device_model", value: value)
    }

    /// Creates a `SegmentationEntry` for indicating whether a call is a video call.
    ///
    /// - Parameter value: A boolean indicating if the self user is a team member.
    /// - Returns: A `SegmentationEntry` instance with the appropriate key and value.

    static func isSelfTeamMember(_ value: Bool) -> Self {
        .init(key: "is_team_member", value: value.analyticsValue)
    }

    /// Creates a `SegmentationEntry` for indicating whether a call is a video call.
    ///
    /// - Parameter value: A boolean indicating if the call is a video call.
    /// - Returns: A `SegmentationEntry` instance with the appropriate key and value.

    static func isVideoCall(_ value: Bool) -> Self {
        .init(key: "is_video_call", value: value.analyticsValue)
    }

    /// Creates a `SegmentationEntry` for the type of group in a conversation.
    ///
    /// - Parameter value: The `ConversationType` of the conversation.
    /// - Returns: A `SegmentationEntry` instance with the appropriate key and value.

    static func groupType(_ value: ConversationType) -> Self {
        .init(key: "group_type", value: value.analyticsValue)
    }

    /// Creates a `SegmentationEntry` for the type of contribution in a conversation.
    ///
    /// - Parameter value: The `ContributionType` of the contribution.
    /// - Returns: A `SegmentationEntry` instance with the appropriate key and value.

    static func contributionType(_ value: ConversationContributionType) -> Self {
        .init(key: "contribution_type", value: value.analyticsValue)
    }

    /// Creates a `SegmentationEntry` for the size of a conversation.
    ///
    /// - Parameter value: The number of participants in the conversation.
    /// - Returns: A `SegmentationEntry` instance with the appropriate key and value.

    static func conversationSize(_ value: UInt) -> Self {
        .init(key: "conversation_size", value: value.analyticsValue)
    }

}

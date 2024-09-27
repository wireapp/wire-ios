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

/// An event tracking the user's contributions in a conversation.

public struct ConversationContributionAnalyticsEvent: AnalyticsEvent {

    /// The type of contribution.

    public var contributionType: ConversationContributionType

    /// The type of conversation.

    public var conversationType: ConversationType

    /// The size of the conversation.

    public var conversationSize: UInt

    /// Create a new `ConversationContributionAnalyticsEvent`.

    public init(
        contributionType: ConversationContributionType,
        conversationType: ConversationType,
        conversationSize: UInt
    ) {
        self.contributionType = contributionType
        self.conversationType = conversationType
        self.conversationSize = conversationSize
    }

    /// The name of the event.

    public var eventName: String {
        "contributed"
    }

    /// The segmentation information for the event.

    public var segmentation: Set<SegmentationEntry> {
        [
            .groupType(conversationType),
            .contributionType(contributionType),
            .conversationSize(conversationSize)
        ]
    }

}

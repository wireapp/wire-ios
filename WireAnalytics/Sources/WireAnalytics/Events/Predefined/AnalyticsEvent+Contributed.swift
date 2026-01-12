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

    enum Contributed {

        /// An event tracking the when the user contributes to a conversation.
        ///
        /// - Parameters:
        ///   - contributionType: The type of contribution.
        ///   - conversationType: The type of conversation.
        ///   - conversationSize: The number of participants in the conversation.
        ///
        /// - Returns: A conversation contribution analytics event.

        public static func conversationContribution(
            _ contributionType: ConversationContributionType,
            conversationType: Segmentation.Conversation.ConversationType?,
            conversationSize: Int
        ) -> AnalyticsEvent {
            AnalyticsEvent(name: "contributed") {
                Segmentation.contributionType(contributionType)
                if let conversationType {
                    Segmentation.Conversation.conversationType(conversationType)
                }
                Segmentation.Removed.groupType(conversationType?.mapToConversationType() ?? .unknown)
                Segmentation.Conversation.conversationSize(conversationSize)
            }
        }

    }
}

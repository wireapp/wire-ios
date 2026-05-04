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

public extension AnalyticsEvent.Segmentation {

    enum Conversation {

        /// Creates a ``Segmentation`` for the type of conversation.

        static func conversationType(_ value: Conversation.ConversationType) -> AnalyticsEvent.Segmentation {
            .init(key: "conversation_type", value: value.rawValue)
        }

        /// Creates a ``Segmentation`` for the size of a conversation.
        ///
        /// - Parameter value: The number of participants in the conversation.
        /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

        static func conversationSize(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "conversation_size", value: value)
        }

        /// Creates a ``Segmentation`` for the number of guests in a conversation which are not members of any team
        /// (personal accounts).

        static func conversationGuestsNonTeam(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "conversation_guests", value: value)
        }

        /// Creates a ``Segmentation`` for the number of guests in a conversation which are members of a team.

        static func conversationGuestsTeam(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "conversation_guests_pro", value: value)
        }

        /// Creates a ``Segmentation`` for the number of services (members) of the conversation.

        static func conversationServices(_ value: Int) -> AnalyticsEvent.Segmentation {
            .init(key: "conversation_services", value: value)
        }

        public enum ConversationType: String {
            case group
            case oneOnOne = "one_to_one"
        }
    }
}

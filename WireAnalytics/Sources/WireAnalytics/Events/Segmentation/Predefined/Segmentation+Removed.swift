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

import struct Foundation.TimeInterval

// The segmentation entries in this file are not to be used anymore.
// As soon as we get the confirmation that these are not used anymore, we should delete this file.
// https://wearezeta.atlassian.net/wiki/spaces/ENGINEERIN/pages/1364262933/Appendix+Countly+segmentation+values

extension AnalyticsEvent.Segmentation {

    enum Removed {

        // https://wearezeta.atlassian.net/browse/WPB-12199?focusedCommentId=132080
        @available(*, deprecated, message: "Use `AnalyticsEvent.Segmentation.Conversation.ConversationType`.")
        enum ConversationType: String {
            case group
            case oneOnOne = "one_on_one"
            case unknown
        }

        /// Creates a ``Segmentation`` for the type of group in a conversation.
        ///
        /// - Parameter value: The `ConversationType` of the conversation.
        /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

        @available(*, deprecated, renamed: "conversationType")
        static func groupType(_ value: ConversationType) -> AnalyticsEvent.Segmentation {
            // https://wearezeta.atlassian.net/browse/WPB-12199?focusedCommentId=132080
            .init(key: "group_type", value: value.rawValue)
        }

        /// Creates a ``Segmentation`` for the duration of the calling survey
        ///
        /// - Parameter value: The duration of the call.
        /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

        static func callDuration(_ value: TimeInterval) -> AnalyticsEvent.Segmentation {
            .init(key: "duration", value: String(value))
        }

        /// Creates a ``Segmentation`` for the ignore reason of the calling survey
        /// - Parameter value: the ignore reason
        /// - Returns: A ``Segmentation`` instance with the appropriate key and value.

        static func callIgnoreReason(_ value: String) -> AnalyticsEvent.Segmentation {
            .init(key: "ignore-reason", value: value)
        }
    }
}

extension AnalyticsEvent.Segmentation.Conversation.ConversationType {

    func mapToConversationType() -> AnalyticsEvent.Segmentation.Removed.ConversationType {
        switch self {
        case .group:
            .group
        case .oneOnOne:
            .oneOnOne
        }
    }
}

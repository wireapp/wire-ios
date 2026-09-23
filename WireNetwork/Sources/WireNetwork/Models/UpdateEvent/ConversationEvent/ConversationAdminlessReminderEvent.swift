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

public import Foundation

/// An event sent as a periodic reminder that a conversation has no eligible admins and is scheduled for automatic
/// deletion by the backend.

public struct ConversationAdminlessReminderEvent: Equatable, Sendable {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The id of the admin who left and made the conversation adminless.

    public let senderID: UserID

    /// When the reminder was sent.

    public let timestamp: Date

    /// The date at which the backend will automatically delete the conversation.

    public let scheduledDeletionDate: Date

    /// Create a new `ConversationAdminlessReminderEvent`.
    ///
    /// - Parameters:
    ///   - conversationID: The id of the conversation.
    ///   - senderID: The id of the admin who left and made the conversation adminless.
    ///   - timestamp: When the reminder was sent.
    ///   - scheduledDeletionDate: The date at which the backend will automatically delete the conversation.

    public init(
        conversationID: ConversationID,
        senderID: UserID,
        timestamp: Date,
        scheduledDeletionDate: Date
    ) {
        self.conversationID = conversationID
        self.senderID = senderID
        self.timestamp = timestamp
        self.scheduledDeletionDate = scheduledDeletionDate
    }

}

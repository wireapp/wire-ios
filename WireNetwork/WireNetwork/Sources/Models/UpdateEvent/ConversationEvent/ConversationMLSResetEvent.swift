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

import Foundation

/// An event where an mls reset for a conversation.

public struct ConversationMLSResetEvent: Equatable, Sendable {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The id of the user set the permission.

    public let senderID: UserID

    /// The old group id before reset

    public let oldMLSGroupIDBase64: String
    public let newMLSGroupIDBase64: String

    public init(
        conversationID: ConversationID,
        senderID: UserID,
        oldMLSGroupIDBase64: String,
        newMLSGroupIDBase64: String
    ) {
        self.conversationID = conversationID
        self.senderID = senderID
        self.oldMLSGroupIDBase64 = oldMLSGroupIDBase64
        self.newMLSGroupIDBase64 = newMLSGroupIDBase64
    }
}

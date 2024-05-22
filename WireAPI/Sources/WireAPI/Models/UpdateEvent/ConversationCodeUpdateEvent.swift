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

import Foundation

/// An event where a conversation's access code was updated.

public struct ConversationCodeUpdateEvent {

    /// The id of the conversation.

    public let conversationID: ConversationID

    /// The access key.

    public let key: String

    /// The access code.

    public let code: String

    /// A link to join the conversation.

    public let uri: String?

    /// Whether a password is required to join the conversation.

    public let isPasswordProtected: Bool

}

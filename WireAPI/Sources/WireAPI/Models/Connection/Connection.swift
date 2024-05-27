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

public struct Connection: Equatable {

    /// Remote identifier of the sender

    public let senderId: UUID?

    /// Remote identifier of the receiver

    public let receiverId: UUID?

    /// Qualified identifier of the receiver

    public let receiverQualifiedId: QualifiedID?

    /// Remote identifier of the conversation

    public let conversationId: UUID?

    /// Qualified identifier of the conversation

    public let qualifiedConversationId: QualifiedID?

    /// Time when connection was last updated

    public let lastUpdate: Date

    /// current status of connection

    public let status: ConnectionStatus
}

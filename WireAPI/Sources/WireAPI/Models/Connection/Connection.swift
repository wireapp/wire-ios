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

public struct Connection: Equatable, Codable {

    /// Remote identifier of the sender

    public let senderID: UUID?

    /// Remote identifier of the receiver

    public let receiverID: UUID?

    /// Qualified identifier of the receiver

    public let receiverQualifiedID: QualifiedID?

    /// Remote identifier of the conversation

    public let conversationID: UUID?

    /// Qualified identifier of the conversation

    public let qualifiedConversationID: QualifiedID?

    /// Time when connection was last updated

    public let lastUpdate: Date

    /// current status of connection

    public let status: ConnectionStatus
    
    public init(senderID: UUID?,
         receiverID: UUID?,
         receiverQualifiedID: QualifiedID?,
         conversationID: UUID?,
         qualifiedConversationID: QualifiedID?,
         lastUpdate: Date,
         status: ConnectionStatus
    ) {
        self.senderID = senderID
        self.receiverID = receiverID
        self.receiverQualifiedID = receiverQualifiedID
        self.conversationID = conversationID
        self.qualifiedConversationID = qualifiedConversationID
        self.lastUpdate = lastUpdate
        self.status = status
    }

}

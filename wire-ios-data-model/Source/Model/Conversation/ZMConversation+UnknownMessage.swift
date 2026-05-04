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

import GenericMessageProtocol

public extension ZMConversation {

    /// Appends a placeholder message to the conversation. This message can later be exchanged once the payload can
    /// successfully be deserialized.
    /// - Parameters:
    ///   - payload: The binary data to be deserialized into a ``GenericMessage`` instance.
    func appendUnknownMessage(
        messageID: UUID,
        sender: ZMUser,
        serverTimestamp: Date,
        payload: Data
    ) throws -> UnknownMessage {

        guard let managedObjectContext else {
            throw AppendUnknownMessageError.managedObjectContextIsNil
        }

        let unknownMessage = UnknownMessage(
            nonce: messageID,
            managedObjectContext: managedObjectContext
        )
        unknownMessage.nonce = messageID
        unknownMessage.sender = sender
        unknownMessage.serverTimestamp = serverTimestamp
        unknownMessage.payload = payload

        return unknownMessage

    }

    enum AppendUnknownMessageError: Error {
        case managedObjectContextIsNil
    }

}

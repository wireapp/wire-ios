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

import GenericMessageProtocol
import WireBackup
import WireDataModel
import WireFoundation

extension MessageBackupModel {

    init?(_ message: ZMMessage) {
        switch message {

        case let message as ZMClientMessage where !message.isObfuscated:
            guard let genericMessage = message.underlyingMessage, genericMessage.isInitialized else { return nil }
            self.init(message, genericMessage: genericMessage)

        case let message as ZMAssetClientMessage where !message.isObfuscated:
            guard let genericMessage = message.underlyingMessage, genericMessage.isInitialized else { return nil }
            self.init(message, genericMessage: genericMessage)

        default:
            return nil
        }
    }

    init?(_ message: ZMMessage, genericMessage: GenericMessage) {

        guard
            !message.isEphemeral,
            let id = message.nonce,
            let senderUserID = message.senderUser?.qualifiedID(localDomain: message.managedObjectContext?.localDomain),
            let creationDate = message.serverTimestamp,
            let conversationID = message.conversation?.qualifiedID,
            let content = genericMessage.content.flatMap(MessageBackupModel.Content.init)
        else { return nil }

        self.init(
            id: id.uuidString,
            conversationID: QualifiedID(conversationID),
            senderUserID: QualifiedID(senderUserID),
            senderClientID: message.senderClientID,
            creationDate: creationDate,
            content: content
        )

    }

}

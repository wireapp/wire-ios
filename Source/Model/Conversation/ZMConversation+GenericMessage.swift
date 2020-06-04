//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
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
import WireProtos

extension ZMConversation {
    /// Appends a new message to the conversation.
    /// @param genericMessage the generic message that should be appended
    /// @param expires wether the message should expire or tried to be send infinitively
    /// @param hidden wether the message should be hidden in the conversation or not
    public func appendClientMessage(with genericMessage: GenericMessage, expires: Bool = true, hidden: Bool = false) -> ZMClientMessage? {
        guard let nonce = UUID(uuidString: genericMessage.messageID) else { return nil }
        guard let moc = self.managedObjectContext else { return nil }
        do {
            let data = try genericMessage.serializedData()
            let message = ZMClientMessage(nonce: nonce, managedObjectContext: moc)
            message.add(data)
            return append(message, expires: expires, hidden: hidden)
        } catch {
            return nil
        }
    }
    
    /// Appends a new message to the conversation.
    /// @param client message that should be appended
    public func append(_ message: ZMClientMessage, expires: Bool, hidden: Bool) -> ZMClientMessage? {
        guard let moc = self.managedObjectContext else {
            return nil
        }
        message.sender = ZMUser.selfUser(in: moc)
        
        if expires {
            message.setExpirationDate()
        }
        
        if hidden {
            message.hiddenInConversation = self
        } else {
            append(message)
            unarchiveIfNeeded()
            message.updateCategoryCache()
            message.prepareToSend()
        }
        return message
    }
}

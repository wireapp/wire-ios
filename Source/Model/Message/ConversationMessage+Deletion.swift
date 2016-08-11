//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
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

extension ZMConversation {
    static func appendHideMessageToSelfConversation(message: ZMMessage) {
        guard let messageNonce = message.nonce,
            let conversation = message.conversation,
            let convID = conversation.remoteIdentifier else {
                return
        }

        let nonce = NSUUID()
        let genericMessage = ZMGenericMessage(hideMessage: messageNonce.transportString(), inConversation: convID.transportString(), nonce: nonce.transportString())
        ZMConversation.appendSelfConversationWithGenericMessageData(genericMessage.data().copy() as! NSData, managedObjectContext: message.managedObjectContext)
    }
}

extension ZMMessage {
    
    // NOTE: This is a free function meant to be called from Obj-C because you can't call protocol extension from it
    public static func hideMessage(message: ZMConversationMessage) {
        guard let castedMessage = message as? ZMMessage else { return }
        castedMessage.hideForSelfUser()
    }
    
    func hideForSelfUser() {
        guard !isZombieObject else { return }
        ZMConversation.appendHideMessageToSelfConversation(self)
        removeMessage()
    }
    
    public static func deleteForEveryone(message: ZMConversationMessage) {
        guard let castedMessage = message as? ZMMessage else { return }
        castedMessage.deleteForEveryone()
    }
    
    func deleteForEveryone() {
        guard !isZombieObject, let sender = sender where sender.isSelfUser else { return }
        guard let conversation = conversation else { return }
        
        // We insert a message of type `ZMMessageDelete` containing the nonce of the message that should be deleted
        let deletedMessage = ZMGenericMessage(deleteMessage: nonce.transportString(), nonce: NSUUID().transportString())
        
        conversation.appendNonExpiringGenericMessage(deletedMessage, hidden: true)
        removeMessage()
    }
}

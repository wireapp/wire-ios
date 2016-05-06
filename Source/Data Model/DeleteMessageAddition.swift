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
// along with this program. If not, see <http://www.gnu.org/licenses/>.
// 


import Foundation
import ZMCDataModel

extension ZMConversation {
    static func appendSelfConversationWithDeleteOfMessage(message: ZMMessage) {
        guard let messageNonce = message.nonce,
            let conversation = message.conversation,
            let convID = conversation.remoteIdentifier else {
                return
        }
        
        let nonce = NSUUID()
        let genericMessage = ZMGenericMessage(deleteMessage: messageNonce.transportString(), inConversation: convID.transportString(), nonce: nonce.transportString())
        ZMConversation.appendSelfConversationWithGenericMessageData(genericMessage.data().copy() as! NSData, managedObjectContext: message.managedObjectContext)
    }
}

extension ZMConversationMessage {
        
    // this is for UI
    public func deleteForAccount() {
        guard let selfMessage = self as? ZMMessage else { return }
        selfMessage.deleteForAccount()
    }
}

extension ZMMessage {
    
// NOTE:- This is a free function meant to be call from Objc because you can't call protocol extension from it
    public static func deleteMessage(message: ZMConversationMessage) {
        message.deleteForAccount()
    }
    
    func deleteForAccount() {
        if self.isZombieObject {
            return
        }
        
        ZMConversation.appendSelfConversationWithDeleteOfMessage(self)
        self.managedObjectContext?.deleteObject(self)
    }
}

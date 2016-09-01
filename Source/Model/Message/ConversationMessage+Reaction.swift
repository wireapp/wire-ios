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


extension ZMMessage {
    
    public static func addReaction(unicodeValue: String?, toMessage message: ZMConversationMessage)
    {
        guard let message = message as? ZMMessage,
              let context = message.managedObjectContext else { return }
        
        let genericMessage = ZMGenericMessage(emojiString: unicodeValue, messageID:message.nonce.transportString(), nonce: NSUUID().transportString())
        message.conversation?.appendGenericMessage(genericMessage, expires:false, hidden: true)
        
        message.addReaction(unicodeValue, forUser: ZMUser.selfUserInContext(context))
    }
    
    public static func removeReaction(onMessage message:ZMConversationMessage)
    {
        addReaction(nil, toMessage: message)
    }
    
    @objc public func addReaction(unicodeValue: String?, forUser user:ZMUser) {
        
        removeReaction(forUser:user)
        if let unicodeValue = unicodeValue where unicodeValue.characters.count > 0 {
            for reaction in self.reactions {
                if reaction.unicodeValue! == unicodeValue {
                    reaction.mutableSetValueForKey(ZMReactionUsersValueKey).addObject(user)
                    return
                }
            }
            
            //we didn't find a reaction, need to add a new one
            let newReaction = Reaction.insertReaction(unicodeValue, users:[user], inMessage: self)
            self.mutableSetValueForKey("reactions").addObject(newReaction)
        }
    }
    
    @objc internal func removeReaction(forUser user: ZMUser)
    {
        for reaction in self.reactions {
            if reaction.users.contains(user) {
                reaction.mutableSetValueForKey(ZMReactionUsersValueKey).removeObject(user)
                break;
            }
        }
    }
    
}

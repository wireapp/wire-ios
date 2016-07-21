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


class ZMLocalNotificationForRenameEvent : ZMLocalNotificationForEvent {
    
    var newName : String!
    
    internal override var eventType: ZMLocalNotificationForEventType {return .ConversationRename}
    
    override var requiresConversation : Bool {
        return true
    }
    
    override func canCreateNotification() -> Bool {
        if (!super.canCreateNotification()) { return false }
        
        if let name = eventData["name"] as? String where name.characters.count > 0 {
            newName = name
            return true
        }
        return false
    }
    
    override func configureAlertBody() -> String {
        return ZMPushStringConversationRename.localizedStringWithUser(sender, count:nil, text:newName)
    }
}


class ZMLocalNotificationForConversationCreateEvent : ZMLocalNotificationForEvent {
    internal override var eventType: ZMLocalNotificationForEventType {return .ConversationCreate }
    
    override func configureAlertBody() -> String {
        return ZMPushStringConversationCreate.localizedStringWithUser(sender, count:nil, text:nil)
    }
}


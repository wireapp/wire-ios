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


import ZMTransport


class ZMLocalNotificationForMemberEvent : ZMLocalNotificationForEvent {

    var userIDStrings : [String]!
    
    override var requiresConversation : Bool {
        return true
    }
    
    override func canCreateNotification() -> Bool {
        guard super.canCreateNotification()
        else { return false }
        
        guard let userIDs = eventData["user_ids"] as? [String] where userIDs.count > 0
        else { return false }
        
        userIDStrings = userIDs
        return true
    }
    
    func alertBodyForMemberJoinOrLeaveEvent(type : ZMUpdateEventType) ->  String {
        if userIDStrings.count == 1 {
            let firstUserID = NSUUID(UUIDString: userIDStrings.first!)
            let user = ZMUser(remoteID: firstUserID!, createIfNeeded: false, inContext: managedObjectContext)
            let senderID = lastEvent.senderUUID()
            
            if  senderID != nil && senderID == firstUserID {
                return ZMPushStringMemberLeaveSender.localizedStringWithUser(sender, conversation: conversation, otherUser: nil)
            }
            let key = (type == .ConversationMemberLeave) ? ZMPushStringMemberLeave : ZMPushStringMemberJoin
            return key.localizedStringWithUser(sender, conversation: conversation, otherUser: user)
        }
        let key = (type == .ConversationMemberLeave) ? ZMPushStringMemberLeaveMany : ZMPushStringMemberJoinMany
        return key.localizedStringWithUser(sender, conversation: conversation, otherUser: nil)
    }
    
    func alertBodyForMultipleMemberJoinOrLeaveEvents(type : ZMUpdateEventType) -> String {
        let aSender = allEventsAreFromSameSender ? sender : nil
        let key = (type == .ConversationMemberLeave) ? ZMPushStringMemberLeaveMany : ZMPushStringMemberJoinMany
        return key.localizedStringWithUser(aSender, conversation: conversation, otherUser: nil)
    }
}


class ZMLocalNotificationForMemberLeaveEvent : ZMLocalNotificationForMemberEvent {
    
    override var copiedEventTypes : [ZMUpdateEventType] {
        return [.ConversationMemberLeave]
    }
    
    override func configureAlertBody() -> String {
        if events.count == 1 {
            return alertBodyForMemberJoinOrLeaveEvent(.ConversationMemberLeave)
        }
        return alertBodyForMultipleMemberJoinOrLeaveEvents(.ConversationMemberLeave)
    }
}


class ZMLocalNotificationForMemberJoinEvent : ZMLocalNotificationForMemberEvent {
    
    override var copiedEventTypes : [ZMUpdateEventType] {
        return [.ConversationMemberJoin]
    }
    
    override func configureAlertBody() -> String {
        if events.count == 1 {
            return alertBodyForMemberJoinOrLeaveEvent(.ConversationMemberJoin)
        }
        return alertBodyForMultipleMemberJoinOrLeaveEvents(.ConversationMemberJoin)
    }
}



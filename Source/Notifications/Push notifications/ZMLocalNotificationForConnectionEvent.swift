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

class ZMLocalNotificationForConnectionEvent : ZMLocalNotificationForEvent {
    
    override func configureAlertBody() -> String {
        let name = eventData["name"] as? String
        return ZMPushStringConnectionRequest.localizedStringWithUserName(name)
    }
    
    override var category : String {
        return ZMConnectCategory
    }
}

class ZMLocalNotificationForUserConnectionEvent : ZMLocalNotificationForEvent {
    
    internal override var eventType: ZMLocalNotificationForEventType {return connectionType }
    
    var connectionType : ZMLocalNotificationForEventType!
    
    override func canCreateNotification() -> Bool {
        if !super.canCreateNotification() { return false }
        let lastEvent = self.lastEvent! // last event is sure to exist here, checked in canCreateNotificaion
        if let status = lastEvent.payload["connection"]?["status"] as? String {
            if status == "accepted" {
                connectionType = .ConnectionAccepted
                return true
            } else if status == "pending" {
                connectionType = .ConnectionRequest
                return true
            }
        }
        return false
    }
    
    override func configureAlertBody() -> String {
        let name = sender?.name ?? lastEvent!.payload["user"]?["name"] as? String
        if connectionType == .ConnectionRequest {
            return ZMPushStringConnectionRequest.localizedStringWithUserName(name)
        }
        return ZMPushStringConnectionAccepted.localizedStringWithUserName(name)
    }
    
    override var category : String {
        return (connectionType == .ConnectionRequest) ? ZMConnectCategory : ZMConversationCategory
    }
}

class ZMLocalNotificationForNewUserEvent : ZMLocalNotificationForEvent {
    
    internal override var eventType: ZMLocalNotificationForEventType {return .NewConnection}
    
    override func configureAlertBody() -> String {
        let name = lastEvent!.payload["user"]?["name"] as? String
        return ZMPushStringNewConnection.localizedStringWithUserName(name)
    }
}



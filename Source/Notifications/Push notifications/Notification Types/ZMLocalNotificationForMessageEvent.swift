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


import ZMUtilities

public func findIndex<S: SequenceType>(sequence: S, predicate: (S.Generator.Element) -> Bool) -> Int? {
    for (index, element) in sequence.enumerate() {
        if predicate(element) {
            return index
        }
    }
    return nil
}

let MaximumNumberOfEventsBeforeBundling = 5


public class ZMLocalNotificationForPostInConversationEvent : ZMLocalNotificationForEvent {
    
    override var requiresConversation : Bool {
        return true
    }
    
    var encryptedEventData : String? {
        guard let payload = lastEvent.payload as? [String : AnyObject]
        else { return nil }
        
        if let data = payload["data"] {
            if let data = data as? String {
                return data
            }
            if let data = data["info"] as? String {
                return data
            }
        }
        return nil
    }
    
    func messageAddEventHasPreexistingMessage(event: ZMUpdateEvent) -> Bool {
        if event.hasEncryptedAndUnencryptedVersion() {
            let nonce = event.messageNonce()
            let message = ZMMessage.fetchMessageWithNonce(nonce, forConversation: conversation, inManagedObjectContext: conversation!.managedObjectContext)
            return message != nil
        }
        return false
    }
}


public class ZMLocalNotificationForMessage: ZMLocalNotificationForPostInConversationEvent {
    var messageText : String?

    override var copiedEventTypes : [ZMUpdateEventType] {
        return [.ConversationMessageAdd, .ConversationAssetAdd, .ConversationOtrAssetAdd, .ConversationOtrMessageAdd]
    }
    
    override var shouldCopyNotifications : Bool {
        return events.count < MaximumNumberOfEventsBeforeBundling+1
    }
    
    override func canCreateNotification() -> Bool {
        guard super.canCreateNotification() && !messageAddEventHasPreexistingMessage(lastEvent)
            else { return false }
        
        switch lastEvent.type {
        case .ConversationOtrAssetAdd, .ConversationOtrMessageAdd:
            guard let encryptedEventData = encryptedEventData else { return false }
            
            var genericMessage : ZMGenericMessage?
            let exception = zm_tryBlock{
                genericMessage = ZMGenericMessage(base64String: encryptedEventData)
            }
            
            guard exception == nil,
                let message = genericMessage where (message.hasText() && message.text.content.characters.count > 0) || (message.hasImage())
            else { return false }
            
            if message.hasText() {
                messageText = message.text.content
            }
            return true
        case .ConversationMessageAdd:
            guard let text = eventData["content"] as? String where text.characters.count > 0
                else { return false }
            messageText = text
            return true
        case .ConversationAssetAdd:
            guard let tag = eventData["info"]?["tag"] as? String where tag == "medium"
                else { return false }
            return true
        default:
            return false
        }
    }
    
    // MARK : Notification content
    override func configureAlertBody() -> String {
        if events.count <= MaximumNumberOfEventsBeforeBundling && messageText != nil {
            return alertBody
        }
        if events.count == 1 && messageText == nil {
            return alertBodyForOneImageAddEvent
        }
        return alertBodyForMultipleMessageAddEvents
    }
    
    var alertBody : String {
        return ZMPushStringMessageAdd.localizedStringWithUser(sender, conversation: conversation, text:messageText!)
    }
    
    var alertBodyForOneImageAddEvent : String {
        return ZMPushStringImageAdd.localizedStringWithUser(sender, conversation: conversation)
    }
    
    var alertBodyForMultipleMessageAddEvents : String {
        let count = conversation!.estimatedUnreadCount + 1
        
        if conversation?.conversationType != .OneOnOne {
            return (ZMPushStringMessageAddMany + ".group").localizedStringWithConversation(conversation, count: count)
        } else {
            return (ZMPushStringMessageAddMany + ".oneonone").localizedStringWithUser(sender, count: count)
        }
    }
}


public class ZMLocalNotificationForKnockMessage : ZMLocalNotificationForPostInConversationEvent {
    
    override var copiedEventTypes : [ZMUpdateEventType] {
        return [.ConversationKnock, .ConversationOtrMessageAdd]
    }
    
    override func canCreateNotification() -> Bool {
        guard super.canCreateNotification() && !messageAddEventHasPreexistingMessage(lastEvent)
            else { return false }
        
        switch lastEvent.type {
        case .ConversationOtrMessageAdd:
            guard let encryptedEventData = encryptedEventData else { return false }
            
            var genericMessage : ZMGenericMessage?
            let exception = zm_tryBlock{
                genericMessage = ZMGenericMessage(base64String: encryptedEventData)
            }
            
            guard exception == nil,
                let message = genericMessage where message.hasKnock()
            else { return false }
            
            return true
        case .ConversationKnock:
            return true
        default:
            return false
        }
    }
    
    // MARK : Notification content
    override func configureAlertBody() -> String {
        let knockCount = NSNumber(integer: events.count)
        let aSender = allEventsAreFromSameSender ? self.sender : nil;
        return ZMPushStringKnock.localizedStringWithUser(aSender, conversation:self.conversation, count:knockCount)
    }

    override var soundName : String {
        return ZMLocalNotificationPingSoundName + ".caf"
    }
   
}


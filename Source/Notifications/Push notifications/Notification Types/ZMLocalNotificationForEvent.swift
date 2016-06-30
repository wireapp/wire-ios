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


let ZMLocalNotificationRingingDefaultSoundName = "ringing_from_them_long.caf"
let ZMLocalNotificationPingDefaultSoundName = "ping_from_them.caf"
let ZMLocalNotificationNewMessageDefaultSoundName = "new_message_apns.caf"


func ZMLocalNotificationRingingSoundName() -> String {
    if let soundName = NSUserDefaults.standardUserDefaults().objectForKey("ZMCallSoundName") as? String,
        let sound = ZMSound(rawValue: soundName) {
        return sound.filename()
    }
    else {
        return ZMLocalNotificationRingingDefaultSoundName
    }
}

func ZMLocalNotificationPingSoundName() -> String {
    if let soundName = NSUserDefaults.standardUserDefaults().objectForKey("ZMPingSoundName") as? String,
        let sound = ZMSound(rawValue: soundName) {
        return sound.filename()
    }
    else {
        return ZMLocalNotificationPingDefaultSoundName
    }
}

func ZMLocalNotificationNewMessageSoundName() -> String {
    if let soundName = NSUserDefaults.standardUserDefaults().objectForKey("ZMMessageSoundName") as? String,
        let sound = ZMSound(rawValue: soundName) {
        return sound.filename()
    }
    else {
        return ZMLocalNotificationNewMessageDefaultSoundName
    }
}

let ZMConversationCategory = "conversationCategory"
let ZMCallCategory = "callCategory"
let ZMConnectCategory = "connectCategory"


public extension ZMLocalNotificationForEvent {
    
    
    public static func notification(forEvent event: ZMUpdateEvent, managedObjectContext: NSManagedObjectContext, application: UIApplication?) -> ZMLocalNotificationForEvent? {
        switch event.type {
        case .ConversationOtrMessageAdd:
            if let note = ZMLocalNotificationForKnockMessage(event: event, managedObjectContext: managedObjectContext, application: application) {
                return note
            }
            return ZMLocalNotificationForMessage(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationAssetAdd, .ConversationMessageAdd, .ConversationOtrAssetAdd:
            return ZMLocalNotificationForMessage(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationConnectRequest:
            return ZMLocalNotificationForConnectionEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationKnock:
            return ZMLocalNotificationForKnockMessage(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationMemberJoin:
            return ZMLocalNotificationForMemberJoinEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationMemberLeave:
            return ZMLocalNotificationForMemberLeaveEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationRename:
            return ZMLocalNotificationForRenameEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .UserConnection:
            return ZMLocalNotificationForUserConnectionEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .ConversationCreate:
            return ZMLocalNotificationForConversationCreateEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .UserContactJoin:
            return ZMLocalNotificationForNewUserEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        case .CallState:
            return ZMLocalNotificationForCallEvent(event: event, managedObjectContext: managedObjectContext, application: application)
        default:
            return nil
        }
    }
}

@objc public protocol NotificationScheduler: NSObjectProtocol {
    func scheduleLocalNotification(notification: UILocalNotification);
    func cancelLocalNotification(notification: UILocalNotification);
}

extension UIApplication : NotificationScheduler {
}

public class ZMLocalNotificationForEvent : ZMLocalNotification {
    
    var lastEvent : ZMUpdateEvent {
        return events.last!
    }
    
    var eventData : [String : AnyObject] {
        return (lastEvent.payload as? [String : AnyObject])!["data"] as! [String : AnyObject]
    }

    public let notificationType : ZMLocalNotificationType = ZMLocalNotificationType.Event
    public let sender : ZMUser?
    let application : NotificationScheduler
    let managedObjectContext : NSManagedObjectContext
    public let conversation : ZMConversation?

    var events : [ZMUpdateEvent] = []
    public var notifications : [UILocalNotification] = []
    
    public convenience init?(event: ZMUpdateEvent, managedObjectContext: NSManagedObjectContext, application: NotificationScheduler?) {
       let conversation = ZMLocalNotificationForEvent.fetchConversation(event, managedObjectContext: managedObjectContext)
        self.init(events: [event], conversation: conversation, managedObjectContext: managedObjectContext, application:application)
    }
    
    required public init?(events: [ZMUpdateEvent], conversation: ZMConversation?, managedObjectContext: NSManagedObjectContext, application: NotificationScheduler?, copyFromNote: ZMLocalNotificationForEvent? = nil) {
        self.application = application ?? UIApplication.sharedApplication()
        self.conversation = conversation
        self.events = events
        if let senderUUID = events.last!.senderUUID() {
            self.sender = ZMUser(remoteID: senderUUID, createIfNeeded: false, inContext: managedObjectContext)
        } else {
            self.sender = nil
        }
        self.managedObjectContext = managedObjectContext
        super.init()
        
        if let note = copyFromNote {
            prepareForCopy(note)
        }
        
        if !canCreateNotification() { return nil }
        if shouldCreateNoficiationForLastEvent {
            let notification = configureNotification()
            notifications.append(notification)
        }
    }
    
    
    public func copyByAddingEvent(event: ZMUpdateEvent) -> ZMLocalNotificationForEvent? {
        if !canAddEvent(event) { return nil }
        events.append(event)
        
        guard let note =  self.dynamicType.init(events: events, conversation: conversation, managedObjectContext: managedObjectContext, application: application, copyFromNote:self)
        else { return nil }
        
        if note.shouldCopyNotifications {
            note.notifications = notifications + note.notifications
        } else {
            cancelNotifications()
        }
        return note
    }
    
    func cancelNotifications() {
        notifications.forEach{application.cancelLocalNotification($0)}
    }
    
    func configureNotification() -> UILocalNotification {
        let notification = UILocalNotification()
        notification.alertBody = configureAlertBody().stringByEscapingPercentageSymbols()
        notification.soundName = soundName
        notification.category = category
        notification.userInfo = userInfo
        return notification
    }
    
    var userInfo : [String: String] {
        var info : [String: String] = [:]
        if let convIDString = conversation?.objectIDURLString() {
            info[ZMLocalNotificationConversationObjectURLKey] = convIDString
        }
        if let senderUUIDString = lastEvent.senderUUID()?.transportString() {
            info[ZMLocalNotificationUserInfoSenderKey] = senderUUIDString
        }
        if let messageNonce = lastEvent.messageNonce()?.transportString() {
            info[ZMLocalNotificationUserInfoNonceKey] = messageNonce
        }
        if let eventID = lastEvent.eventID()?.transportString() {
            info["eventID"] = eventID
        }
        return info
    }
    
    var allSenderUUIDS : Set<NSUUID> {
        let senderIDs = events.flatMap{$0.senderUUID()}
        return Set(senderIDs)
    }
    
    var allEventsAreFromSameSender  : Bool {
        return allSenderUUIDS.count < 2
    }
    
    static func fetchConversation(event: ZMUpdateEvent, managedObjectContext : NSManagedObjectContext) -> ZMConversation? {
        if let uuid = event.conversationUUID() {
            return ZMConversation.fetchObjectWithRemoteIdentifier(uuid, inManagedObjectContext: managedObjectContext)
        }
        return nil
    }
    
    func senderIsSelfUser(event: ZMUpdateEvent) -> Bool {
        let selfUser = ZMUser.selfUserInContext(managedObjectContext)
        return (sender?.remoteIdentifier == selfUser.remoteIdentifier)
    }
    
    public func containsIdenticalEvent(event: ZMUpdateEvent) -> Bool {
        guard event.hasEncryptedAndUnencryptedVersion() && (copiedEventTypes.contains(event.type) || lastEvent.type == event.type),
            let conversation = conversation where conversation.remoteIdentifier == event.conversationUUID()
            else { return false }
        
        let idx = findIndex(events){$0.messageNonce() == event.messageNonce()}
        return idx != nil
    }
    
    
    /// You HAVE To override configureAlertBody() to configure the alert body
    func configureAlertBody() -> String { return "" }
    
    // MARK: Override these if needed
    
    /// if this returns true, it copies previous UILocalNotifications over, otherwise those get cancelled
    var shouldCopyNotifications : Bool { return false }
    /// set to true if notification depends / refers to a specific conversation
    var requiresConversation : Bool { return false }
    /// create a notification even if conversation is silenced
    var ignoresSilencedState : Bool { return false }
    /// if true, it will create a ZMLocalNotification but no UILocalNotification for this event, this will be true in most cases
    var shouldCreateNoficiationForLastEvent : Bool { return true }
    /// if true, it only copies events of the same sender
    var shouldCopyEventsOfSameSender : Bool { return false }
    
    /// if empty, it does not copy events
    var copiedEventTypes : [ZMUpdateEventType] { return [] }
    var soundName : String { return ZMLocalNotificationNewMessageSoundName() }
    var category : String { return ZMConversationCategory }
    
    /// you can copy additional properties from the previous notification to the new one
    func prepareForCopy(note: ZMLocalNotificationForEvent) { }
    
    func canCreateNotification() -> Bool {
        if ((conversation == nil) && requiresConversation) || (senderIsSelfUser(lastEvent) && lastEvent.type != .CallState ){
            return false
        }
        if let conversation = conversation where conversation.isSilenced && !ignoresSilencedState {
            return false
        }
        return true
    }
    
    func canAddEvent(event: ZMUpdateEvent) -> Bool {
        guard copiedEventTypes.contains(event.type),
            let conversation = conversation where
            conversation.remoteIdentifier == event.conversationUUID() && (!conversation.isSilenced || ignoresSilencedState)
        else {
            return false
        }
        if shouldCopyEventsOfSameSender && self.allSenderUUIDS.first != event.senderUUID() {
            return false
        }
        return true
    }
}





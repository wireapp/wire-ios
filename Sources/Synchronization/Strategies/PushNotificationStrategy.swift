//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

import WireRequestStrategy

public protocol NotificationSessionDelegate: class {
    func modifyNotification(_ alert: ClientNotification, messageCount: Int)
}

public struct ClientNotification {
    public var title: String
    public var body: String
}

final class PushNotificationStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource {
    
    var sync: NotificationStreamSync!
    private var pushNotificationStatus: PushNotificationStatus!
    private var eventProcessor: UpdateEventProcessor!
    private var delegate: NotificationSessionDelegate?
    private var moc: NSManagedObjectContext!

    private let useLegacyPushNotifications: Bool
    
    var eventDecoder: EventDecoder!
    var eventMOC: NSManagedObjectContext!
    
    init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
         eventContext: NSManagedObjectContext,
         applicationStatus: ApplicationStatus,
         pushNotificationStatus: PushNotificationStatus,
         notificationsTracker: NotificationsTracker?,
         notificationSessionDelegate: NotificationSessionDelegate?,
         useLegacyPushNotifications: Bool) {
        
        super.init(withManagedObjectContext: managedObjectContext,
                   applicationStatus: applicationStatus)
       
        sync = NotificationStreamSync(moc: managedObjectContext,
                                      notificationsTracker: notificationsTracker,
                                      delegate: self)
        self.eventProcessor = self
        self.pushNotificationStatus = pushNotificationStatus
        self.delegate = notificationSessionDelegate
        self.moc = managedObjectContext
        self.eventDecoder = EventDecoder(eventMOC: eventContext, syncMOC: managedObjectContext)
        self.useLegacyPushNotifications = useLegacyPushNotifications
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return isFetchingStreamForAPNS && !useLegacyPushNotifications ? requestGenerators.nextRequest() : nil
    }
    
    public override func nextRequest() -> ZMTransportRequest? {
        return isFetchingStreamForAPNS && !useLegacyPushNotifications ? requestGenerators.nextRequest() : nil
    }
    
    public var requestGenerators: [ZMRequestGenerator] {
           return [sync]
       }
    
    public var isFetchingStreamForAPNS: Bool {
        return self.pushNotificationStatus.hasEventsToFetch
    }

}

extension PushNotificationStrategy: NotificationStreamSyncDelegate {
    public func fetchedEvents(_ events: [ZMUpdateEvent], hasMoreToFetch: Bool) {
        var eventIds: [UUID] = []
        var parsedEvents: [ZMUpdateEvent] = []
        var latestEventId: UUID? = nil
        for event in events {
            event.appendDebugInformation("From missing update events transcoder, processUpdateEventsAndReturnLastNotificationIDFromPayload")
            parsedEvents.append(event)
            if let uuid = event.uuid {
                eventIds.append(uuid)
            }
            if !event.isTransient {
                latestEventId = event.uuid
            }
        }
        eventProcessor.storeUpdateEvents(parsedEvents, ignoreBuffer: true)
        pushNotificationStatus.didFetch(eventIds: eventIds, lastEventId: latestEventId, finished: hasMoreToFetch)
        
    }
    
    public func failedFetchingEvents() {
        pushNotificationStatus.didFailToFetchEvents()
    }
}

extension PushNotificationStrategy: UpdateEventProcessor {
    func processEventsIfReady() -> Bool {
        /// TODO check this
        return true
    }

    var eventConsumers: [ZMEventConsumer] {
        /// TODO check this
        get {
            return []
        }
        set(newValue) {
        }
    }

    public func storeUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        eventDecoder.decryptAndStoreEvents(updateEvents, block: { (decryptedUpdateEvents) in
            let localNotifications = self.convertToLocalNotifications(decryptedUpdateEvents, moc: self.moc)
            var alert = ClientNotification(title: "", body: "")
            if localNotifications.count == 1 {
                if let notification = localNotifications.first {
                    alert.title = notification.title ?? ""
                    alert.body = notification.body
                }
            }
            // The notification service extension API doesn't support generating multiple user notifications. In this case, the body text will be replaced in the UI project.
            
            self.delegate?.modifyNotification(alert, messageCount: localNotifications.count)
        })
    }
    
    public func storeAndProcessUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        // Events will be processed in the foreground
    }
}

// MARK: - Converting events to localNotifications
extension PushNotificationStrategy {
    private func convertToLocalNotifications(_ events: [ZMUpdateEvent], moc: NSManagedObjectContext) -> [ZMLocalNotification] {
        return events.compactMap { event in
            var conversation: ZMConversation?
            if let conversationID = event.conversationUUID {
                conversation = ZMConversation.fetch(with: conversationID, in: moc)
            }
            return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: moc)
        }
    }
}

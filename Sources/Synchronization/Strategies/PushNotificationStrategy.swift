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

public protocol LocalNotificationsDelegate: class {
    func shouldCreateNotificationWith(_ alert: (title: String, body: String), showNotification: Bool)
}

public final class PushNotificationStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource {
    
    var sync: NotificationStreamSync!
    private var pushNotificationStatus: PushNotificationStatus!
    private var eventProcessor: UpdateEventProcessor!
    private var delegate: LocalNotificationsDelegate?
    private var moc: NSManagedObjectContext!
    
    var eventDecoder: EventDecoder!
    var eventMOC: NSManagedObjectContext!
    
    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                pushNotificationStatus: PushNotificationStatus,
                notificationsTracker: NotificationsTracker?,
                localNotificationsDelegate: LocalNotificationsDelegate?,
                sharedContainerURL: URL,
                accountIdentifier: UUID,
                syncMOC: NSManagedObjectContext) {
        
        super.init(withManagedObjectContext: managedObjectContext,
                   applicationStatus: applicationStatus)
       
        sync = NotificationStreamSync(moc: managedObjectContext,
                                      notificationsTracker: notificationsTracker,
                                      delegate: self)
        self.eventProcessor = self
        self.pushNotificationStatus = pushNotificationStatus
        self.delegate = localNotificationsDelegate
        self.moc = managedObjectContext
        self.eventMOC = NSManagedObjectContext.createEventContext(withSharedContainerURL: sharedContainerURL, userIdentifier: accountIdentifier)
        self.eventDecoder = EventDecoder(eventMOC: eventMOC, syncMOC: syncMOC)
    }
    
    public override func nextRequestIfAllowed() -> ZMTransportRequest? {
        return requestGenerators.nextRequest()
    }
    
    public override func nextRequest() -> ZMTransportRequest? {
        return requestGenerators.nextRequest()
    }
    
    public var requestGenerators: [ZMRequestGenerator] {
           return [sync]
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
    public func storeUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        eventDecoder.decryptAndStoreEvents(updateEvents, block: { (decryptedUpdateEvents) in
            let localNotifications = self.didConvert(decryptedUpdateEvents, liveEvents: true, prefetchResult: nil, moc: self.moc).compactMap { $0 }
            var alert: (String, String) = ("", "")
            var showNotification = true
            switch localNotifications.count {
            case 0:
                showNotification = false
            case 1:
                if let notification = localNotifications.first {
                    alert = (notification.title ?? "", notification.body)
                }
            default:
                //bodyText = "\(localNotifications.count) " + "self.settings.notifications.push_notification.title".localized
                
                //TODO katerina: replace with a localized string
                let bodyText = "\(localNotifications.count) Notifications"
                alert = ("", bodyText)
            }
            self.delegate?.shouldCreateNotificationWith(alert, showNotification: showNotification)
        })
    }
    
    public func storeAndProcessUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
       // Events will be processed in the foreground
    }
    
}

// MARK: - Converting events to localNotifications

extension PushNotificationStrategy {
    private func didConvert(_ events: [ZMUpdateEvent], liveEvents: Bool, prefetchResult: ZMFetchRequestBatchResult?, moc: NSManagedObjectContext) -> [ZMLocalNotification?] {
        var localNotifications: [ZMLocalNotification?] = []
        let conversationMap =  prefetchResult?.conversationsByRemoteIdentifier ?? [:]
        let eventsToForward = events.filter { $0.source.isOne(of: .pushNotification, .webSocket) }
        
        eventsToForward.forEach { event in
            var conversation: ZMConversation?
            if let conversationID = event.conversationUUID {
                // Fetch the conversation here to avoid refetching every time we try to create a notification
                conversation = conversationMap[conversationID] ?? ZMConversation.fetch(withRemoteIdentifier: conversationID, in: moc)
            }
            
            let note = ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: moc)
            localNotifications.append(note)
        }
        return localNotifications
    }
}

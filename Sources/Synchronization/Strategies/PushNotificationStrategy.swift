//
// Wire
// Copyright (C) 2022 Wire Swiss GmbH
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
import Foundation

public protocol NotificationSessionDelegate: AnyObject {

    func notificationSessionDidGenerateNotification(_ notification: ZMLocalNotification?, unreadConversationCount: Int)

}

final class PushNotificationStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource, UpdateEventProcessor {
    
    var sync: NotificationStreamSync!
    private var pushNotificationStatus: PushNotificationStatus!
    private var eventProcessor: UpdateEventProcessor!
    private var moc: NSManagedObjectContext!
    private var localNotifications = [ZMLocalNotification]()

    private weak var delegate: NotificationSessionDelegate?

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

        self.useLegacyPushNotifications = useLegacyPushNotifications
        
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
    }
    
    public override func nextRequestIfAllowed(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return isFetchingStreamForAPNS && !useLegacyPushNotifications ? requestGenerators.nextRequest(for: apiVersion) : nil
    }
    
    public override func nextRequest(for apiVersion: APIVersion) -> ZMTransportRequest? {
        return isFetchingStreamForAPNS && !useLegacyPushNotifications ? requestGenerators.nextRequest(for: apiVersion) : nil
    }
    
    public var requestGenerators: [ZMRequestGenerator] {
           return [sync]
       }
    
    public var isFetchingStreamForAPNS: Bool {
        return self.pushNotificationStatus.hasEventsToFetch
    }

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
        eventDecoder.decryptAndStoreEvents(updateEvents) { decryptedUpdateEvents in
            let notifications = self.convertToLocalNotifications(decryptedUpdateEvents, moc: self.moc)
            self.localNotifications.append(contentsOf: notifications)
        }
    }

    public func storeAndProcessUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        // Events will be processed in the foreground
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
        pushNotificationStatus.didFetch(eventIds: eventIds, lastEventId: latestEventId, finished: !hasMoreToFetch)

        if !hasMoreToFetch {
            // We should only process local notifications once after we've finished fetching
            // all events because otherwise we tell the delegate (i.e the notification
            // service extension) to use its content handler more than once, which may lead
            // to unexpected behavior.
            processLocalNotifications()
            localNotifications.removeAll()
        }
    }

    private func processLocalNotifications() {
        let notification: ZMLocalNotification?

        if localNotifications.count > 1 {
            notification = ZMLocalNotification.bundledMessages(count: localNotifications.count, in: moc)
        } else {
            notification = localNotifications.first
        }
        let unreadCount = Int(ZMConversation.unreadConversationCount(in: moc))
        delegate?.notificationSessionDidGenerateNotification(notification, unreadConversationCount: unreadCount)
    }
    
    public func failedFetchingEvents() {
        pushNotificationStatus.didFailToFetchEvents()
    }

}

// MARK: - Converting events to localNotifications

extension PushNotificationStrategy {

    private func convertToLocalNotifications(_ events: [ZMUpdateEvent], moc: NSManagedObjectContext) -> [ZMLocalNotification] {
        return events.compactMap { event in
            return notification(from: event, in: moc)
        }
    }

    private func notification(from event: ZMUpdateEvent, in context: NSManagedObjectContext) -> ZMLocalNotification? {
        var note: ZMLocalNotification?
        guard
            let conversationID = event.conversationUUID,
            let conversation = ZMConversation.fetch(with: conversationID, in: context)
        else {
            return nil
        }

        if let callEventContent = CallEventContent(from: event) {
            let currentTimestamp = Date().addingTimeInterval(managedObjectContext.serverTimeDelta)

            /// The caller should not be the same as the user receiving the call event and
            /// the age of the event is less than 30 seconds
            guard let callState = callEventContent.callState,
                  let callerID = callEventContent.callerID,
                  let caller = ZMUser.fetch(with: callerID, domain: event.senderDomain, in: context),
                  caller != ZMUser.selfUser(in: context),
                  !isEventTimedOut(currentTimestamp: currentTimestamp, eventTimestamp: event.timestamp) else {
                      return nil
                  }
            note = ZMLocalNotification.init(callState: callState, conversation: conversation, caller: caller, moc: context)
        } else {
            note = ZMLocalNotification.init(event: event, conversation: conversation, managedObjectContext: context)
        }

        note?.increaseEstimatedUnreadCount(on: conversation)
        return note
    }

    private func isEventTimedOut(currentTimestamp: Date, eventTimestamp: Date?) -> Bool {
        guard let eventTimestamp = eventTimestamp else {
            return true
        }

        return Int(currentTimestamp.timeIntervalSince(eventTimestamp)) > 30
    }

}

// MARK: - Helpers

private extension CallEventContent {

    init?(from event: ZMUpdateEvent) {
        guard
            event.type == .conversationOtrMessageAdd,
            let message = GenericMessage(from: event),
            message.hasCalling,
            let payload = message.calling.content.data(using: .utf8, allowLossyConversion: false)
        else {
            return nil
        }

        self.init(from: payload)
    }

}

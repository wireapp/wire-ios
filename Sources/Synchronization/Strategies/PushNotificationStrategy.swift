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

public final class PushNotificationStrategy: AbstractRequestStrategy, ZMRequestGeneratorSource {
    
    var sync: NotificationStreamSync!
    private var pushNotificationStatus: PushNotificationStatus!
    private var eventProcessor: UpdateEventProcessor!
//    private var eventDecoder: EventDecoder!
    
    public init(withManagedObjectContext managedObjectContext: NSManagedObjectContext,
                applicationStatus: ApplicationStatus,
                pushNotificationStatus: PushNotificationStatus,
                notificationsTracker: NotificationsTracker?/*,
                eventMOC: NSManagedObjectContext,
                syncMOC: NSManagedObjectContext*/) {
        
        super.init(withManagedObjectContext: managedObjectContext,
                   applicationStatus: applicationStatus)
       
        sync = NotificationStreamSync(moc: managedObjectContext,
                                      notificationsTracker: notificationsTracker,
                                      delegate: self)
        self.eventProcessor = self
        self.pushNotificationStatus = pushNotificationStatus
//        eventDecoder = EventDecoder(eventMOC: eventMOC, syncMOC: syncMOC)
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
        eventProcessor.process(updateEvents: parsedEvents, ignoreBuffer: true)
        pushNotificationStatus.didFetch(eventIds: eventIds, lastEventId: latestEventId, finished: hasMoreToFetch)
        
    }
    
    public func failedFetchingEvents() {
        pushNotificationStatus.didFailToFetchEvents()
    }
}

extension PushNotificationStrategy: UpdateEventProcessor {
    
    public func process(updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        //        if ignoreBuffer || isReadyToProcessEvents {
        consume(updateEvents: updateEvents)
        //        } else {
        //            Logging.eventProcessing.info("Buffering \(updateEvents.count) event(s)")
        //            updateEvents.forEach(eventsBuffer.addUpdateEvent)
        //        }
    }
    
    public func consume(updateEvents: [ZMUpdateEvent]) {
    
        for event in updateEvents {
            
        }
//        eventDecoder.processEvents(updateEvents) { [weak self] (decryptedUpdateEvents) in
//            guard let `self` = self else { return }
//            
//            let date = Date()
//            let fetchRequest = prefetchRequest(updateEvents: decryptedUpdateEvents)
//            let prefetchResult = syncMOC.executeFetchRequestBatchOrAssert(fetchRequest)
//            
//            Logging.eventProcessing.info("Consuming: [\n\(decryptedUpdateEvents.map({ "\tevent: \(ZMUpdateEvent.eventTypeString(for: $0.type) ?? "Unknown")" }).joined(separator: "\n"))\n]")
//            
//            for event in decryptedUpdateEvents {
//                for eventConsumer in self.eventConsumers {
//                    eventConsumer.processEvents([event], liveEvents: true, prefetchResult: prefetchResult)
//                }
//                self.eventProcessingTracker?.registerEventProcessed()
//            }
//            localNotificationDispatcher?.processEvents(decryptedUpdateEvents, liveEvents: true, prefetchResult: nil)
//            
//            if let messages = fetchRequest.noncesToFetch as? Set<UUID>,
//                let conversations = fetchRequest.remoteIdentifiersToFetch as? Set<UUID> {
//                let confirmationMessages = ZMConversation.confirmDeliveredMessages(messages, in: conversations, with: syncMOC)
//                for message in confirmationMessages {
//                    self.applicationStatusDirectory?.deliveryConfirmation.needsToConfirmMessage(message.nonce!)
//                }
//            }
//            
//            syncMOC.saveOrRollback()
//            
//            Logging.eventProcessing.debug("Events processed in \(-date.timeIntervalSinceNow): \(self.eventProcessingTracker?.debugDescription ?? "")")
//            
//        }
//        
    }
}

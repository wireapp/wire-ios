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

import Foundation
import WireUtilities
import WireRequestStrategy

extension NSNotification.Name {
    static let calculateBadgeCount = NSNotification.Name(rawValue: "calculateBadgeCountNotication")
}

class EventProcessor: UpdateEventProcessor {

    private static let logger = Logger(subsystem: "VoIP Push", category: "EventProcessor")

    let syncContext: NSManagedObjectContext
    let eventContext: NSManagedObjectContext
    let operationStateProvider: OperationStateProvider
    let syncStatus: SyncStatus
    var eventBuffer: ZMUpdateEventsBuffer?
    let eventDecoder: EventDecoder
    let eventProcessingTracker: EventProcessingTrackerProtocol
    let earService: EARServiceInterface

    public var eventConsumers: [ZMEventConsumer] = []

    var isReadyToProcessEvents: Bool {
        switch operationStateProvider.operationState {
        case .backgroundPendingCall:
            return !syncStatus.isSyncingInBackground

        default:
            return !syncStatus.isSyncing && !syncContext.isLocked
        }
    }

    // MARK: Life Cycle

    init(
        storeProvider: CoreDataStack,
        syncStatus: SyncStatus,
        operationStateProvider: OperationStateProvider,
        eventProcessingTracker: EventProcessingTrackerProtocol,
        earService: EARServiceInterface
    ) {
        self.syncContext = storeProvider.syncContext
        self.eventContext = storeProvider.eventContext
        self.syncStatus = syncStatus
        self.operationStateProvider = operationStateProvider
        self.eventDecoder = EventDecoder(eventMOC: eventContext, syncMOC: syncContext)
        self.eventProcessingTracker = eventProcessingTracker
        self.earService = earService
        self.eventBuffer = ZMUpdateEventsBuffer(updateEventProcessor: self)
    }

    // MARK: Methods

    /// Process previously received events if we are ready to process events.
    ///
    // - Returns: **True** if there are still more events to process
    @objc
    public func processEventsIfReady() -> Bool { // TODO jacob shouldn't be public
        Self.logger.trace("process events if ready")
        guard isReadyToProcessEvents else {
            Self.logger.info("not ready to process events")
            return  true
        }

        eventBuffer?.processAllEventsInBuffer()

        if syncContext.encryptMessagesAtRest {
            do {
                Self.logger.info("trying to get EAR keys")
                let privateKeys = try earService.fetchPrivateKeys()
                processStoredUpdateEvents(with: privateKeys)
            } catch {
                Self.logger.error("failed to fetch EAR keys: \(String(describing: error))")
                return true
            }
        } else {
            processStoredUpdateEvents()
        }

        return false
    }

    public func storeUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        if ignoreBuffer || isReadyToProcessEvents {
            let publicKeys = try? earService.fetchPublicKeys()

            eventDecoder.decryptAndStoreEvents(
                updateEvents,
                publicKeys: publicKeys
            ) { [weak self] (decryptedEvents) in
                guard let `self` = self else { return }

                Logging.eventProcessing.info("Consuming events while in background")
                for eventConsumer in self.eventConsumers {
                    eventConsumer.processEventsWhileInBackground?(decryptedEvents)
                }
                self.syncContext.saveOrRollback()
                NotificationInContext(name: .calculateBadgeCount, context: self.syncContext.notificationContext).post()
            }
        } else {
            Logging.eventProcessing.info("Buffering \(updateEvents.count) event(s)")
            updateEvents.forEach({ eventBuffer?.addUpdateEvent($0) })
        }
    }

    public func storeAndProcessUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) {
        storeUpdateEvents(updateEvents, ignoreBuffer: ignoreBuffer)
        _ = processEventsIfReady()
    }

    private func processStoredUpdateEvents(with privateKeys: EARPrivateKeys? = nil) {
        Self.logger.trace("process stored update events")

        eventDecoder.processStoredEvents(with: privateKeys) { [weak self] (decryptedUpdateEvents) in
            Self.logger.info("decrypted update events: \(decryptedUpdateEvents.count)")

            guard let `self` = self else { return }

            let date = Date()
            let fetchRequest = prefetchRequest(updateEvents: decryptedUpdateEvents)
            let prefetchResult = syncContext.executeFetchRequestBatchOrAssert(fetchRequest)

            Logging.eventProcessing.info("Consuming: [\n\(decryptedUpdateEvents.map({ "\tevent: \(ZMUpdateEvent.eventTypeString(for: $0.type) ?? "Unknown")" }).joined(separator: "\n"))\n]")

            for event in decryptedUpdateEvents {
                for eventConsumer in self.eventConsumers {
                    eventConsumer.processEvents([event], liveEvents: true, prefetchResult: prefetchResult)
                }
                self.eventProcessingTracker.registerEventProcessed()
            }
            ZMConversation.calculateLastUnreadMessages(in: syncContext)
            syncContext.saveOrRollback()

            Logging.eventProcessing.debug("Events processed in \(-date.timeIntervalSinceNow): \(self.eventProcessingTracker.debugDescription)")
        }
    }

    @objc(prefetchRequestForUpdateEvents:)
    public func prefetchRequest(updateEvents: [ZMUpdateEvent]) -> ZMFetchRequestBatch {
        var messageNounces: Set<UUID> = Set()
        var conversationNounces: Set<UUID> = Set()

        for eventConsumer in eventConsumers {
            if let messageNoncesToPrefetch = eventConsumer.messageNoncesToPrefetch?(toProcessEvents: updateEvents) {
                messageNounces.formUnion(messageNoncesToPrefetch)
            }

            if let conversationRemoteIdentifiersToPrefetch = eventConsumer.conversationRemoteIdentifiersToPrefetch?(toProcessEvents: updateEvents) {
                conversationNounces.formUnion(conversationRemoteIdentifiersToPrefetch)
            }
        }

        let fetchRequest = ZMFetchRequestBatch()
        fetchRequest.addNonces(toPrefetchMessages: messageNounces)
        fetchRequest.addConversationRemoteIdentifiers(toPrefetchConversations: conversationNounces)

        return fetchRequest
    }

}

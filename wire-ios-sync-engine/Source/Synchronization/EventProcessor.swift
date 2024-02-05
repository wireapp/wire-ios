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

actor EventProcessor: UpdateEventProcessor {

    private static let logger = Logger(subsystem: "VoIP Push", category: "EventProcessor")

    private let syncContext: NSManagedObjectContext
    private let eventContext: NSManagedObjectContext
    private var bufferedEvents: [ZMUpdateEvent]
    private let eventDecoder: EventDecoder
    private let eventProcessingTracker: EventProcessingTrackerProtocol
    private let earService: EARServiceInterface
    private var processingTask: Task<Void, Error>?
    private let eventConsumers: [ZMEventConsumer]
    private let eventAsyncConsumers: [ZMEventAsyncConsumer]

    // MARK: Life Cycle

    init(
        storeProvider: CoreDataStack,
        eventProcessingTracker: EventProcessingTrackerProtocol,
        earService: EARServiceInterface,
        eventConsumers: [ZMEventConsumer],
        eventAsyncConsumers: [ZMEventAsyncConsumer]
    ) {
        self.syncContext = storeProvider.syncContext
        self.eventContext = storeProvider.eventContext
        self.eventDecoder = EventDecoder(eventMOC: eventContext, syncMOC: syncContext)
        self.eventProcessingTracker = eventProcessingTracker
        self.earService = earService
        self.bufferedEvents = []
        self.eventConsumers = eventConsumers
        self.eventAsyncConsumers = eventAsyncConsumers
    }

    // MARK: Methods

    func bufferEvents(_ events: [ZMUpdateEvent]) async {
        guard !DeveloperFlag.ignoreIncomingEvents.isOn else { return }
        bufferedEvents.append(contentsOf: events)
    }

    func processEvents(_ events: [ZMUpdateEvent]) async throws {
        try await enqueueTask {
            NotificationCenter.default.post(name: .eventProcessorDidStartProcessingEventsNotification, object: self)

            guard !DeveloperFlag.ignoreIncomingEvents.isOn else { return }
            let publicKeys = try? self.earService.fetchPublicKeys()
            let decryptedEvents = await self.eventDecoder.decryptAndStoreEvents(events, publicKeys: publicKeys)
            await self.processBackgroundEvents(decryptedEvents)
            let isLocked = await self.syncContext.perform { self.syncContext.isLocked }
            try await self.processEvents(callEventsOnly: isLocked)
            await self.requestToCalculateBadgeCount()
            NotificationCenter.default.post(name: .eventProcessorDidFinishProcessingEventsNotification, object: self)
        }
    }

    func processBufferedEvents() async throws {
        let events = bufferedEvents
        bufferedEvents.removeAll()
        try await processEvents(events)
    }

    private func enqueueTask(_ block: @escaping @Sendable () async throws -> Void) async throws {
        processingTask = Task { [processingTask] in
            _ = await processingTask?.result
            return try await block()
        }

        // throw error if any
        _ = try await processingTask?.value
    }

    private func processBackgroundEvents(_ events: [ZMUpdateEvent]) async {
        await syncContext.perform {
            for eventConsumer in self.eventConsumers {
                eventConsumer.processEventsWhileInBackground?(events)
            }
        }
    }

    private func requestToCalculateBadgeCount() async {
        await self.syncContext.perform {
            self.syncContext.saveOrRollback()
            NotificationInContext(name: .calculateBadgeCount, context: self.syncContext.notificationContext).post()
        }
    }

    private func processEvents(callEventsOnly: Bool) async throws {
        WireLogger.updateEvent.info("process pending events (callEventsOnly: \(callEventsOnly)")

        let encryptMessagesAtRest = await syncContext.perform {
            self.syncContext.encryptMessagesAtRest
        }
        if encryptMessagesAtRest {
            do {
                WireLogger.updateEvent.info("trying to get EAR keys")
                let privateKeys = try earService.fetchPrivateKeys(includingPrimary: !callEventsOnly)
                await processStoredUpdateEvents(with: privateKeys, callEventsOnly: callEventsOnly)
            } catch {
                WireLogger.updateEvent.error("failed to fetch EAR keys: \(String(describing: error))")
                throw error
            }
        } else {
            await processStoredUpdateEvents(callEventsOnly: callEventsOnly)
        }
    }

    private func processStoredUpdateEvents(
        with privateKeys: EARPrivateKeys? = nil,
        callEventsOnly: Bool = false
    ) async {
        WireLogger.updateEvent.info("process stored update events (callEventsOnly: \(callEventsOnly))")

        await eventDecoder.processStoredEvents(
            with: privateKeys,
            callEventsOnly: callEventsOnly
        ) { [weak self] (decryptedUpdateEvents) in
            WireLogger.updateEvent.info("retrieved \(decryptedUpdateEvents.count) events from the database")

            guard let self else { return }

            let date = Date()
            let fetchRequest = await prefetchRequest(updateEvents: decryptedUpdateEvents)
            let prefetchResult = await syncContext.perform { self.syncContext.executeFetchRequestBatchOrAssert(fetchRequest) }

            let eventDescriptions = decryptedUpdateEvents.map {
                ZMUpdateEvent.eventTypeString(for: $0.type) ?? "unknown"
            }

            WireLogger.updateEvent.info("consuming events: \(eventDescriptions)")

            Logging.eventProcessing.info("Consuming: [\n\(decryptedUpdateEvents.map({ "\tevent: \(ZMUpdateEvent.eventTypeString(for: $0.type) ?? "Unknown")" }).joined(separator: "\n"))\n]")

            for event in decryptedUpdateEvents {
                await syncContext.perform {
                    for eventConsumer in self.eventConsumers {
                        eventConsumer.processEvents([event], liveEvents: true, prefetchResult: prefetchResult)
                    }
                }
                // swiftlint:disable todo_requires_jira_link
                // TODO: [F] @Jacob should this be done on syncContext to keep every thing in sync?
                // swiftlint:enable todo_requires_jira_link
                for eventConsumer in self.eventAsyncConsumers {
                    await eventConsumer.processEvents([event], liveEvents: true, prefetchResult: prefetchResult)
                }
            }

            await syncContext.perform {
                self.eventProcessingTracker.registerEventProcessed()
                ZMConversation.calculateLastUnreadMessages(in: self.syncContext)
                self.syncContext.saveOrRollback()
            }

            WireLogger.updateEvent.debug("Events processed in \(-date.timeIntervalSinceNow): \(self.eventProcessingTracker.debugDescription)")
        }
    }

    @objc(prefetchRequestForUpdateEvents:completion:)
    public func prefetchRequest(updateEvents: [ZMUpdateEvent]) async -> ZMFetchRequestBatch {
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

extension Notification.Name {

    static let calculateBadgeCount = Self(rawValue: "calculateBadgeCountNotication")

    /// Published before the first event is processed.
    static let eventProcessorDidStartProcessingEventsNotification = Self("EventProcessorDidStartProcessingEvents")

    /// Published after the last event has been processed.
    static let eventProcessorDidFinishProcessingEventsNotification = Self("EventProcessorDidFinishProcessingEvents")
}

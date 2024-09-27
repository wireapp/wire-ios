//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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
import WireRequestStrategy
import WireUtilities

// MARK: - EventProcessor

actor EventProcessor: UpdateEventProcessor {
    private static let logger = Logger(subsystem: "VoIP Push", category: "EventProcessor")

    private let syncContext: NSManagedObjectContext
    private let eventContext: NSManagedObjectContext
    private var bufferedEvents: [ZMUpdateEvent]
    private let eventDecoder: any EventDecoderProtocol
    private let eventProcessingTracker: EventProcessingTrackerProtocol
    private let earService: EARServiceInterface
    private var processingTask: Task<Void, Error>?
    private let eventConsumers: [ZMEventConsumer]
    private let eventAsyncConsumers: [ZMEventAsyncConsumer]

    private let processedEventList = ProcessedEventList()

    // MARK: Life Cycle

    init(
        storeProvider: CoreDataStack,
        eventProcessingTracker: EventProcessingTrackerProtocol,
        earService: EARServiceInterface,
        eventConsumers: [ZMEventConsumer],
        eventAsyncConsumers: [ZMEventAsyncConsumer],
        lastEventIDRepository: LastEventIDRepositoryInterface
    ) {
        let eventDecoder = EventDecoder(
            eventMOC: storeProvider.eventContext,
            syncMOC: storeProvider.syncContext,
            lastEventIDRepository: lastEventIDRepository
        )

        self.init(
            storeProvider: storeProvider,
            eventDecoder: eventDecoder,
            eventProcessingTracker: eventProcessingTracker,
            earService: earService,
            eventConsumers: eventConsumers,
            eventAsyncConsumers: eventAsyncConsumers
        )
    }

    init(
        storeProvider: CoreDataStack,
        eventDecoder: any EventDecoderProtocol,
        eventProcessingTracker: EventProcessingTrackerProtocol,
        earService: EARServiceInterface,
        eventConsumers: [ZMEventConsumer],
        eventAsyncConsumers: [ZMEventAsyncConsumer]
    ) {
        self.syncContext = storeProvider.syncContext
        self.eventContext = storeProvider.eventContext
        self.eventDecoder = eventDecoder
        self.eventProcessingTracker = eventProcessingTracker
        self.earService = earService
        self.bufferedEvents = []
        self.eventConsumers = eventConsumers
        self.eventAsyncConsumers = eventAsyncConsumers
    }

    // MARK: Methods

    func bufferEvents(_ events: [ZMUpdateEvent]) async {
        guard !DeveloperFlag.ignoreIncomingEvents.isOn else { return }
        for event in events {
            WireLogger.updateEvent.debug("buffer event", attributes: event.logAttributes)
        }
        bufferedEvents.append(contentsOf: events)
    }

    func processEvents(_ events: [ZMUpdateEvent]) async throws {
        try await enqueueTask {
            NotificationCenter.default.post(name: .eventProcessorDidStartProcessingEventsNotification, object: self)

            guard !DeveloperFlag.ignoreIncomingEvents.isOn else { return }

            let publicKeys = try? self.earService.fetchPublicKeys()
            let decryptedEvents = try await self.eventDecoder.decryptAndStoreEvents(events, publicKeys: publicKeys)
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
        defer { processingTask = nil }

        processingTask = Task { [processingTask] in
            _ = try await processingTask?.value
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
        await syncContext.perform {
            self.syncContext.saveOrRollback()
            NotificationInContext(name: .calculateBadgeCount, context: self.syncContext.notificationContext).post()
        }
    }

    private func processEvents(callEventsOnly: Bool) async throws {
        WireLogger.updateEvent.info("process pending events: callEventsOnly=\(callEventsOnly)")

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

    func processStoredUpdateEvents(
        with privateKeys: EARPrivateKeys? = nil,
        callEventsOnly: Bool = false
    ) async {
        WireLogger.updateEvent.info("process stored update events (callEventsOnly: \(callEventsOnly))")

        await eventDecoder.processStoredEvents(
            with: privateKeys,
            callEventsOnly: callEventsOnly
        ) { [weak self] decryptedUpdateEvents in
            WireLogger.updateEvent.info(
                "retrieved \(decryptedUpdateEvents.count) events from the database",
                attributes: .safePublic
            )

            guard let self else { return }

            let date = Date()
            let fetchRequest = await prefetchRequest(updateEvents: decryptedUpdateEvents)
            let prefetchResult = await syncContext
                .perform { self.syncContext.executeFetchRequestBatchOrAssert(fetchRequest) }

            let eventDescriptions = decryptedUpdateEvents.map {
                ZMUpdateEvent.eventTypeString(for: $0.type) ?? "unknown"
            }

            WireLogger.updateEvent.info("consuming events: \(eventDescriptions)", attributes: .safePublic)

            WireLogger.eventProcessing
                .info(
                    "Consuming: [\n\(decryptedUpdateEvents.map { "\tevent: \(ZMUpdateEvent.eventTypeString(for: $0.type) ?? "Unknown")" }.joined(separator: "\n"))\n]"
                )

            for event in decryptedUpdateEvents {
                WireLogger.updateEvent.info("process decrypted event", attributes: event.logAttributes)

                // Workaround: there's a concurrency bug where a stored event was fetched
                // and processed, then before it could be deleted, a second pass refetched
                // the same event and processed it again. It's not known why this happens,
                // but in the meantime we will avoid processing an event more than once.
                guard await !processedEventList.containsEvent(event) else {
                    WireLogger.updateEvent.warn(
                        "event already processed, skipping...",
                        attributes: event.logAttributes
                    )
                    continue
                }

                await syncContext.perform {
                    for eventConsumer in self.eventConsumers {
                        eventConsumer.processEvents([event], liveEvents: true, prefetchResult: prefetchResult)
                    }
                }

                for eventConsumer in eventAsyncConsumers {
                    await eventConsumer.processEvents([event])
                }

                await processedEventList.addEvent(event)
            }

            await syncContext.perform {
                self.eventProcessingTracker.registerEventProcessed()
                ZMConversation.calculateLastUnreadMessages(in: self.syncContext)
                self.syncContext.saveOrRollback()
            }

            WireLogger.updateEvent
                .debug(
                    "Events processed in \(-date.timeIntervalSinceNow): \(eventProcessingTracker.debugDescription)"
                )
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

            if let conversationRemoteIdentifiersToPrefetch = eventConsumer
                .conversationRemoteIdentifiersToPrefetch?(toProcessEvents: updateEvents) {
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

// MARK: - ProcessedEventList

private actor ProcessedEventList {
    private var hashes = Set<Int64>()

    // A full list would contain approx 80kB.
    private let capacity = 10000

    func addEvent(_ event: ZMUpdateEvent) {
        guard let hash = event.contentHash else {
            assertionFailure("events for processing should have a content hash")
            return
        }

        if hashes.count >= capacity, let randomElement = hashes.randomElement() {
            hashes.remove(randomElement)
        }

        hashes.insert(hash)
    }

    func containsEvent(_ event: ZMUpdateEvent) -> Bool {
        guard let hash = event.contentHash else {
            assertionFailure("events for processing should have a content hash")
            return false
        }

        return hashes.contains(hash)
    }
}

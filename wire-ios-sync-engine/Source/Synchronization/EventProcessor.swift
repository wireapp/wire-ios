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

actor EventProcessor: UpdateEventProcessor {

    private static let logger = Logger(subsystem: "VoIP Push", category: "EventProcessor")

    let syncContext: NSManagedObjectContext
    let eventContext: NSManagedObjectContext
    let syncStatus: SyncStatus
    private var bufferedEvents: [ZMUpdateEvent]
    let eventDecoder: EventDecoder
    let eventProcessingTracker: EventProcessingTrackerProtocol
    let earService: EARServiceInterface
    var decryptingTask: Task<Void, Error>?
    var processingTask: Task<Void, Error>?

    private let eventConsumers: [ZMEventConsumer]

    var isReadyToProcessEvents: Bool {
        get async {
            await syncContext.perform {
                // Only process events once we've finished fetching events.
                guard !self.syncStatus.isSyncing else { return false }

                // If the database is locked, then we won't be able to process events
                // that require writes to the database.
                guard !self.syncContext.isLocked else { return false }

                // Don't process events if this developer flag is on
                guard !DeveloperFlag.ignoreIncomingEvents.isOn else { return false }

                return true
            }
        }
    }

    // MARK: Life Cycle

    init(
        storeProvider: CoreDataStack,
        syncStatus: SyncStatus,
        eventProcessingTracker: EventProcessingTrackerProtocol,
        earService: EARServiceInterface,
        eventConsumers: [ZMEventConsumer]
    ) {
        self.syncContext = storeProvider.syncContext
        self.eventContext = storeProvider.eventContext
        self.syncStatus = syncStatus
        self.eventDecoder = EventDecoder(eventMOC: eventContext, syncMOC: syncContext)
        self.eventProcessingTracker = eventProcessingTracker
        self.earService = earService
        self.bufferedEvents = []
        self.eventConsumers = eventConsumers
    }

    // MARK: Methods

    /// Process previously received events if we are ready to process events.
    ///
    /// - Returns: **True** if there are still more events to process
    @objc
    public func processEventsIfReady() async -> Bool { // TODO jacob shouldn't be public
        WireLogger.updateEvent.info("process events if ready")

        guard await isReadyToProcessEvents else {
            WireLogger.updateEvent.info("not ready to process events")
            return true
        }

        await self.processAllEventsInBuffer()

        var hasMoreEventsToProcess = false
        do {
            try await self.processEvents(callEventsOnly: false)
        } catch {
            hasMoreEventsToProcess = true
        }

        return hasMoreEventsToProcess
    }

    private func processTask(_ block: @escaping @Sendable () async throws -> Void) async throws {
        if let existingProcessingTask = processingTask {
            return try await existingProcessingTask.value
        }

        let task: Task<Void, Error> = Task(operation: block)
        processingTask = task
        try await task.value
        processingTask = nil
    }

    private func decryptTask(_ block: @escaping @Sendable () async throws -> Void) async throws {
        try await decryptingTask?.value
        let task: Task<Void, Error> = Task(operation: block)
        decryptingTask = task
        try await task.value
        decryptingTask = nil
    }

    func processPendingCallEvents() async throws {
        await self.processAllEventsInBuffer()
        try await self.processEvents(callEventsOnly: true)
    }

    private func processEvents(callEventsOnly: Bool) async throws {
        try await processTask { [self] in
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
    }

    public func storeUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) async {
            if await isReadyToProcessEvents || ignoreBuffer {
                try? await decryptTask { [self] in
                    let publicKeys = try? earService.fetchPublicKeys()

                    let decryptedEvents = await eventDecoder.decryptAndStoreEvents(
                        updateEvents,
                        publicKeys: publicKeys
                    )

                    Logging.eventProcessing.info("Consuming events while in background")
                    for eventConsumer in self.eventConsumers {
                        eventConsumer.processEventsWhileInBackground?(decryptedEvents)
                    }
                    await self.syncContext.perform {
                        self.syncContext.saveOrRollback()
                        NotificationInContext(name: .calculateBadgeCount, context: self.syncContext.notificationContext).post()
                    }
                }
            } else if !DeveloperFlag.ignoreIncomingEvents.isOn {
                Logging.eventProcessing.info("Buffering \(updateEvents.count) event(s)")
                self.bufferedEvents = updateEvents
            }
    }

    public func storeAndProcessUpdateEvents(_ updateEvents: [ZMUpdateEvent], ignoreBuffer: Bool) async {
        await storeUpdateEvents(updateEvents, ignoreBuffer: ignoreBuffer)
        let isLocked = await syncContext.perform { self.syncContext.isLocked }

        if isLocked {
            try? await processPendingCallEvents()
        } else {
            _ = await processEventsIfReady()
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

            guard let `self` = self else { return }

            let date = Date()
            let fetchRequest = await prefetchRequest(updateEvents: decryptedUpdateEvents)
            let prefetchResult = await syncContext.perform { self.syncContext.executeFetchRequestBatchOrAssert(fetchRequest) }

            let eventDescriptions = decryptedUpdateEvents.map {
                ZMUpdateEvent.eventTypeString(for: $0.type) ?? "unknown"
            }

            WireLogger.updateEvent.info("consuming events: \(eventDescriptions)")

            Logging.eventProcessing.info("Consuming: [\n\(decryptedUpdateEvents.map({ "\tevent: \(ZMUpdateEvent.eventTypeString(for: $0.type) ?? "Unknown")" }).joined(separator: "\n"))\n]")

            await syncContext.perform {
                for event in decryptedUpdateEvents {
                    for eventConsumer in self.eventConsumers {
                        // TODO: [jacob] EventConsumer.processEvents should become async
                        eventConsumer.processEvents([event], liveEvents: true, prefetchResult: prefetchResult)
                    }
                    self.eventProcessingTracker.registerEventProcessed()
                }
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

    // MARK: - Buffered Events

    private func processAllEventsInBuffer() async {
        await storeUpdateEvents(bufferedEvents, ignoreBuffer: true)
        bufferedEvents = []
    }
}

//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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
import GenericMessageProtocol
import WireDataModel
import WireLogging
import WireUtilities

private let zmLog = ZMSLog(tag: "EventDecoder")

// sourcery: AutoMockable
public protocol EventDecoderProtocol {

    func decryptAndStoreEvents(
        _ events: [ZMUpdateEvent],
        publicKeys: EARPublicKeys?
    ) async throws -> [ZMUpdateEvent]

    func processStoredEvents(
        with privateKeys: EARPrivateKeys?,
        callEventsOnly: Bool,
        _ block: @escaping ([ZMUpdateEvent]) async -> Void
    ) async

}

/// Decodes and stores events from various sources to be processed later
public final class EventDecoder: NSObject, EventDecoderProtocol {

    public typealias ConsumeBlock = ([ZMUpdateEvent]) async -> Void

    static var BatchSize: Int {
        if let testingBatchSize {
            return testingBatchSize
        }
        return 500
    }

    /// Set this for testing purposes only
    public static var testingBatchSize: Int?

    unowned let eventMOC: NSManagedObjectContext
    unowned let syncMOC: NSManagedObjectContext

    let isFederationEnabled: Bool

    fileprivate typealias EventsWithStoredEvents = (storedEvents: [StoredUpdateEvent], updateEvents: [ZMUpdateEvent])

    public init(
        eventMOC: NSManagedObjectContext,
        syncMOC: NSManagedObjectContext,
        lastEventIDRepository: LastEventIDRepositoryInterface,
        isFederationEnabled: Bool
    ) {
        self.eventMOC = eventMOC
        self.syncMOC = syncMOC
        self.lastEventIDRepository = lastEventIDRepository
        self.isFederationEnabled = isFederationEnabled
        super.init()
    }

    private let lastEventIDRepository: LastEventIDRepositoryInterface
}

// MARK: - Process events

extension EventDecoder {

    /// Decrypts passed in events and stores them in chronological order in a persisted database,
    /// it then saves the database and cryptobox
    ///
    /// - Parameters:
    ///   - events: Encrypted events
    /// - Returns: the decrypted events for processing.

    public func decryptAndStoreEvents(
        _ events: [ZMUpdateEvent],
        publicKeys: EARPublicKeys? = nil
    ) async throws -> [ZMUpdateEvent] {
        let lastIndex = await eventMOC.perform { [eventMOC] in
            // Get the highest index of events in the DB
            StoredUpdateEvent.highestIndex(eventMOC)
        }

        guard let proteusService = await syncMOC.perform({ [syncMOC] in syncMOC.proteusService }) else {
            WireLogger.proteus.warn("ignore decrypting events because proteus service is not available")
            return []
        }

        let decryptedEvents: [ZMUpdateEvent] = try await decryptAndStoreEvents(
            events,
            startingAtIndex: lastIndex,
            publicKeys: publicKeys,
            proteusService: proteusService
        )

        if !events.isEmpty {
            WireLogger.eventProcessing.info("Decrypted/Stored \(events.count) event(s)")
        }

        return decryptedEvents
    }

    /// Process previously stored and decrypted events by repeatedly calling the the consume block until
    /// all the stored events have been processed. If the app crashes while processing the events, they
    /// can be recovered from the database.
    ///
    /// - Parameters:
    ///   - privateKeys: Keys to be used to decrypt events.
    ///   - block: Event consume block which is called once for every stored event.

    public func processStoredEvents(
        with privateKeys: EARPrivateKeys? = nil,
        callEventsOnly: Bool = false,
        _ block: ConsumeBlock
    ) async {
        await process(
            with: privateKeys,
            block,
            firstCall: true,
            callEventsOnly: callEventsOnly
        )
    }

    /// Decrypts and stores the decrypted events as `StoreUpdateEvent` in the event database.
    /// The encryption context is only closed after the events have been stored, which ensures
    /// they can be decrypted again in case of a crash.
    ///
    /// - Parameters:
    ///   - events The new events that should be decrypted and stored in the database.
    ///   - startingAtIndex The startIndex to be used for the incrementing sortIndex of the stored events.
    ///
    /// - Returns: Decrypted events.

    private func decryptAndStoreEvents(
        _ events: [ZMUpdateEvent],
        startingAtIndex startIndex: Int64,
        publicKeys: EARPublicKeys?,
        proteusService: ProteusServiceInterface
    ) async throws -> [ZMUpdateEvent] {
        var decryptedEvents: [ZMUpdateEvent] = []

        try await withExpiringActivity(reason: "Decrypting & storing event") {
            var index = startIndex
            for event in events {
                try Task.checkCancellation()
                if DeveloperFlag.decryptAndStoreEventsSleep.isOn {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                }
                await decryptedEvents += self.decryptAndStoreEvent(
                    event: event,
                    at: index,
                    publicKeys: publicKeys,
                    proteusService: proteusService
                )
                index += 1
            }
        }

        return decryptedEvents
    }

    private func decryptAndStoreEvent(
        event: ZMUpdateEvent,
        at index: Int64,
        publicKeys: EARPublicKeys?,
        proteusService: ProteusServiceInterface
    ) async -> [ZMUpdateEvent] {

        func storeLastEventId() async {
            if let eventUUID = event.uuid, !event.isTransient {
                await syncMOC.perform {
                    self.lastEventIDRepository.storeLastEventID(eventUUID)
                }
            }
        }

        do {
            let decryptedEvents = try await decryptEvent(
                event: event,
                publicKeys: publicKeys,
                proteusService: proteusService
            )

            if !decryptedEvents.isEmpty {
                await eventMOC.perform {
                    self.storeUpdateEvents(
                        decryptedEvents,
                        startingAtIndex: index,
                        publicKeys: publicKeys
                    )
                }
            }

            await storeLastEventId()
            return decryptedEvents

        } catch let error as Failure {
            switch error {
            case .missingMLSGroupID:
                WireLogger.mls.error(
                    "failed to decrypt mls message: missing MLS group ID"
                )
            }

            await storeLastEventId()
            return []
        } catch {
            WireLogger.mls.warn(
                "failed to decrypt mls message: \(String(describing: error))"
            )

            await storeLastEventId()
            return []
        }
    }

    private func decryptEvent(
        event: ZMUpdateEvent,
        publicKeys: EARPublicKeys?,
        proteusService: ProteusServiceInterface
    ) async throws -> [ZMUpdateEvent] {
        switch event.type {
        case .conversationOtrMessageAdd, .conversationOtrAssetAdd:
            let proteusEvent = await decryptProteusEventAndAddClient(event, in: syncMOC) { sessionID, encryptedData in
                try await proteusService.decrypt(
                    data: encryptedData,
                    forSession: sessionID,
                    context: nil
                )
            }
            return proteusEvent.map { [$0] } ?? []

        case .conversationMLSWelcome:
            await processWelcomeMessage(from: event, context: syncMOC)
            return [event]

        case .conversationMLSMessageAdd:
            return try await decryptMlsMessage(from: event, context: syncMOC)

        default:
            return [event]
        }
    }

    // Insert the decrypted events in the event database using a `storeIndex`
    // incrementing from the highest index currently stored in the database.
    // The encryptedPayload property is encrypted using the public key.

    private func storeUpdateEvents(
        _ decryptedEvents: [ZMUpdateEvent],
        startingAtIndex startIndex: Int64,
        publicKeys: EARPublicKeys?
    ) {
        for (idx, event) in decryptedEvents.enumerated() {
            WireLogger.updateEvent.info("store event", attributes: event.logAttributes)

            _ = StoredUpdateEvent.encryptAndCreate(
                event,
                context: eventMOC,
                index: Int64(idx) + startIndex + 1,
                isCallEvent: event.isCallEvent,
                publicKeys: publicKeys
            )
        }

        do {
            try eventMOC.save()
        } catch {
            WireLogger.updateEvent.critical("Failed to save stored update events: \(error.localizedDescription)")
        }
    }

    // Processes the stored events in the database in batches of size EventDecoder.BatchSize` and calls the
    // `consumeBlock` for each batch.
    // After the `consumeBlock` has been called the stored events are deleted from the database.
    // This method terminates when no more events are in the database.

    private func process(
        with privateKeys: EARPrivateKeys?,
        _ consumeBlock: ConsumeBlock,
        firstCall: Bool,
        callEventsOnly: Bool
    ) async {
        let events = await fetchNextEventsBatch(with: privateKeys, callEventsOnly: callEventsOnly)

        guard !events.storedEvents.isEmpty else {
            if firstCall {
                await consumeBlock([])
            }
            WireLogger.updateEvent.debug("EventDecoder: process events finished", attributes: .safePublic)
            return
        }

        WireLogger.updateEvent.debug(
            "EventDecoder: process batch of \(events.storedEvents.count) events",
            attributes: .safePublic
        )
        await processBatch(events.updateEvents, storedEvents: events.storedEvents, block: consumeBlock)

        await process(with: privateKeys, consumeBlock, firstCall: false, callEventsOnly: callEventsOnly)
    }

    /// Fetches and returns the next batch of size `EventDecoder.BatchSize`
    /// of `StoredEvents` and `ZMUpdateEvent`'s in a `EventsWithStoredEvents` tuple.

    private func fetchNextEventsBatch(
        with privateKeys: EARPrivateKeys?,
        callEventsOnly: Bool
    ) async -> EventsWithStoredEvents {

        var (storedEvents, updateEvents) = ([StoredUpdateEvent](), [ZMUpdateEvent]())

        await eventMOC.perform {
            let eventBatch = StoredUpdateEvent.nextEventBatch(
                size: EventDecoder.BatchSize,
                privateKeys: privateKeys,
                context: self.eventMOC,
                callEventsOnly: callEventsOnly
            )

            storedEvents = eventBatch.eventsToDelete
            updateEvents = eventBatch.eventsToProcess
        }

        return (storedEvents: storedEvents, updateEvents: updateEvents)
    }

    /// Calls the `ComsumeBlock` and deletes the respective stored events subsequently.

    private func processBatch(
        _ events: [ZMUpdateEvent],
        storedEvents: [StoredUpdateEvent],
        block: ConsumeBlock
    ) async {
        if !events.isEmpty {
            WireLogger.eventProcessing.info("Forwarding \(events.count) event(s) to consumers")
        }

        await block(filterInvalidEvents(from: events))

        await eventMOC.perform { [eventMOC] in
            storedEvents.forEach { storedEvent in
                eventMOC.delete(storedEvent)
                WireLogger.eventProcessing.info(
                    "delete stored event",
                    attributes: [LogAttributesKey.eventId: storedEvent.uuidString?.redactedAndTruncated() ?? "<nil>"]
                )
            }
            do {
                try eventMOC.save()
            } catch {
                WireLogger.eventProcessing
                    .critical("failed to save eventMoc after deleting stored events: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - List of already received event IDs

private extension EventDecoder {

    /// Filters out events that shouldn't be processed
    func filterInvalidEvents(from events: [ZMUpdateEvent]) async -> [ZMUpdateEvent] {
        let selfConversationID = await syncMOC
            .perform { ZMConversation.selfConversation(in: self.syncMOC).remoteIdentifier }
        let selfUserID = await syncMOC.perform { ZMUser.selfUser(in: self.syncMOC).remoteIdentifier }

        return events.filter { event in
            // The only message we process arriving in the self conversation from other users is availability updates
            if event.conversationUUID == selfConversationID, event.senderUUID != selfUserID,
               let genericMessage = GenericMessage(from: event, validate: true) {
                let included = genericMessage.hasAvailability
                if !included {
                    WireLogger.updateEvent.warn("dropping stored event", attributes: event.logAttributes)
                }
                return included
            }

            return true
        }
    }
}

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
import WireCryptobox
import WireDataModel
import WireUtilities

private let zmLog = ZMSLog(tag: "EventDecoder")

/// Key used in persistent store metadata
private let previouslyReceivedEventIDsKey = "zm_previouslyReceivedEventIDsKey"

/// Holds a list of received event IDs
@objc public protocol PreviouslyReceivedEventIDsCollection: NSObjectProtocol {
    func discardListOfAlreadyReceivedPushEventIDs()
}

/// Decodes and stores events from various sources to be processed later
@objcMembers public final class EventDecoder: NSObject {

    public typealias ConsumeBlock = (([ZMUpdateEvent]) async -> Void)

    static var BatchSize: Int {
        if let testingBatchSize = testingBatchSize {
            return testingBatchSize
        }
        return 500
    }

    /// Set this for testing purposes only
    public static var testingBatchSize: Int?

    unowned let eventMOC: NSManagedObjectContext
    unowned let syncMOC: NSManagedObjectContext

    fileprivate typealias EventsWithStoredEvents = (storedEvents: [StoredUpdateEvent], updateEvents: [ZMUpdateEvent])

    public init(eventMOC: NSManagedObjectContext, syncMOC: NSManagedObjectContext) {
        self.eventMOC = eventMOC
        self.syncMOC = syncMOC
        super.init()
        self.eventMOC.performGroupedBlockAndWait {
            self.createReceivedPushEventIDsStoreIfNecessary()
        }
    }
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
    ) async -> [ZMUpdateEvent] {
        let (filteredEvents, lastIndex) = await eventMOC.perform {
            self.storeReceivedPushEventIDs(from: events)
            let filteredEvents = self.filterAlreadyReceivedEvents(from: events)

            // Get the highest index of events in the DB
            let lastIndex = StoredUpdateEvent.highestIndex(self.eventMOC)
            return (filteredEvents, lastIndex)
        }

        guard self.syncMOC.proteusProvider.canPerform else {
                WireLogger.proteus.warn("ignore decrypting events because it is not safe")
             return []
        }

        let decryptedEvents: [ZMUpdateEvent] = await self.syncMOC.proteusProvider.performAsync(
            withProteusService: { proteusService in
                return await self.decryptAndStoreEvents(
                    filteredEvents,
                    startingAtIndex: lastIndex,
                    publicKeys: publicKeys,
                    proteusService: proteusService
                )
            },
            withKeyStore: { keyStore in
                return await self.legacyDecryptAndStoreEvents(
                    filteredEvents,
                    startingAtIndex: lastIndex,
                    publicKeys: publicKeys,
                    keyStore: keyStore
                )
            }
        )

        if !events.isEmpty {
            Logging.eventProcessing.info("Decrypted/Stored \( events.count) event(s)")
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
    ) async -> [ZMUpdateEvent] {
        var decryptedEvents = [ZMUpdateEvent]()

        decryptedEvents = await events.asyncCompactMap { event -> ZMUpdateEvent? in
            switch event.type {
            case .conversationOtrMessageAdd, .conversationOtrAssetAdd:
                return await self.decryptProteusEventAndAddClient(event, in: self.syncMOC) { sessionID, encryptedData in
                    try await proteusService.decrypt(
                        data: encryptedData,
                        forSession: sessionID
                    )
                }
            case .conversationMLSMessageAdd:
                return await self.decryptMlsMessage(from: event, context: self.syncMOC)

            default:
                return event
            }
        }

        // This call has to be synchronous to ensure that we close the
        // encryption context only if we stored all events in the database.
        eventMOC.performAndWait {
            self.storeUpdateEvents(decryptedEvents, startingAtIndex: startIndex, publicKeys: publicKeys)
        }

        return decryptedEvents
    }

    private func legacyDecryptAndStoreEvents(
        _ events: [ZMUpdateEvent],
        startingAtIndex startIndex: Int64,
        publicKeys: EARPublicKeys?,
        keyStore: UserClientKeysStore
    ) async -> [ZMUpdateEvent] {
        var decryptedEvents: [ZMUpdateEvent] = []

        keyStore.encryptionContext.perform { [weak self] sessionsDirectory in
            guard let self else { return }

            decryptedEvents = await events.asyncCompactMap { event -> ZMUpdateEvent? in
                switch event.type {
                case .conversationOtrMessageAdd, .conversationOtrAssetAdd:
                    return await self.decryptProteusEventAndAddClient(event, in: self.syncMOC) { sessionID, encryptedData in
                        try sessionsDirectory.decryptData(
                            encryptedData,
                            for: sessionID.mapToEncryptionSessionID()
                        )
                    }

                case .conversationMLSMessageAdd:
                    return self.decryptMlsMessage(from: event, context: self.syncMOC)

                default:
                    return event
                }
            }

            // This call has to be synchronous to ensure that we close the
            // encryption context only if we stored all events in the database.
            eventMOC.performAndWait {
                self.storeUpdateEvents(decryptedEvents, startingAtIndex: startIndex, publicKeys: publicKeys)
            }

        }

        return decryptedEvents
    }

    // Insert the decrypted events in the event database using a `storeIndex`
    // incrementing from the highest index currently stored in the database.
    // The encryptedPayload property is encrypted using the public key.

    private func storeUpdateEvents(
        _ decryptedEvents: [ZMUpdateEvent],
        startingAtIndex startIndex: Int64,
        publicKeys: EARPublicKeys?
    ) {
        let selfUser = ZMUser.selfUser(in: syncMOC)

        let account = Account(
            userName: "",
            userIdentifier: selfUser.remoteIdentifier
        )

        for (idx, event) in decryptedEvents.enumerated() {
            _ = StoredUpdateEvent.encryptAndCreate(
                event,
                context: eventMOC,
                index: Int64(idx) + startIndex + 1,
                publicKeys: publicKeys
            )
        }

        self.eventMOC.saveOrRollback()
    }

    // Processes the stored events in the database in batches of size EventDecoder.BatchSize` and calls the `consumeBlock` for each batch.
    // After the `consumeBlock` has been called the stored events are deleted from the database.
    // This method terminates when no more events are in the database.

    private func process(
        with privateKeys: EARPrivateKeys?,
        _ consumeBlock: ConsumeBlock,
        firstCall: Bool,
        callEventsOnly: Bool
    ) async {
        let events = await fetchNextEventsBatch(with: privateKeys, callEventsOnly: callEventsOnly)

        guard events.storedEvents.count > 0 else {
            if firstCall {
                await consumeBlock([])
            }
            return
        }

        await processBatch(events.updateEvents, storedEvents: events.storedEvents, block: consumeBlock)
        await process(with: privateKeys, consumeBlock, firstCall: false, callEventsOnly: callEventsOnly)
    }

    /// Fetches and returns the next batch of size `EventDecoder.BatchSize`
    /// of `StoredEvents` and `ZMUpdateEvent`'s in a `EventsWithStoredEvents` tuple.

    private func fetchNextEventsBatch(with privateKeys: EARPrivateKeys?, callEventsOnly: Bool) async -> EventsWithStoredEvents {
        var (storedEvents, updateEvents)  = ([StoredUpdateEvent](), [ZMUpdateEvent]())

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
        storedEvents: [NSManagedObject],
        block: ConsumeBlock
    ) async {
        if !events.isEmpty {
            Logging.eventProcessing.info("Forwarding \(events.count) event(s) to consumers")
        }

        await block(filterInvalidEvents(from: events))

        eventMOC.performGroupedBlockAndWait {
            storedEvents.forEach(self.eventMOC.delete(_:))
            self.eventMOC.saveOrRollback()
        }
    }

}

// MARK: - List of already received event IDs
extension EventDecoder {

    /// create event ID store if needed
    fileprivate func createReceivedPushEventIDsStoreIfNecessary() {
        if self.eventMOC.persistentStoreMetadata(forKey: previouslyReceivedEventIDsKey) as? [String] == nil {
            self.eventMOC.setPersistentStoreMetadata(array: [String](), key: previouslyReceivedEventIDsKey)
        }
    }

    /// List of already received event IDs
    fileprivate var alreadyReceivedPushEventIDs: Set<UUID> {
        let array = self.eventMOC.persistentStoreMetadata(forKey: previouslyReceivedEventIDsKey) as! [String]
        return Set(array.compactMap { UUID(uuidString: $0) })
    }

    /// List of already received event IDs as strings
    fileprivate var alreadyReceivedPushEventIDsStrings: Set<String> {
        return Set(self.eventMOC.persistentStoreMetadata(forKey: previouslyReceivedEventIDsKey) as! [String])
    }

    /// Store received event IDs
    fileprivate func storeReceivedPushEventIDs(from: [ZMUpdateEvent]) {
        let uuidToAdd = from
            .filter { $0.source == .pushNotification }
            .compactMap { $0.uuid }
            .map { $0.transportString() }
        let allUuidStrings = self.alreadyReceivedPushEventIDsStrings.union(uuidToAdd)

        self.eventMOC.setPersistentStoreMetadata(array: Array(allUuidStrings), key: previouslyReceivedEventIDsKey)
    }

    /// Filters out events that have been received before
    fileprivate func filterAlreadyReceivedEvents(from: [ZMUpdateEvent]) -> [ZMUpdateEvent] {
        let eventIDsToDiscard = self.alreadyReceivedPushEventIDs
        return from.compactMap { event -> ZMUpdateEvent? in
            if event.source != .pushNotification, let uuid = event.uuid {
                return eventIDsToDiscard.contains(uuid) ? nil : event
            } else {
                return event
            }
        }
    }

    /// Filters out events that shouldn't be processed
    fileprivate func filterInvalidEvents(from events: [ZMUpdateEvent]) async -> [ZMUpdateEvent] {
        let selfConversationID = await syncMOC.perform { ZMConversation.selfConversation(in: self.syncMOC).remoteIdentifier }
        let selfUserID = await syncMOC.perform { ZMUser.selfUser(in: self.syncMOC).remoteIdentifier }

        return events.filter { event in
            // The only message we process arriving in the self conversation from other users is availability updates
            if event.conversationUUID == selfConversationID, event.senderUUID != selfUserID, let genericMessage = GenericMessage(from: event) {
                return genericMessage.hasAvailability
            }

            return true
        }
    }
}

@objc extension EventDecoder: PreviouslyReceivedEventIDsCollection {

    /// Discards the list of already received events
    public func discardListOfAlreadyReceivedPushEventIDs() {
        self.eventMOC.performGroupedBlockAndWait {
            self.eventMOC.setPersistentStoreMetadata(array: [String](), key: previouslyReceivedEventIDsKey)
        }
    }
}

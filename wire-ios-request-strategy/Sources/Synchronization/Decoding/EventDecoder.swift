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

private let zmLog = ZMSLog(tag: "EventDecoder")

/// Key used in persistent store metadata
private let previouslyReceivedEventIDsKey = "zm_previouslyReceivedEventIDsKey"

/// Holds a list of received event IDs
@objc public protocol PreviouslyReceivedEventIDsCollection: NSObjectProtocol {
    func discardListOfAlreadyReceivedPushEventIDs()
}

/// Decodes and stores events from various sources to be processed later
@objcMembers public final class EventDecoder: NSObject {

    public typealias ConsumeBlock = (([ZMUpdateEvent]) -> Void)

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

    public func decryptAndStoreEvents(
        _ events: [ZMUpdateEvent],
        block: ConsumeBlock? = nil
    ) {
        var lastIndex: Int64?
        var decryptedEvents: [ZMUpdateEvent] = []

        eventMOC.performGroupedBlockAndWait {

            self.storeReceivedPushEventIDs(from: events)
            let filteredEvents = self.filterAlreadyReceivedEvents(from: events)

            // Get the highest index of events in the DB
            lastIndex = StoredUpdateEvent.highestIndex(self.eventMOC)

            guard let index = lastIndex else { return }
            decryptedEvents = self.decryptAndStoreEvents(filteredEvents, startingAtIndex: index)
        }

        if !events.isEmpty {
            Logging.eventProcessing.info("Decrypted/Stored \( events.count) event(s)")
        }

        block?(decryptedEvents)
    }

    /// Process previously stored and decrypted events by repeatedly calling the the consume block until
    /// all the stored events have been processed. If the app crashes while processing the events, they
    /// can be recovered from the database.
    ///
    /// - Parameters:
    ///   - encryptionKeys: Keys to be used to decrypt events.
    ///   - block: Event consume block which is called once for every stored event.

    public func processStoredEvents(with encryptionKeys: EncryptionKeys? = nil, _ block: ConsumeBlock) {
        process(with: encryptionKeys, block, firstCall: true)
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
        startingAtIndex startIndex: Int64
    ) -> [ZMUpdateEvent] {
        let account = Account(userName: "", userIdentifier: ZMUser.selfUser(in: self.syncMOC).remoteIdentifier)
        let publicKey = try? EncryptionKeys.publicKey(for: account)
        var decryptedEvents: [ZMUpdateEvent] = []

        // TODO: [John] use flag here
        syncMOC.zm_cryptKeyStore.encryptionContext.perform { [weak self] (sessionsDirectory) -> Void in
            guard let `self` = self else { return }

            decryptedEvents = events.compactMap { event -> ZMUpdateEvent? in
                switch event.type {
                case .conversationOtrMessageAdd, .conversationOtrAssetAdd:
                    // Proteus
                    return decryptProteusEventAndAddClient(
                        event,
                        in: self.syncMOC,
                        sessionsDirectory: sessionsDirectory
                    )

                case .conversationMLSMessageAdd:
                    return self.decryptMlsMessage(from: event, context: self.syncMOC)
                default:
                    return event
                }
            }

            // This call has to be synchronous to ensure that we close the
            // encryption context only if we stored all events in the database

            // Insert the decrypted events in the event database using a `storeIndex`
            // incrementing from the highest index currently stored in the database
            // The encryptedPayload property is encrypted using the public key
            for (idx, event) in decryptedEvents.enumerated() {
                _ = StoredUpdateEvent.encryptAndCreate(event, managedObjectContext: self.eventMOC, index: Int64(idx) + startIndex + 1, publicKey: publicKey)
            }

            self.eventMOC.saveOrRollback()
        }

        return decryptedEvents
    }

    // MARK: - Decryption

    /// Decrypts an event (if needed) and return a decrypted copy (or the original if no
    /// decryption was needed) and information about the decryption result.

    func decryptProteusEventAndAddClient(
        _ event: ZMUpdateEvent,
        in moc: NSManagedObjectContext,
        sessionsDirectory: EncryptionSessionsDirectory
    ) -> ZMUpdateEvent? {
        guard !event.wasDecrypted else { return event }
        guard event.type == .conversationOtrMessageAdd || event.type == .conversationOtrAssetAdd else {
            fatal("Can't decrypt event of type \(event.type) as it's not supposed to be encrypted")
        }

        // is it for the current client?
        let selfUser = ZMUser.selfUser(in: moc)
        guard let recipientIdentifier = event.recipientIdentifier, selfUser.selfClient()?.remoteIdentifier == recipientIdentifier else {
            return nil
        }

        // client
        guard let senderClient = createClientIfNeeded(from: event, in: moc) else { return nil }

        // decrypt
        let createdNewSession: Bool
        let decryptedEvent: ZMUpdateEvent

        // Proteus
        func fail(error: CBoxResult? = nil) {
            if senderClient.isInserted {
                selfUser.selfClient()?.addNewClientToIgnored(senderClient)
            }
            appendFailedToDecryptMessage(after: error, for: event, sender: senderClient, in: moc)
        }

        do {
            guard let result = try decryptedUpdateEvent(
                for: event,
                sender: senderClient,
                sessionsDirectory: sessionsDirectory
            ) else {
                fail()
                return nil
            }
            (createdNewSession, decryptedEvent) = result
        } catch let error as CBoxResult {
            fail(error: error)
            return nil
        } catch {
            fatalError("Unknown error in decrypting payload, \(error)")
        }

        // new client discovered?
        if createdNewSession {
            let senderClientSet: Set<UserClient> = [senderClient]
            selfUser.selfClient()?.decrementNumberOfRemainingKeys()
            selfUser.selfClient()?.addNewClientToIgnored(senderClient)
            selfUser.selfClient()?.updateSecurityLevelAfterDiscovering(senderClientSet)
        }

        return decryptedEvent
    }

    /// Create user and client if needed. The client will not be trusted
    private func createClientIfNeeded(from updateEvent: ZMUpdateEvent, in moc: NSManagedObjectContext) -> UserClient? {
        guard let senderUUID = updateEvent.senderUUID,
              let senderClientID = updateEvent.senderClientID else { return nil }

        let domain = updateEvent.senderDomain
        let user = ZMUser.fetchOrCreate(with: senderUUID, domain: domain, in: moc)
        let client = UserClient.fetchUserClient(withRemoteId: senderClientID, forUser: user, createIfNeeded: true)!

        client.discoveryDate = updateEvent.timestamp

        return client
    }

    /// Appends a system message for a failed decryption
    fileprivate func appendFailedToDecryptMessage(after error: CBoxResult?, for event: ZMUpdateEvent, sender: UserClient, in moc: NSManagedObjectContext) {
        zmLog.safePublic("Failed to decrypt message with error: \(error), client id <\(sender.safeRemoteIdentifier))>")
        zmLog.error("event debug: \(event.debugInformation)")
        if error == CBOX_OUTDATED_MESSAGE || error == CBOX_DUPLICATE_MESSAGE {
            return // do not notify the user if the error is just "duplicated"
        }

        var conversation: ZMConversation?
        if let conversationUUID = event.conversationUUID {
            conversation = ZMConversation.fetch(with: conversationUUID, domain: event.conversationDomain, in: moc)
            conversation?.appendDecryptionFailedSystemMessage(at: event.timestamp, sender: sender.user!, client: sender, errorCode: Int(error?.rawValue ?? 0))
        }

        let userInfo: [String: Any] = [
            "cause": error?.rawValue as Any,
            "deviceClass": sender.deviceClass ?? ""
        ]

        NotificationInContext(
            name: ZMConversation.failedToDecryptMessageNotificationName,
            context: sender.managedObjectContext!.notificationContext,
            object: conversation,
            userInfo: userInfo
        ).post()
    }

    /// Returns the decrypted version of an update event. This is generated by decrypting the encrypted version
    /// and creating a new event with the decrypted data in the expected payload keys
    private func decryptedUpdateEvent(
        for event: ZMUpdateEvent,
        sender: UserClient,
        sessionsDirectory: EncryptionSessionsDirectory
    ) throws -> (createdNewSession: Bool, event: ZMUpdateEvent)? {
        guard
            let result = try self.decryptedData(
                event,
                client: sender,
                sessionsDirectory: sessionsDirectory
            ),
            let decryptedEvent = event.decryptedEvent(decryptedData: result.decryptedData)
        else {
            return nil
        }
        return (createdNewSession: result.createdNewSession, event: decryptedEvent)
    }

    /// Decrypted data from event
    private func decryptedData(
        _ event: ZMUpdateEvent,
        client: UserClient,
        sessionsDirectory: EncryptionSessionsDirectory
    ) throws -> (createdNewSession: Bool, decryptedData: Data)? {
        guard
            let encryptedData = try event.encryptedMessageData(),
            let sessionID = client.sessionIdentifier
        else {
            return nil
        }

        /// Check if it's the "bomb" message (gave encrypting on the sender)
        guard encryptedData != ZMFailedToCreateEncryptedMessagePayloadString.data(using: .utf8) else {
            zmLog.safePublic("Received 'failed to encrypt for your client' special payload (bomb) from \(sessionID). Current device might have invalid prekeys on the BE.")
            return nil
        }

        return try sessionsDirectory.decryptData(encryptedData, for: sessionID)
    }


    func decryptMlsMessage(from updateEvent: ZMUpdateEvent, context: NSManagedObjectContext) -> ZMUpdateEvent? {
        Logging.mls.info("decrypting mls message")

        guard let mlsController = context.mlsController else {
            Logging.mls.warn("failed to decrypt mls message: MLSController is missing")
            return nil
        }

        guard let payload = updateEvent.eventPayload(type: Payload.UpdateConversationMLSMessageAdd.self) else {
            Logging.mls.warn("failed to decrypt mls message: invalid update event payload")
            return nil
        }

        guard let conversation = ZMConversation.fetch(with: payload.id, domain: payload.qualifiedID?.domain, in: context) else {
            Logging.mls.warn("failed to decrypt mls message: conversation not found in db")
            return nil
        }

        guard conversation.mlsStatus == .ready else {
            Logging.mls.warn("failed to decrypt mls message: conversation is not ready (status: \(String(describing: conversation.mlsStatus)))")
            return nil
        }

        guard let groupID = conversation.mlsGroupID else {
            Logging.mls.warn("failed to decrypt mls message: missing MLS group ID")
            return nil
        }

        do {
            guard
                let result = try mlsController.decrypt(message: payload.data,
                                                       for: groupID)
            else {
                Logging.mls.info("successfully decrypted mls message but no result was returned")
                return nil
            }

            switch result {
            case .message(let decryptedData, let senderClientID):
                return updateEvent.decryptedMLSEvent(decryptedData: decryptedData, senderClientID: senderClientID)
            case .proposal(let commitDelay):
                let scheduledDate = (updateEvent.timestamp ?? Date()) + TimeInterval(commitDelay)
                mlsController.scheduleCommitPendingProposals(groupID: groupID, at: scheduledDate)

                if updateEvent.source == .webSocket {
                    Task {
                        do {
                            try await mlsController.commitPendingProposals()
                        } catch {
                            Logging.mls.error("Failed to commit pending proposals: \(String(describing: error))")
                        }
                    }
                }
                return nil
            }

        } catch {
            Logging.mls.warn("failed to decrypt mls message: \(String(describing: error))")
            return nil
        }
    }

    // Processes the stored events in the database in batches of size EventDecoder.BatchSize` and calls the `consumeBlock` for each batch.
    // After the `consumeBlock` has been called the stored events are deleted from the database.
    // This method terminates when no more events are in the database.
    private func process(with encryptionKeys: EncryptionKeys?, _ consumeBlock: ConsumeBlock, firstCall: Bool) {
        let events = fetchNextEventsBatch(with: encryptionKeys)
        guard events.storedEvents.count > 0 else {
            if firstCall {
                consumeBlock([])
            }
            return
        }

        processBatch(events.updateEvents, storedEvents: events.storedEvents, block: consumeBlock)
        process(with: encryptionKeys, consumeBlock, firstCall: false)
    }

    /// Calls the `ComsumeBlock` and deletes the respective stored events subsequently.
    private func processBatch(_ events: [ZMUpdateEvent], storedEvents: [NSManagedObject], block: ConsumeBlock) {
        if !events.isEmpty {
            Logging.eventProcessing.info("Forwarding \(events.count) event(s) to consumers")
        }

        block(filterInvalidEvents(from: events))

        eventMOC.performGroupedBlockAndWait {
            storedEvents.forEach(self.eventMOC.delete(_:))
            self.eventMOC.saveOrRollback()
        }
    }

    /// Fetches and returns the next batch of size `EventDecoder.BatchSize`
    /// of `StoredEvents` and `ZMUpdateEvent`'s in a `EventsWithStoredEvents` tuple.
    private func fetchNextEventsBatch(with encryptionKeys: EncryptionKeys?) -> EventsWithStoredEvents {
        var (storedEvents, updateEvents)  = ([StoredUpdateEvent](), [ZMUpdateEvent]())

        eventMOC.performGroupedBlockAndWait {
            storedEvents = StoredUpdateEvent.nextEvents(self.eventMOC, batchSize: EventDecoder.BatchSize)
            updateEvents = StoredUpdateEvent.eventsFromStoredEvents(storedEvents, encryptionKeys: encryptionKeys)
        }
        return (storedEvents: storedEvents, updateEvents: updateEvents)
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
    fileprivate func filterInvalidEvents(from events: [ZMUpdateEvent]) -> [ZMUpdateEvent] {
        let selfConversation = ZMConversation.selfConversation(in: syncMOC)
        let selfUser = ZMUser.selfUser(in: syncMOC)

        return events.filter { event in
            // The only message we process arriving in the self conversation from other users is availability updates
            if event.conversationUUID == selfConversation.remoteIdentifier, event.senderUUID != selfUser.remoteIdentifier, let genericMessage = GenericMessage(from: event) {
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

extension ZMUpdateEvent {

    /// Recipient identifier
    fileprivate var recipientIdentifier: String? {
        return self.eventData?["recipient"] as? String
    }

    /// Event payload
    private var eventData: [String: Any]? {
        guard let eventData = (self.payload as? [String: Any])?["data"] as? [String: Any] else {
            return nil
        }
        return eventData
    }

    fileprivate func encryptedMessageData() throws -> Data? {
        guard let key = payloadKey else { return nil }
        guard let string = eventData?[key] as? String, let data = Data(base64Encoded: string) else { return nil }

        // We need to check the size of the encrypted data payload for regular OTR and external messages
        let maxReceivingSize = Int(12_000 * 1.5)
        guard string.count <= maxReceivingSize, externalStringCount <= maxReceivingSize else { throw CBOX_DECODE_ERROR }
        return data
    }

    fileprivate var payloadKey: String? {
        switch type {
        case .conversationOtrMessageAdd: return "text"
        case .conversationOtrAssetAdd: return "key"
        default: return nil
        }
    }

    fileprivate var externalStringCount: Int {
        return (eventData?["data"] as? String)?.count ?? 0
    }

}

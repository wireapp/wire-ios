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

import CoreData
import Foundation

@objc(StoredUpdateEvent)
public final class StoredUpdateEvent: NSManagedObject {

    private static let entityName = "StoredUpdateEvent"
    private static let SortIndexKey = "sortIndex"

    /// The key under which the event payload is encrypted by the public key.

    static let encryptedPayloadKey = "encryptedPayload"

    // MARK: - Properties

    @NSManaged
    /// hash Value of payload and eventId combined
    var eventHash: Int64

    @NSManaged
    var uuidString: String?

    @NSManaged
    var debugInformation: String?

    @NSManaged
    var isTransient: Bool

    @NSManaged
    var payload: NSDictionary?

    @NSManaged
    var isEncrypted: Bool

    @NSManaged
    var isCallEvent: Bool

    @NSManaged
    var source: Int16

    @NSManaged
    var sortIndex: Int64

    // MARK: - Creation

    /// Maps a passed in `ZMUpdateEvent` to a `StoredUpdateEvent` which is persisted in a database
    ///
    /// - Parameters:
    ///   - event: received events
    ///   - managedObjectContext: current managedObjectContext
    ///   - index: the passed in `index` is used to enumerate events to be able to fetch and sort them later on in the order they were received
    ///   - publicKey: the publicKey which will be used to encrypt update events
    ///
    /// - Returns: storedEvent which will be persisted in a database

    public static func encryptAndCreate(
        _ event: ZMUpdateEvent,
        context: NSManagedObjectContext,
        index: Int64,
        publicKeys: EARPublicKeys? = nil
    ) -> StoredUpdateEvent? {
        guard let eventId = event.uuid?.transportString(),
              let eventHash = EventHasher.hash(eventId: eventId, payload: event.payload) else {
            assertionFailure("trying to check storedEvent without id")
            return nil
        }

        guard !storedEventExists(for: eventId, eventHash: eventHash, in: context) else {
            WireLogger.updateEvent.warn("dropping event as it has already been stored", attributes: event.logAttributes)
            return nil
        }

        guard let storedEvent = StoredUpdateEvent.create(from: event,
                                                         eventId: eventId,
                                                         eventHash: eventHash,
                                                         index: index,
                                                         context: context) else {
            WireLogger.updateEvent.error("could not store event", attributes: [.eventId: event.safeUUID])
            return nil
        }

        encryptIfNeeded(
            storedEvent,
            publicKeys: publicKeys
        )

        return storedEvent
    }

    static func create(from event: ZMUpdateEvent,
                       eventId: String,
                       eventHash: Int,
                       index: Int64,
                       context: NSManagedObjectContext) -> StoredUpdateEvent? {
        let storedEvent = StoredUpdateEvent.insertNewObject(context)

        storedEvent?.debugInformation = event.debugInformation
        storedEvent?.isTransient = event.isTransient
        storedEvent?.source = Int16(event.source.rawValue)
        storedEvent?.sortIndex = index
        storedEvent?.uuidString = eventId
        storedEvent?.isCallEvent = event.isCallEvent
        storedEvent?.payload = event.payload as NSDictionary
        storedEvent?.eventHash = Int64(eventHash)
        storedEvent?.isEncrypted = false

        return storedEvent
    }

    static private func storedEventExists(for eventId: String, eventHash: Int, in context: NSManagedObjectContext) -> Bool {
        let fetchRequest = NSFetchRequest<StoredUpdateEvent>(entityName: self.entityName)
        let eventIdPredicate = NSPredicate(format: "%K = %@", #keyPath(StoredUpdateEvent.uuidString), eventId)

        let eventHash = NSPredicate(format: "%K = %lld", #keyPath(StoredUpdateEvent.eventHash), Int64(eventHash))
        let defaultEventHash = NSPredicate(format: "%K = 0", #keyPath(StoredUpdateEvent.eventHash))

        let eventHashOrPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [eventHash, defaultEventHash])

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [eventIdPredicate, eventHashOrPredicate])

        let result = context.countOrAssert(request: fetchRequest)
        return result > 0
    }

    private static func encryptIfNeeded(
        _ storedEvent: StoredUpdateEvent,
        publicKeys: EARPublicKeys?
    ) {
        guard
            let publicKeys,
            let unencryptedPayload = storedEvent.payload
        else {
            return
        }

        // Call events may need to be processed in the background, therefore
        // we use the secondary key which allows decryption in the backgound.
        // All other events should be protected with the more restrictive
        // primary key, meaning they can't be decrypted in the background.
        let key = storedEvent.isCallEvent ? publicKeys.secondary : publicKeys.primary

        storedEvent.payload = encrypt(
            eventPayload: unencryptedPayload,
            publicKey: key
        )

        storedEvent.isEncrypted = true
    }

    static func insertNewObject(_ context: NSManagedObjectContext) -> StoredUpdateEvent? {
        return NSEntityDescription.insertNewObject(
            forEntityName: self.entityName,
            into: context
        ) as? StoredUpdateEvent
    }

    // MARK: - Retrieving

    /// Returns stored events sorted by and up until (including) the defined `stopIndex`
    /// Returns a maximum of `batchSize` events at a time

    static func nextEvents(
        _ context: NSManagedObjectContext,
        batchSize: Int,
        callEventsOnly: Bool
    ) -> [StoredUpdateEvent] {
        let fetchRequest = NSFetchRequest<StoredUpdateEvent>(entityName: self.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: StoredUpdateEvent.SortIndexKey, ascending: true)]
        fetchRequest.fetchLimit = batchSize
        fetchRequest.returnsObjectsAsFaults = false

        if callEventsOnly {
            fetchRequest.predicate = NSPredicate(format: "%K == YES", #keyPath(StoredUpdateEvent.isCallEvent))
        }

        let result = context.fetchOrAssert(request: fetchRequest)
        return result
    }

    /// Returns the highest index of all stored events

    public static func highestIndex(_ context: NSManagedObjectContext) -> Int64 {
        let fetchRequest = NSFetchRequest<StoredUpdateEvent>(entityName: self.entityName)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: StoredUpdateEvent.SortIndexKey, ascending: false)]
        fetchRequest.fetchBatchSize = 1
        let result = context.fetchOrAssert(request: fetchRequest)
        return result.first?.sortIndex ?? 0
    }

    static func nextEventBatch(
        size: Int,
        privateKeys: EARPrivateKeys?,
        context: NSManagedObjectContext,
        callEventsOnly: Bool
    ) -> EventBatch {
        let storedEvents = nextEvents(context, batchSize: size, callEventsOnly: callEventsOnly)
        return eventsFromStoredEvents(
            storedEvents,
            privateKeys: privateKeys
        )
    }

    static func eventsFromStoredEvents(
        _ storedEvents: [StoredUpdateEvent],
        privateKeys: EARPrivateKeys?
    ) -> EventBatch {
        var result = EventBatch()

        for storedEvent in storedEvents {
            switch extractUpdateEvent(
                from: storedEvent,
                privateKeys: privateKeys
            ) {
            case .success(let updateEvent):
                result.eventsToProcess.append(updateEvent)
                result.eventsToDelete.append(storedEvent)

            case .failure(.permanent):
                WireLogger.updateEvent.warn("StoredUpdateEvent: eventsFromStoredEvents failure permanent")
                result.eventsToDelete.append(storedEvent)

            case .failure(.temporary):
                WireLogger.updateEvent.warn("StoredUpdateEvent: eventsFromStoredEvents failure temporary, continue")
                continue
            }
        }

        return result
    }

    struct EventBatch {

        var eventsToProcess = [ZMUpdateEvent]()
        var eventsToDelete = [StoredUpdateEvent]()

    }

    private static func extractUpdateEvent(
        from storedEvent: StoredUpdateEvent,
        privateKeys: EARPrivateKeys?
    ) -> Result<ZMUpdateEvent, ExtractionFailure> {
        do {
            guard
                let payload = try decryptPayloadIfNeeded(
                    storedEvent: storedEvent,
                    privateKeys: privateKeys
                ),
                let eventSource = ZMUpdateEventSource(rawValue: Int(storedEvent.source)),
                let decryptedEvent = ZMUpdateEvent.decryptedUpdateEvent(
                    fromEventStreamPayload: payload,
                    uuid: storedEvent.uuidString.flatMap(UUID.init(transportString:)),
                    transient: storedEvent.isTransient,
                    source: eventSource
                )
            else {
                WireLogger.updateEvent.error("StoreUpdateEvent: decryption failed permanently", attributes: .safePublic)
                return .failure(.permanent)
            }

            if let debugInfo = storedEvent.debugInformation {
                decryptedEvent.appendDebugInformation(debugInfo)
            }

            decryptedEvent.contentHash = storedEvent.eventHash

            return .success(decryptedEvent)

        } catch DecryptionFailure.privateKeyUnavailable {
            // The required key isn't available now, but it may be later.
            WireLogger.updateEvent.warn("StoreUpdateEvent: decryption failed temporary", attributes: .safePublic)
            return .failure(.temporary)
        } catch {
            WireLogger.updateEvent.error("StoreUpdateEvent: decryption failed permanently", attributes: .safePublic)
            return .failure(.permanent)
        }
    }

    enum ExtractionFailure: Error {

        case temporary
        case permanent

    }

    // MARK: - Encryption at Rest

    /// Encrypts the passed payload if publicKey.
    ///
    /// - Parameters:
    ///   - eventPayload: the event payload
    ///   - publicKey: publicKey which will be used to encrypt eventPayload
    ///
    /// - Returns: a dictionary which contains encrypted payload.

    private static func encrypt(
        eventPayload: NSDictionary,
        publicKey: SecKey
    ) -> NSDictionary? {
        guard
            let data = try? JSONSerialization.data(
                withJSONObject: eventPayload,
                options: []
            ),
            let encryptedData = SecKeyCreateEncryptedData(
                publicKey,
                .eciesEncryptionCofactorX963SHA256AESGCM,
                data as CFData,
                nil
            )
        else {
            return nil
        }

        return NSDictionary(dictionary: [encryptedPayloadKey: encryptedData])
    }

    /// Decrypts the passed stored event payload if the isEncrypted property is true.
    ///
    /// - Parameters:
    ///   - storedEvent: the stored event
    ///   - encryptionKeys: keys to be used to decrypt the stored event payload
    ///
    /// - Returns: a dictionary which contains decrypted payload.

    private static func decryptPayloadIfNeeded(
        storedEvent: StoredUpdateEvent,
        privateKeys: EARPrivateKeys?
    ) throws -> NSDictionary? {
        guard storedEvent.isEncrypted else {
            return storedEvent.payload
        }

        guard let encryptedPayload = storedEvent.payload?[encryptedPayloadKey] as? Data else {
            throw DecryptionFailure.payloadMissing
        }

        // Call events are encrypted by the secondary public key, all other events are
        // encrypted with the primary public key. The secondary key is available while
        // the app is in the background, allowing call events to be processed in the
        // background.
        let key = storedEvent.isCallEvent ? privateKeys?.secondary : privateKeys?.primary

        guard let key else {
            throw DecryptionFailure.privateKeyUnavailable
        }

        return try decrypt(
            payload: encryptedPayload,
            privateKey: key
        )
    }

    private static func decrypt(payload: Data, privateKey: SecKey) throws -> NSDictionary {
        WireLogger.updateEvent.debug("StoreUpdateEvent: decrypt payload")

        guard let decryptedData = SecKeyCreateDecryptedData(
            privateKey,
            .eciesEncryptionCofactorX963SHA256AESGCM,
            payload as CFData,
            nil
        ) else {
            throw DecryptionFailure.decryptionError
        }

        guard let decryptedPayload = try? JSONSerialization.jsonObject(
          with: decryptedData as Data,
          options: []
        ) as? NSDictionary else {
            throw DecryptionFailure.serializationError
        }

        return decryptedPayload
    }

    enum DecryptionFailure: Error {

        case payloadMissing
        case privateKeyUnavailable
        case decryptionError
        case serializationError

    }

}

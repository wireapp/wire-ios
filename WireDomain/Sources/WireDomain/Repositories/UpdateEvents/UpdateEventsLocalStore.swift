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

import WireDataModel
import WireFoundation
import WireLogging
import WireNetwork
import WireUpdateEventCoding

final class UpdateEventsLocalStore: UpdateEventsLocalStoreProtocol {

    enum Key: String, DefaultsKey {
        case lastEventID
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case failedToFetchStoredEvents(Swift.Error)
        case failedToDeleteStoredEvents(Swift.Error)
        case failedToEncryptEventData
    }

    // MARK: - Properties

    private let eventContext: NSManagedObjectContext
    private let syncContext: NSManagedObjectContext
    private let storage: PrivateUserDefaults<Key>
    private let updateEventCoder = StorableUpdateEventCoder()

    // MARK: - Object lifecycle

    init(
        eventContext: NSManagedObjectContext,
        syncContext: NSManagedObjectContext,
        userID: UUID,
        sharedUserDefaults: UserDefaults
    ) {
        self.eventContext = eventContext
        self.syncContext = syncContext
        self.storage = PrivateUserDefaults(
            userID: userID,
            storage: sharedUserDefaults
        )
    }

    // MARK: - Public

    public func lastEventID() -> UUID? {
        storage.getUUID(
            forKey: .lastEventID
        )
    }

    public func storeServerTimeDelta(
        _ serverTimeDelta: TimeInterval
    ) async {
        await syncContext.perform { [syncContext] in
            syncContext.serverTimeDelta = serverTimeDelta
        }
    }

    public func storeLastEventID(id: UUID) {
        storage.setUUID(id, forKey: .lastEventID)
    }

    public func resetLastEventID() {
        storage.setUUID(nil, forKey: .lastEventID)
    }

    public func indexOfLastEventEnvelope() async throws -> Int64 {
        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: false)
            request.fetchBatchSize = 1
            let lastEnvelope = try eventContext.fetch(request).first
            return lastEnvelope?.sortIndex ?? 0
        }
    }

    public func persistEventEnvelope(
        _ eventEnvelope: UpdateEventEnvelope,
        index: Int64,
        publicKeys: EARPublicKeys?
    ) async throws {

        try await eventContext.perform { [eventContext, updateEventCoder] in
            try Self.internalPersistEventEnvelope(
                updateEventCoder: updateEventCoder,
                eventContext: eventContext,
                eventEnvelope: eventEnvelope,
                index: index,
                publicKeys: publicKeys
            )
            try eventContext.save()
        }
    }

    public func persistEventEnvelopes(
        _ eventEnvelopes: [UpdateEventEnvelope],
        index: Int64,
        publicKeys: EARPublicKeys?
    ) async throws {
        try await eventContext.perform { [eventContext, updateEventCoder] in
            var currentIndex = index

            for eventEnvelope in eventEnvelopes {
                try Self.internalPersistEventEnvelope(
                    updateEventCoder: updateEventCoder,
                    eventContext: eventContext,
                    eventEnvelope: eventEnvelope,
                    index: currentIndex,
                    publicKeys: publicKeys
                )
                currentIndex += 1
            }

            try eventContext.save()
        }
    }

    public func fetchStoredEventEnvelopes(
        limit: UInt,
        privateKeys: EARPrivateKeys?,
        backgroundAccessibleOnly: Bool
    ) async throws -> [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)] {
        try await eventContext.perform { [eventContext, updateEventCoder] in
            do {
                let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)

                WireLogger.ear.info("fetching stored events. backgroundAccessibleOnly: \(backgroundAccessibleOnly)")

                if backgroundAccessibleOnly {
                    request.predicate = NSPredicate(
                        format: "%K == false OR %K == true",
                        #keyPath(StoredUpdateEventEnvelope.isEncrypted),
                        #keyPath(StoredUpdateEventEnvelope.isBackgroundAccessible)
                    )
                }

                request.fetchLimit = Int(limit)
                request.returnsObjectsAsFaults = false
                let storedEventEnvelopes = try eventContext.fetch(request)
                return try storedEventEnvelopes.compactMap { storedEnvelope in
                    var data = storedEnvelope.data

                    if storedEnvelope.isEncrypted {

                        WireLogger.ear.info("decrypting stored event.")

                        guard let privateKeys else {
                            WireLogger.ear.error(
                                "failed to decrypt stored event: no private keys",
                                attributes: .safePublic
                            )
                            return nil
                        }

                        let isBackgroundAccessible = storedEnvelope.isBackgroundAccessible
                        let key = isBackgroundAccessible ? privateKeys.secondary : privateKeys.primary

                        guard let key, let decryptedData = EAREncryptionHelper.decrypt(
                            data: data,
                            privateKey: key
                        ) else {
                            WireLogger.ear.error("failed to decrypt stored event", attributes: .safePublic)
                            return nil
                        }
                        data = decryptedData
                    }

                    return (try updateEventCoder.decode(data), storedEnvelope.objectID)
                }
            } catch {
                throw Error.failedToFetchStoredEvents(error)
            }
        }
    }

    public func deleteNextPendingEvents(
        with objectIDs: [NSManagedObjectID]
    ) async throws {
        try await eventContext.perform { [eventContext] in
            let deleteRequest = NSBatchDeleteRequest(objectIDs: objectIDs)
            deleteRequest.resultType = .resultTypeObjectIDs
            let batchDelete = try eventContext.execute(deleteRequest) as? NSBatchDeleteResult

            guard let deleteResult = batchDelete?.result as? [NSManagedObjectID] else {
                return assertionFailure(
                    "batch deletion result should be of NSManagedObjectID type"
                )
            }

            WireLogger.sync.debug(
                "deleting \(objectIDs.count) stored envelopes",
                attributes: .incrementalSync
            )

            let deletedObjects: [AnyHashable: Any] = [
                NSDeletedObjectsKey: deleteResult
            ]

            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: deletedObjects,
                into: [eventContext]
            )
        }
    }

    public func deleteEventEnvelopes(
        at indices: [Int64]
    ) async throws {
        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.fetchRequest(sortIndices: indices)
            let untypedRequest: NSFetchRequest<NSFetchRequestResult> = request as! NSFetchRequest<NSFetchRequestResult>
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: untypedRequest)
            deleteRequest.resultType = .resultTypeObjectIDs
            let batchDelete = try eventContext.execute(deleteRequest) as? NSBatchDeleteResult

            guard let deleteResult = batchDelete?.result as? [NSManagedObjectID] else {
                return assertionFailure(
                    "batch deletion result should be of NSManagedObjectID type"
                )
            }

            WireLogger.sync.debug(
                "deleting \(indices.count) stored envelopes",
                attributes: .incrementalSync
            )

            let deletedObjects: [AnyHashable: Any] = [
                NSDeletedObjectsKey: deleteResult
            ]

            NSManagedObjectContext.mergeChanges(
                fromRemoteContextSave: deletedObjects,
                into: [eventContext]
            )
        }
    }

    public func deleteEventEnvelope(
        atIndex index: Int64
    ) async throws {
        try await eventContext.perform { [eventContext] in
            let request = StoredUpdateEventEnvelope.fetchRequest(sortIndex: index)
            guard let envelope = try eventContext.fetch(request).first else { return }
            WireLogger.sync.debug(
                "deleting stored envelope at index \(index)",
                attributes: .incrementalSync
            )
            eventContext.delete(envelope)
            try eventContext.save()
        }
    }

    func calculateLastUnreadMessages() async {
        await syncContext.perform { [syncContext] in
            ZMConversation.calculateLastUnreadMessages(in: syncContext)
        }
    }

    // MARK: - Private Helpers

    private static func internalPersistEventEnvelope(
        updateEventCoder: StorableUpdateEventCoder,
        eventContext: NSManagedObjectContext,
        eventEnvelope: UpdateEventEnvelope,
        index: Int64,
        publicKeys: EARPublicKeys?
    ) throws {
        let storedEventEnvelope = StoredUpdateEventEnvelope(context: eventContext)

        var data = try updateEventCoder.encode(eventEnvelope)

        if let publicKeys {
            let isBackgroundAccessible = eventEnvelope.isBackgroundAccessible
            let key = isBackgroundAccessible ? publicKeys.secondary : publicKeys.primary

            WireLogger.ear.debug("encrypting event. backgroundAccessible: \(isBackgroundAccessible)")

            if let encryptedData = EAREncryptionHelper.encrypt(
                data: data,
                publicKey: key
            ) {
                data = encryptedData
                storedEventEnvelope.isEncrypted = true
                storedEventEnvelope.isBackgroundAccessible = isBackgroundAccessible
            } else {
                WireLogger.ear.error("failed to encrypt event", attributes: .safePublic)
                throw Error.failedToEncryptEventData
            }
        } else {
            // Explicitly set flags for unencrypted events
            storedEventEnvelope.isEncrypted = false
            storedEventEnvelope.isBackgroundAccessible = false
        }

        storedEventEnvelope.data = data
        storedEventEnvelope.sortIndex = index
    }
}

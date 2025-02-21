//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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

final class UpdateEventsLocalStore: UpdateEventsLocalStoreProtocol {

    enum Key: String, DefaultsKey {
        case lastEventID
    }

    // MARK: - Error

    enum Error: Swift.Error {
        case failedToFetchStoredEvents(Swift.Error)
        case failedToDeleteStoredEvents(Swift.Error)
    }

    // MARK: - Properties

    private let context: NSManagedObjectContext
    private let storage: PrivateUserDefaults<Key>

    // MARK: - Object lifecycle

    init(
        context: NSManagedObjectContext,
        userID: UUID,
        sharedUserDefaults: UserDefaults
    ) {
        self.context = context
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

    public func storeLastEventID(id: UUID) {
        storage.setUUID(id, forKey: .lastEventID)
    }

    public func indexOfLastEventEnvelope() async throws -> Int64 {
        try await context.perform { [context] in
            let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: false)
            request.fetchBatchSize = 1
            let lastEnvelope = try context.fetch(request).first
            return lastEnvelope?.sortIndex ?? 0
        }
    }

    public func persistEventEnvelope(
        _ data: Data,
        index: Int64
    ) async throws {
        try await context.perform { [context] in
            let storedEventEnvelope = StoredUpdateEventEnvelope(context: context)
            storedEventEnvelope.data = data
            storedEventEnvelope.sortIndex = index
            try context.save()
        }
    }

    public func fetchStoredEventEnvelopePayloads(
        limit: UInt
    ) async throws -> [Data] {
        try await context.perform { [context] in
            do {
                let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
                request.fetchLimit = Int(limit)
                request.returnsObjectsAsFaults = false
                let storedEventEnvelopes = try context.fetch(request)
                return storedEventEnvelopes.map(\.data)
            } catch {
                throw Error.failedToFetchStoredEvents(error)
            }
        }
    }

    public func deleteNextPendingEvents(
        limit: UInt
    ) async throws {
        try await context.perform { [context] in
            do {
                let request = StoredUpdateEventEnvelope.sortedFetchRequest(asending: true)
                request.fetchLimit = Int(limit)
                let storedEventEnvelopes = try context.fetch(request)
                WireLogger.sync.debug("deleting \(storedEventEnvelopes.count) stored envelopes")
                storedEventEnvelopes.forEach(context.delete)
                try context.save()
            } catch {
                throw Error.failedToDeleteStoredEvents(error)
            }
        }
    }

    public func deleteEventEnvelope(
        atIndex index: Int64
    ) async throws {
        try await context.perform { [context] in
            let request = StoredUpdateEventEnvelope.fetchRequest(sortIndex: index)
            guard let envelope = try context.fetch(request).first else { return }
            WireLogger.sync.debug("deleting stored envelope at index \(index)")
            context.delete(envelope)
            try context.save()
        }
    }

}

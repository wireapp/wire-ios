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

import CoreData
import WireNetwork

// sourcery: AutoMockable
public protocol UpdateEventsLocalStoreProtocol {

    /// Get last event ID.
    /// - returns: The last event ID.

    func lastEventID() -> UUID?

    /// Stores last event ID.
    /// - parameter id: The last event ID to store.

    func storeLastEventID(id: UUID)

    /// Sets last event ID to nil.

    func resetLastEventID()

    /// Retrieves the index of the last event envelope.
    /// - returns: The last index event envelope.

    func indexOfLastEventEnvelope() async throws -> Int64

    /// Persists an event envelope locally.
    /// - Parameters:
    ///     - eventEnvelope: The event envelope to persist.
    ///     - index: The event envelope index.

    func persistEventEnvelope(
        _ eventEnvelope: UpdateEventEnvelope,
        index: Int64
    ) async throws

    /// Persists an event envelopes locally.
    /// - Parameters:
    ///     - eventEnvelopes: The event envelopes to persist.
    ///     - index: The event envelope start index.

    func persistEventEnvelopes(
        _ eventEnvelopes: [UpdateEventEnvelope],
        index: Int64
    ) async throws

    /// Fetches stored event envelopes.
    /// - parameter limit: A fetch limit.
    /// - returns: A list of decoded event envelopes and their related object IDs.

    func fetchStoredEventEnvelopes(
        limit: UInt
    ) async throws -> [(envelope: UpdateEventEnvelope, objectID: NSManagedObjectID)]

    /// Deletes next pending events locally.
    /// - parameter objectIDs: The `StoredUpdateEventEnvelope` object IDs to delete.

    func deleteNextPendingEvents(
        with objectIDs: [NSManagedObjectID]
    ) async throws

    /// Delete all stored events matching given indexes
    /// - Parameter indexes: array of indexes matching the stored events
    func deleteEventEnvelopes(at indexes: [Int64]) async throws

    /// Delete the event envelope with the given index.
    /// - parameter index: The index of the envelope to delete

    func deleteEventEnvelope(
        atIndex index: Int64
    ) async throws

    func calculateLastUnreadMessages() async

    func storeServerTimeDelta(
        _ serverTimeDelta: TimeInterval
    ) async
}

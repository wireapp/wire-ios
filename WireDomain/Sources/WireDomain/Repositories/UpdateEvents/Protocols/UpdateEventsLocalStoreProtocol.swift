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

import Foundation
import WireAPI

// sourcery: AutoMockable
public protocol UpdateEventsLocalStoreProtocol {

    /// Get last event ID.
    /// - returns: The last event ID.

    func lastEventID() -> UUID?

    /// Stores last event ID.
    /// - parameter id: The last event ID to store.

    func storeLastEventID(id: UUID)

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

    /// Fetches stored event envelopes.
    /// - parameter limit: A fetch limit.
    /// - returns: A list of event envelopes.

    func fetchStoredEventEnvelopes(
        limit: UInt
    ) async throws -> [UpdateEventEnvelope]

    /// Deletes next pending events locally.
    /// - parameter limit: A fetch limit.

    func deleteNextPendingEvents(
        limit: UInt
    ) async throws

    /// Delete the event envelope with the given index.
    /// - parameter index: The index of the envelope to delete

    func deleteEventEnvelope(
        atIndex index: Int64
    ) async throws

}

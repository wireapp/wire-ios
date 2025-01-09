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




// sourcery: AutoMockable
protocol UpdateEventsLocalStoreProtocol {

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
    ///     - data: The event envelope payload data.
    ///     - index: The event envelope index.

    func persistEventEnvelope(
        _ data: Data,
        index: Int64
    ) async throws

    /// Fetches stored event envelope payloads.
    /// - parameter limit: A fetch limit.
    /// - returns: A list of event payloads.

    func fetchStoredEventEnvelopePayloads(
        limit: UInt
    ) async throws -> [Data]

    /// Deletes next pending events locally.
    /// - parameter limit: A fetch limit.

    func deleteNextPendingEvents(
        limit: UInt
    ) async throws
}
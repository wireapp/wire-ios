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
/// Access update events.
protocol UpdateEventsRepositoryProtocol {

    /// Pull pending events from the server, decrypt if needed, and store locally.
    ///
    /// Pending events are events that have been buffered by the server while
    /// the self client has not had an active push channel.

    func pullPendingEvents() async throws

    /// Fetch the next batch pending events from the database.
    ///
    /// The batch is already sorted, such that the first element is the oldest
    /// stored event. This method does not delete any events
    /// (see `deleteNextPendingEvents(limit:)`), so invoking this method again
    /// will return the same batch.
    ///
    /// - Parameter limit: The maximum number of events to fetch.
    /// - Returns: Decrypted update event envelopes ready for processing.

    func fetchNextPendingEvents(limit: UInt) async throws -> [UpdateEventEnvelope]

    /// Delete the next batch of pending events from the database.
    ///
    /// Use this method to delete stored events that have been processed and
    /// can now be discarded.
    ///
    /// - Parameter limit: The maximum number of events to delete.

    func deleteNextPendingEvents(limit: UInt) async throws

    /// Open the push channel and deliver update event envelopes through
    /// an asynchronous stream.
    ///
    /// The envelopes are bufferred until a consumer starts to iterate though
    /// the stream.
    ///
    /// - Returns: An asynchronous stream of `UpdateEventEnvelope`s.

    func startBufferingLiveEvents() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error>

    /// Close the push channel and stop the asynchronous stream of
    /// `UpdateEventEnvelope`s returned in `startBufferingLiveEvents`.

    func stopReceivingLiveEvents() async

    /// Store the last event envelope id.
    ///
    /// Future pulls of pending events will only include event envelopes
    /// since this id.
    ///
    /// - Parameter id: The id to store.

    func storeLastEventEnvelopeID(_ id: UUID)

    /// Pulls the last event envelope id and stores it locally.

    func pullLastEventID() async throws

}

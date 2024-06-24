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

import Foundation
import WireAPI
import WireDataModel

/// Access update events.

protocol UpdateEventsRepositoryProtocol {

    /// Pull pending events from the server, decrypt if needed, and store locally.
    ///
    /// Pending events are events that have been buffered by the server while
    /// the self client has not had an active push channel.

    func pullPendingEvents() async throws

}

final class UpdateEventsRepository: UpdateEventsRepositoryProtocol {

    private let selfClientID: String
    private let eventsAPI: any UpdateEventsAPI
    private let eventDecryptor: any UpdateEventDecryptorProtocol
    private let eventContext: NSManagedObjectContext
    private let jsonEncoder = JSONEncoder()

    // TODO: rename to 'protocol`
    private let lastEventIDRepository: any LastEventIDRepositoryInterface

    init(
        selfClientID: String,
        eventsAPI: any UpdateEventsAPI,
        eventDecryptor: any UpdateEventDecryptorProtocol,
        eventContext: NSManagedObjectContext,
        lastEventIDRepository: any LastEventIDRepositoryInterface
    ) {
        self.selfClientID = selfClientID
        self.eventsAPI = eventsAPI
        self.eventDecryptor = eventDecryptor
        self.eventContext = eventContext
        self.lastEventIDRepository = lastEventIDRepository
    }

    func pullPendingEvents() async throws {
        // We want all events since this event.
        guard let lastEventID = lastEventIDRepository.fetchLastEventID() else {
            // TODO: what to do if it's nil?
            return
        }

        // We'll insert new events from this index.
        var currentIndex = await eventContext.perform { [eventContext] in
            StoredUpdateEvent.highestIndex(in: eventContext) + 1
        }

        // Events are fetched in batches.
        for try await envelopes in eventsAPI.getUpdateEvents(
            selfClientID: selfClientID,
            sinceEventID: lastEventID
        ) {
            for envelope in envelopes {
                // We can only decrypt once so store the decrypted event for later retrieval.
                for decryptedEvent in try await eventDecryptor.decryptEvents(in: envelope) {
                    try await persistEvent(
                        decryptedEvent,
                        id: envelope.id,
                        index: currentIndex
                    )

                    currentIndex += 1
                }

                if !envelope.isTransient {
                    // Update the last event id so we don't refetch the same events.
                    lastEventIDRepository.storeLastEventID(envelope.id)
                }
            }
        }
    }

    private func persistEvent(
        _ event: UpdateEvent,
        id: UUID,
        index: Int64
    ) async throws {
        try await eventContext.perform { [eventContext, jsonEncoder] in
            let data = try jsonEncoder.encode(event)

            if let string = String(data: data, encoding: .utf8) {
                print("persisting event: \(string)")
            }

            let storedEvent = StoredUpdateEvent(context: eventContext)
            storedEvent.uuidString = id.uuidString
            storedEvent.sortIndex = index
            storedEvent.eventData = data
            try eventContext.save()
        }
    }

}


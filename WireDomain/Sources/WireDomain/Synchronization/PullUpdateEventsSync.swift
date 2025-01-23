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
import WireLogging

protocol PullUpdateEventsSyncProtocol {

    func pull() async throws

}

struct PullUpdateEventsSync: PullUpdateEventsSyncProtocol {
    private let selfClientID: String
    private let api: any UpdateEventsAPI
    private let store: any UpdateEventsLocalStoreProtocol
    private let decryptor: any UpdateEventDecryptorProtocol
    
    init(
        selfClientID: String,
        api: any UpdateEventsAPI,
        store: any UpdateEventsLocalStoreProtocol,
        decryptor: any UpdateEventDecryptorProtocol
    ) {
        self.selfClientID = selfClientID
        self.api = api
        self.store = store
        self.decryptor = decryptor
    }
    
    func pull() async throws {
        WireLogger.sync.debug("pulling pending events")
        // We want all events since this event.
        guard let lastEventID = store.lastEventID() else {
            throw UpdateEventsRepositoryError.lastEventIDMissing
        }

        // We'll insert new events from this index.
        var currentIndex = try await store.indexOfLastEventEnvelope() + 1

        // Events are fetched in batches.
        for try await envelopes in api.getUpdateEvents(
            selfClientID: selfClientID,
            sinceEventID: lastEventID
        ) {
            let batchCount = envelopes.count
            var count = 0
            WireLogger.sync.debug("received batch of \(batchCount) envelopes")

            // If we need to abort, do it before processing the next page.
            try Task.checkCancellation()

            for envelope in envelopes {
                count += 1

                WireLogger.sync.debug(
                    "decrypting envelope (\(count) of \(batchCount))",
                    attributes: [.eventEnvelopeID: envelope.id]
                )

                // We can only decrypt once so store the decrypted events for later retrieval.
                var decryptedEnvelope = envelope
                let decryptedEvents = try await decryptor.decryptEvents(in: envelope)
                decryptedEnvelope.events = decryptedEvents

                WireLogger.sync.debug(
                    "persisting envelope (\(count) of \(batchCount)",
                    attributes: [.eventEnvelopeID: envelope.id]
                )

                let encoder = JSONEncoder()
                let decryptedEnvelopeData = try encoder.encode(decryptedEnvelope)

                try await store.persistEventEnvelope(
                    decryptedEnvelopeData,
                    index: currentIndex
                )

//                onDecryptedEvents.send(decryptedEvents)

                currentIndex += 1

                if !envelope.isTransient {
                    // Update the last event id so we don't refetch the same events.
                    // Transient events aren't stored in the backend's event stream.
                    storeLastEventEnvelopeID(envelope.id)
                }
            }
        }

//        // All events batches are now fetched.
//        onDecryptedEvents.send(completion: .finished)
//        onDecryptedEvents = .init()
    }
    
    func storeLastEventEnvelopeID(_ id: UUID) {
        WireLogger.sync.debug(
            "storing last event id",
            attributes: [.eventEnvelopeID: id]
        )

        store.storeLastEventID(id: id)
    }
}

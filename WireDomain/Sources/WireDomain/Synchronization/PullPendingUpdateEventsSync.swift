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
import WireDataModel

public struct PullPendingUpdateEventsSync: PullPendingUpdateEventsSyncProtocol {

    private let selfClientID: String
    private let api: any UpdateEventsAPI
    private let store: any UpdateEventsLocalStoreProtocol
    private let journal: Journal
    private let decryptor: any UpdateEventDecryptorProtocol
    private let jsonEncoder = JSONEncoder()

    public init(
        selfClientID: String,
        api: any UpdateEventsAPI,
        store: any UpdateEventsLocalStoreProtocol,
        journal: Journal,
        decryptor: any UpdateEventDecryptorProtocol
    ) {
        self.selfClientID = selfClientID
        self.api = api
        self.store = store
        self.journal = journal
        self.decryptor = decryptor
    }

    @discardableResult
    public func pull() async throws -> AsyncStream<[UpdateEvent]> {
        // We want all events since this event.
        guard let lastEventID = store.lastEventID() else {
            throw PullPendingUpdateEventsSyncError.noLastEventID
        }

        WireLogger.sync.debug("pulling pending events since: \(lastEventID)")

        // We'll insert new events from this index.
        var currentIndex = try await store.indexOfLastEventEnvelope() + 1

        var events: [UpdateEvent] = []
        var brokenMLSGroupIDs = Set<String>()

        // Events are fetched in batches.
        for try await envelopes in api.getUpdateEvents(
            selfClientID: selfClientID,
            sinceEventID: lastEventID
        ) {
            let batchCount = envelopes.count
            var count = 0

            if batchCount > 0 {
                WireLogger.sync.debug("fetched \(batchCount) envelopes from remote")
            } else {
                WireLogger.sync.debug("no new events on remote")
            }

            // If we need to abort, do it before processing the next page.
            try Task.checkCancellation()

            func log(_ message: String, envelopeID: UUID?) {
                WireLogger.sync.debug(
                    "event \(count) of \(batchCount): \(message)",
                    attributes: [.eventEnvelopeID: envelopeID]
                )
            }

            for envelope in envelopes {
                count += 1

                log("decrypting...", envelopeID: envelope.id)
                var decryptedEnvelope = envelope
                let decryptionEventsResult = try await decryptor.decryptEvents(in: envelope)
                let decryptedEvents = decryptionEventsResult.events
                decryptedEnvelope.events = decryptedEvents

                brokenMLSGroupIDs.formUnion(decryptionEventsResult.brokenMLSGroupIDs)

                log("storing...", envelopeID: envelope.id)
                try await store.persistEventEnvelope(
                    decryptedEnvelope,
                    index: currentIndex
                )

                events.append(contentsOf: decryptedEvents)

                currentIndex += 1

                if !envelope.isTransient {
                    // We keep track of the last event id so next time we fetch
                    // only new events. We don't track tranisent events because
                    // these events aren't stored in the backend.
                    log("storing last event id...", envelopeID: envelope.id)
                    store.storeLastEventID(id: envelope.id)
                }
            }
        }

        journal.addValue(brokenMLSGroupIDs, for: .brokenMLSGroupIDs)

        return AsyncStream {
            $0.yield(events)
            $0.finish()
        }
    }

}

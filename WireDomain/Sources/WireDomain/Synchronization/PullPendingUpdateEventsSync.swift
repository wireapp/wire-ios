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

import Foundation
import WireDataModel
import WireLogging
import WireNetwork

public struct PullPendingUpdateEventsSync: PullPendingUpdateEventsSyncProtocol {

    private let selfClientID: String
    private let api: any UpdateEventsAPI
    private let store: any UpdateEventsLocalStoreProtocol
    private let journal: Journal
    private let decryptor: any UpdateEventDecryptorProtocol
    private let coreCryptoProvider: any CoreCryptoProviderProtocol
    private let jsonEncoder = JSONEncoder()

    public init(
        selfClientID: String,
        api: any UpdateEventsAPI,
        store: any UpdateEventsLocalStoreProtocol,
        journal: Journal,
        decryptor: any UpdateEventDecryptorProtocol,
        coreCryptoProvider: any CoreCryptoProviderProtocol
    ) {
        self.selfClientID = selfClientID
        self.api = api
        self.store = store
        self.journal = journal
        self.decryptor = decryptor
        self.coreCryptoProvider = coreCryptoProvider
    }

    @discardableResult
    public func pull(publicKeys: EARPublicKeys?) async throws -> AsyncStream<[UpdateEvent]> {
        var lastEventID: UUID?
        // We want all events since this event.
        if let lastStoredEventID = store.lastEventID() {
            lastEventID = lastStoredEventID
        }

        WireLogger.sync.debug("pulling pending events since: \(String(describing: lastEventID))")

        var events: [UpdateEvent] = []

        let timestampedUpdateEvents = api.getUpdateEvents(
            selfClientID: selfClientID,
            sinceEventID: lastEventID
        )

        // Events are fetched in batches.
        for try await timestampedEnvelope in timestampedUpdateEvents {
            let envelopes = timestampedEnvelope.updateEventEnvelopes
            let timestamp = timestampedEnvelope.time
            let batchCount = envelopes.count
            var count = 0

            if let timestamp {
                WireLogger.sync.debug("storing server time delta")
                await store.storeServerTimeDelta(
                    timestamp.timeIntervalSinceNow
                )
            }

            if batchCount > 0 {
                WireLogger.sync.debug("fetched \(batchCount) envelopes from remote")
            } else {
                WireLogger.sync.debug("no new events on remote")
                continue
            }

            // If we need to abort, do it before processing the next page.
            try Task.checkCancellation()

            // We'll insert new events from this index.
            let currentIndex = try await store.indexOfLastEventEnvelope() + 1

            var lastEnvelopeID: UUID?

            // We are decrypting the batch within one core crypto transaction
            try await coreCryptoProvider.coreCrypto().transaction { context in
                WireLogger.sync.debug(
                    "decrypting batch of \(envelopes.count) envelopes",
                    attributes: .safePublic
                )

                var decryptedEnvelopes: [UpdateEventEnvelope] = []

                for envelope in envelopes {
                    count += 1

                    WireLogger.sync.debug(
                        "event \(count) of \(batchCount): decrypting...",
                        attributes: [.eventEnvelopeID: envelope.id]
                    )

                    var decryptedEnvelope = envelope
                    let decryptionEventsResult = await decryptor.decryptEvents(in: envelope, context: context)
                    let decryptedEvents = decryptionEventsResult.events
                    decryptedEnvelope.events = decryptedEvents

                    events.append(contentsOf: decryptedEvents)
                    decryptedEnvelopes.append(decryptedEnvelope)
                    journal.addValues(decryptionEventsResult.brokenMLSGroupIDs, for: .brokenMLSGroupIDs)

                    if !envelope.isTransient {
                        lastEnvelopeID = envelope.id
                    }
                }

                WireLogger.sync.debug("persisting \(decryptedEnvelopes.count) decrypted event(s)")

                try await store.persistEventEnvelopes(
                    decryptedEnvelopes,
                    index: currentIndex,
                    publicKeys: publicKeys
                )
            }

            if let lastEnvelopeID {
                // We keep track of the last event id so next time we fetch
                // only new events. We don't track transient events because
                // these events aren't stored in the backend.
                //
                // NOTE: it's important the we are updating the last event ID
                // after the CC transaction has successfully completed,
                // otherwise we risk data loss in case of a crash.
                WireLogger.sync.debug("storing last event id", attributes: [.eventEnvelopeID: lastEnvelopeID])
                store.storeLastEventID(id: lastEnvelopeID)
            }
        }

        return AsyncStream {
            $0.yield(events)
            $0.finish()
        }
    }

}

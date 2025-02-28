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

import Combine
import Foundation
import WireAPI
import WireDataModel
import WireFoundation
import WireLogging

final class UpdateEventsRepository: UpdateEventsRepositoryProtocol {

    // MARK: - Properties

    private let userID: UUID
    private let selfClientID: String
    private let updateEventsAPI: any UpdateEventsAPI
    private let pushChannel: any PushChannelProtocol
    private let updateEventDecryptor: any UpdateEventDecryptorProtocol
    private let updateEventsLocalStore: any UpdateEventsLocalStoreProtocol
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let pullPendingEventsSync: PullPendingUpdateEventsSync
    private let pullLastUpdateEventIDSync: PullLastUpdateEventIDSync

    // MARK: - Object lifecycle

    init(
        userID: UUID,
        selfClientID: String,
        updateEventsAPI: any UpdateEventsAPI,
        pushChannel: any PushChannelProtocol,
        updateEventDecryptor: any UpdateEventDecryptorProtocol,
        updateEventsLocalStore: any UpdateEventsLocalStoreProtocol
    ) {
        self.userID = userID
        self.selfClientID = selfClientID
        self.updateEventsAPI = updateEventsAPI
        self.pushChannel = pushChannel
        self.updateEventDecryptor = updateEventDecryptor
        self.updateEventsLocalStore = updateEventsLocalStore
        self.pullLastUpdateEventIDSync = PullLastUpdateEventIDSync(
            selfClientID: selfClientID,
            api: updateEventsAPI,
            store: updateEventsLocalStore
        )
        self.pullPendingEventsSync = PullPendingUpdateEventsSync(
            selfClientID: selfClientID,
            api: updateEventsAPI,
            store: updateEventsLocalStore,
            decryptor: updateEventDecryptor
        )
    }

    // MARK: - Pull pending events

    func pullPendingEvents() async throws {
        try await pullPendingEventsSync.pull()
    }

    func pullLastEventID() async throws {
        try await pullLastUpdateEventIDSync.pull()
    }

    // MARK: - Fetch pending events

    func fetchNextPendingEvents(limit: UInt) async throws -> [UpdateEventEnvelope] {
        let payloads = try await updateEventsLocalStore.fetchStoredEventEnvelopePayloads(limit: limit)
        return try decodeEventEnvelopes(payloads)
    }

    private func decodeEventEnvelopes(_ payloads: [Data]) throws -> [UpdateEventEnvelope] {
        try payloads.map {
            do {
                return try decoder.decode(UpdateEventEnvelope.self, from: $0)
            } catch {
                throw UpdateEventsRepositoryError.failedToDecodeStoredEvent(error)
            }
        }
    }

    // MARK: - Delete pending events

    func deleteNextPendingEvents(limit: UInt) async throws {
        try await updateEventsLocalStore.deleteNextPendingEvents(limit: limit)
    }

    // MARK: - Live events

    func startBufferingLiveEvents() async throws -> AsyncThrowingStream<UpdateEventEnvelope, Error> {
        try pushChannel.open().compactMap {
            do {
                WireLogger.sync.debug(
                    "decrypting live event",
                    attributes: [.eventEnvelopeID: $0.id]
                )
                var envelope = $0
                envelope.events = try await self.updateEventDecryptor.decryptEvents(in: envelope)
                return envelope
            } catch {
                WireLogger.sync.error(
                    "failed to decrypt live event, dropping: \(error)",
                    attributes: [.eventEnvelopeID: $0.id]
                )
                return nil
            }
        }.toStream()
    }

    func stopReceivingLiveEvents() async {
        pushChannel.close()
    }

    func fetchLastEventEnvelopeID() -> UUID? {
        updateEventsLocalStore.lastEventID()
    }

    func storeLastEventEnvelopeID(_ id: UUID) {
        WireLogger.sync.debug(
            "storing last event id",
            attributes: [.eventEnvelopeID: id]
        )

        updateEventsLocalStore.storeLastEventID(id: id)
    }

}

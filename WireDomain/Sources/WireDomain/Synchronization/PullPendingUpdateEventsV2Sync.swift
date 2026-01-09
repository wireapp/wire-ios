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
import WireCoreCrypto
import WireDataModel
import WireLogging
import WireNetwork

/// Closure to generate syncMarker, use for testing
public typealias SyncMarkerGenerator = () -> String

public struct PullPendingUpdateEventsSyncV2: PullPendingUpdateEventsSyncV2Protocol {
    enum Failure: Error {
        case acknowledgeFailed
    }

    private let selfClientID: String
    private let pushChannelAPI: any PushChannelV2API
    private let updateEventsStore: any UpdateEventsLocalStoreProtocol
    private let journal: Journal
    private let decryptor: any UpdateEventDecryptorProtocol
    private let coreCryptoProvider: any CoreCryptoProviderProtocol
    private let jsonEncoder = JSONEncoder()
    private let logger = WireLogger.sync
    private let syncMarkerGenerator: SyncMarkerGenerator

    let stream: AsyncStream<[UpdateEvent]>
    private let continuation: AsyncStream<[UpdateEvent]>.Continuation

    public init(
        selfClientID: String,
        pushChannelAPI: any PushChannelV2API,
        updateEventsStore: any UpdateEventsLocalStoreProtocol,
        journal: Journal,
        decryptor: any UpdateEventDecryptorProtocol,
        coreCryptoProvider: any CoreCryptoProviderProtocol,
        syncMarkerGenerator: @escaping SyncMarkerGenerator = { UUID().uuidString }
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.updateEventsStore = updateEventsStore
        self.journal = journal
        self.decryptor = decryptor
        self.coreCryptoProvider = coreCryptoProvider

        let (finalStream, continuation) = AsyncStream<[UpdateEvent]>.makeStream()
        self.stream = finalStream
        self.continuation = continuation
        self.syncMarkerGenerator = syncMarkerGenerator
    }

    private var logAttributes: WireLogging.LogAttributes {
        .incrementalSyncV3 + .newNSE
    }

    public func pull() async throws {
        let syncMarker = syncMarkerGenerator()

        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID, marker: syncMarker)

        let liveEventStream = try await pushChannel.open()

        logger.debug("handling live event stream", attributes: logAttributes)
        do {
            streamLoop: for try await element in liveEventStream {
                try Task.checkCancellation()

                switch element {
                case let .syncMarker(marker, deliveryTag):
                    try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: false)
                    if marker == syncMarker {
                        logger.debug("upToDate event", attributes: logAttributes)
                        continuation.finish()
                        break streamLoop
                    }
                case .missedEvents:
                    logger.warn(
                        "missedEvents event, full sync required, open main app",
                        attributes: logAttributes,
                        .safePublic
                    )
                    // end the stream gracefully so notifications can be shown
                    continuation.finish()
                    break streamLoop
                case let .events(envelopes):
                    do {
                        try await processBatch(
                            envelopes: envelopes,
                            pushChannel: pushChannel
                        )

                    } catch {
                        // TODO: [WPB-10458] review handling errors of processingEvents
                        // in case of thrown errors, we skip to the next event
                        // errors are already logged if needed
                        continue
                    }
                }
            }
            WireLogger.sync.debug("end of forloop closing pushChannel")
            // end of stream so we close the pushChannel
            await pushChannel.close()
        } catch {
            logger.warn(
                "live event stream encountered error: \(String(describing: error))",
                attributes: logAttributes
            )
            await pushChannel.close()
            continuation.finish()
        }
    }

    private func processBatch(
        envelopes: [UpdateEventEnvelope],
        pushChannel: PushChannelV2Protocol
    ) async throws {

        var storedEnvelopes: [(UpdateEventEnvelope, Int64)] = []

        // decrypt
        try await coreCryptoProvider.coreCrypto().perform { coreCryptoContext in
            for envelope in envelopes {
                var envelope = envelope
                envelope.events = await decryptEnvelope(envelope, in: coreCryptoContext)
                continuation.yield(envelope.events)

                // store
                let index = try await storeEnvelope(envelope)
                storedEnvelopes.append((envelope, index))
            }
        }

        // ack the decrypted events
        //
        // NOTE: it's important that we ack after the CC transaction has succesfully completed,
        // otherwise we risk data loss in case of a crash.
        if let lastEnvelope = storedEnvelopes.last?.0 {
            try await acknowledgeUntilEnvelope(lastEnvelope, through: pushChannel, batchSize: storedEnvelopes.count)
        }
    }

    private func decryptEnvelope(
        _ envelope: UpdateEventEnvelope,
        in context: CoreCryptoContextProtocol
    ) async -> [UpdateEvent] {
        logger.debug(
            "decrypting live event envelope v3",
            attributes: [.eventEnvelopeID: envelope.id] + logAttributes
        )
        let decryptionEventsResult = await decryptor.decryptEvents(in: envelope, context: context)

        let brokenMLSGroupIDs = decryptionEventsResult.brokenMLSGroupIDs
        if !brokenMLSGroupIDs.isEmpty {
            journal.addValues(Set(brokenMLSGroupIDs), for: .brokenMLSGroupIDs)
        }
        return decryptionEventsResult.events
    }

    private func storeEnvelope(_ envelope: UpdateEventEnvelope) async throws -> Int64 {
        let index: Int64
        do {
            // Store.
            logger.debug(
                "storing live event envelope",
                attributes: [.eventEnvelopeID: envelope.id] + logAttributes
            )
            index = try await updateEventsStore.indexOfLastEventEnvelope() + 1
            try await updateEventsStore.persistEventEnvelope(envelope, index: index)
        } catch {
            logger.error(
                "failed to store live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + logAttributes
            )
            throw error
        }

        return index
    }

    private func acknowledgeUntilEnvelope(
        _ envelope: UpdateEventEnvelope,
        through pushChannel: PushChannelV2Protocol,
        batchSize: Int
    ) async throws {
        do {
            if let deliveryTag = envelope.deliveryTag {
                logger.debug(
                    "ack event envelope",
                    attributes: [.eventEnvelopeID: envelope.id, .ackMultipleEventsCount: batchSize] + logAttributes
                )
                try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: true)
            }
        } catch {
            throw Failure.acknowledgeFailed
        }
    }
}

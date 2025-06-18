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
import WireDataModel
import WireLogging

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
    
    public init(
        selfClientID: String,
        pushChannelAPI: any PushChannelV2API,
        updateEventsStore: any UpdateEventsLocalStoreProtocol,
        journal: Journal,
        decryptor: any UpdateEventDecryptorProtocol,
        coreCryptoProvider: any CoreCryptoProviderProtocol
    ) {
        self.selfClientID = selfClientID
        self.pushChannelAPI = pushChannelAPI
        self.updateEventsStore = updateEventsStore
        self.journal = journal
        self.decryptor = decryptor
        self.coreCryptoProvider = coreCryptoProvider
    }

    private var logAttributes: WireLogging.LogAttributes {
        .syncAttributes(initialSync: true) + .newNSE
    }

    @discardableResult
    public func pull() async throws -> AsyncStream<[UpdateEvent]> {

        let (finalStream, continuation) = AsyncStream<[UpdateEvent]>.makeStream()
        let pushChannel = try await pushChannelAPI.createPushChannel(clientID: selfClientID)
        
        let liveEventStream = try await pushChannel.open()

        logger.debug("handling live event stream", attributes: logAttributes)
        do {
            for try await element in liveEventStream {
                logger.debug(
                    "received live element: \(element)",
                    attributes: .syncAttributes(initialSync: false)
                )
                switch element {
                case .upToDate:
                    logger.debug("upToDate event", attributes: logAttributes)
                    continuation.finish()
                    break
                case .missedEvents:
                    logger.debug("missedEvents event", attributes: logAttributes)
                    // do nothing
                    break
                case .syncing:
                    // ignore this event, it gives the number of messages until we're caught up
                    try await pushChannel.acknowledgeMessageCount()
                case let .event(envelope):
                    do {

                        var decryptedEnvelope = envelope
                        decryptedEnvelope.events = try await decryptEnvelope(decryptedEnvelope)
                        continuation.yield(decryptedEnvelope.events)
                        
                        _ = try await storeEnvelope(decryptedEnvelope)
                        try await acknowledgeEnvelope(decryptedEnvelope, through: pushChannel)

                    } catch {
                        // in case of thrown errors, we skip to the next event
                        // errors are already logged if needed
                        continue
                    }
                }
            }

        } catch {
            // if we end up here, the pushChannel is closed
            logger.warn(
                "live event stream encountered error: \(String(describing: error))",
                attributes: logAttributes
            )
            // TODO: handle error
            //continuation.finish(throwing: error)
        }
        return finalStream
    }
    
    private func decryptEnvelope(_ envelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        do {
            // Decrypt.
            logger.debug(
                "decrypting live event envelope  v3",
                attributes: [.eventEnvelopeID: envelope.id] + logAttributes
            )
            // TODO: [WPB-17703] add batch decryption
            let decryptionEventsResult = try await decryptor.decryptEvents(in: envelope, context: nil)

            let brokenMLSGroupIDs = decryptionEventsResult.brokenMLSGroupIDs
            if !brokenMLSGroupIDs.isEmpty {
                journal.addValues(Set(brokenMLSGroupIDs), for: .brokenMLSGroupIDs)
            }
            return decryptionEventsResult.events
        } catch {
            logger.error(
                "failed to decrypt live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + logAttributes
            )
            throw error
        }
    }

    private func storeEnvelope(_ envelope: UpdateEventEnvelope) async throws -> Int64 {
        let index: Int64
        do {
            // Store.
            logger.debug(
                "storing live event envelope",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            index = try await updateEventsStore.indexOfLastEventEnvelope() + 1
            try await updateEventsStore.persistEventEnvelope(envelope, index: index)
        } catch {
            logger.error(
                "failed to store live event envelope: \(String(describing: error))",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            throw error
        }

        return index
    }

    private func acknowledgeEnvelope(
        _ envelope: UpdateEventEnvelope,
        through pushChannel: PushChannelV2Protocol
    ) async throws {
        if let deliveryTag = envelope.deliveryTag {
            logger.debug(
                "ack event envelope",
                attributes: [.eventEnvelopeID: envelope.id] + .syncAttributes(initialSync: false)
            )
            try await pushChannel.acknowledgeEvent(deliveryTag: deliveryTag, multiple: false)
        } else {
            throw Failure.acknowledgeFailed
        }
    }

}

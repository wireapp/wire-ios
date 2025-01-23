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
import WireCoreCrypto
import WireDataModel
import WireLogging

// sourcery: AutoMockable
/// Decrypt the E2EE content within update events.
protocol UpdateEventDecryptorProtocol {

    /// Decrypt events in the given event envelope.
    ///
    /// - Parameter eventEnvelope: An event envelope that contains events received from the server.
    /// - Returns: A list of decrypted update events.

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope) async throws -> [UpdateEvent]

}

struct UpdateEventDecryptor: UpdateEventDecryptorProtocol {

    private let proteusMessageDecryptor: any ProteusMessageDecryptorProtocol
    private let mlsMessageDecryptor: any MLSMessageDecryptorProtocol
    private let messageLocalStore: any MessageLocalStoreProtocol

    init(
        proteusService: any ProteusServiceInterface,
        mlsService: any MLSServiceInterface,
        mlsDecryptionService: any MLSDecryptionServiceInterface,
        userClientsLocalStore: any UserClientsLocalStoreProtocol,
        messageLocalStore: any MessageLocalStoreProtocol,
        userLocalStore: any UserLocalStoreProtocol,
        conversationLocalStore: any ConversationLocalStoreProtocol
    ) {
        self.proteusMessageDecryptor = ProteusMessageDecryptor(
            proteusService: proteusService,
            userClientsLocalStore: userClientsLocalStore,
            userLocalStore: userLocalStore
        )

        self.mlsMessageDecryptor = MLSMessageDecryptor(
            mlsDecryptionService: mlsDecryptionService,
            mlsService: mlsService,
            conversationLocalStore: conversationLocalStore
        )

        self.messageLocalStore = messageLocalStore
    }

    init(
        proteusMessageDecryptor: any ProteusMessageDecryptorProtocol,
        mlsMessageDecryptor: any MLSMessageDecryptorProtocol,
        messageLocalStore: any MessageLocalStoreProtocol
    ) {
        self.proteusMessageDecryptor = proteusMessageDecryptor
        self.mlsMessageDecryptor = mlsMessageDecryptor
        self.messageLocalStore = messageLocalStore
    }

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        let logAttributes: LogAttributes = [
            .eventId: eventEnvelope.id.safeForLoggingDescription,
            .public: true
        ]

        var decryptedEvents = [UpdateEvent]()

        for event in eventEnvelope.events {
            switch event {
            case let .conversation(.proteusMessageAdd(eventData)):
                WireLogger.updateEvent.info(
                    "decrypting proteus event...",
                    attributes: logAttributes
                )

                do {
                    let decryptedEventData = try await proteusMessageDecryptor.decryptedEventData(from: eventData)
                    decryptedEvents.append(.conversation(.proteusMessageAdd(decryptedEventData)))
                } catch let error as ProteusService.DecryptionError {
                    WireLogger.updateEvent.error(
                        "failed to decrypt proteus event payload, dropping: \(error.localizedDescription)",
                        attributes: logAttributes
                    )

                    await appendFailedToDecryptProteusMessage(
                        eventData: eventData,
                        error: error.proteusError
                    )
                } catch {
                    WireLogger.updateEvent.error(
                        "failed to decrypt proteus event, dropping: \(error.localizedDescription)",
                        attributes: logAttributes
                    )
                }

            case let .conversation(.mlsMessageAdd(eventData)):

                WireLogger.updateEvent.info(
                    "decrypting MLS event...",
                    attributes: logAttributes
                )

                do {
                    let decryptedEventData = try await mlsMessageDecryptor.decryptedEventData(from: eventData)
                    decryptedEvents.append(.conversation(.mlsMessageAdd(decryptedEventData)))

                } catch {
                    WireLogger.updateEvent.error(
                        "failed to decrypt MLS event, dropping: \(error.localizedDescription)",
                        attributes: logAttributes
                    )
                }

            default:
                // No decryption needed.
                decryptedEvents.append(event)
            }
        }

        return decryptedEvents
    }

    private func appendFailedToDecryptProteusMessage(
        eventData: ConversationProteusMessageAddEvent,
        error: ProteusError
    ) async {
        // Do not notify the user if the error is just "duplicated".
        if error == .DuplicateMessage {
            return
        }

        let systemMessageType: SystemMessageType = .decryptionFailed(
            sender: (eventData.senderID.uuid, eventData.senderID.domain),
            senderClientID: eventData.messageSenderClientID,
            remoteIdentityChanged: error == .RemoteIdentityChanged,
            date: eventData.timestamp
        )

        await messageLocalStore.addSystemMessage(
            messageType: systemMessageType,
            conversationID: eventData.conversationID.uuid,
            conversationDomain: eventData.conversationID.domain
        )
    }

}

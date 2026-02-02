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

struct UpdateEventDecryptor: UpdateEventDecryptorProtocol {

    private let proteusMessageDecryptor: any ProteusMessageDecryptorProtocol
    private let mlsMessageDecryptor: any MLSMessageDecryptorProtocol
    private let messageLocalStore: any MessageLocalStoreProtocol
    private let mlsService: (any MLSServiceInterface)? // optional because only necessary for live events

    init(
        proteusService: any ProteusServiceInterface,
        mlsService: (any MLSServiceInterface)?,
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
            conversationLocalStore: conversationLocalStore
        )

        self.mlsService = mlsService

        self.messageLocalStore = messageLocalStore
    }

    init(
        proteusMessageDecryptor: any ProteusMessageDecryptorProtocol,
        mlsMessageDecryptor: any MLSMessageDecryptorProtocol,
        mlsService: (any MLSServiceInterface)?,
        messageLocalStore: any MessageLocalStoreProtocol
    ) {
        self.proteusMessageDecryptor = proteusMessageDecryptor
        self.mlsMessageDecryptor = mlsMessageDecryptor
        self.messageLocalStore = messageLocalStore
        self.mlsService = mlsService
    }

    func decryptEvents(
        in eventEnvelope: UpdateEventEnvelope,
        context: CoreCryptoContextProtocol?
    ) async -> EventDecryptorResult {
        guard !DeveloperFlag.skipMLSMessagesDecryption.isOn else {
            return EventDecryptorResult(events: [], brokenMLSGroupIDs: [])
        }
        var logAttributes: LogAttributes = [
            .eventId: eventEnvelope.id.safeForLoggingDescription,
            .public: true
        ]

        var decryptedEvents = [UpdateEvent]()
        var brokenMLSGroupIDs = Set<String>()

        for event in eventEnvelope.events {
            logAttributes[.messageType] = event.name
            switch event {
            case let .conversation(.proteusMessageAdd(eventData)):
                WireLogger.updateEvent.info(
                    "decrypting proteus event...",
                    attributes: logAttributes
                )

                do {
                    let decryptedEventData = try await proteusMessageDecryptor.decryptedEventData(
                        from: eventData,
                        context: context
                    )
                    decryptedEvents.append(.conversation(.proteusMessageAdd(decryptedEventData)))
                } catch let error as ProteusService.DecryptionError {
                    WireLogger.updateEvent.error(
                        "failed to decrypt proteus event payload, dropping: \(String(describing: error))",
                        attributes: logAttributes
                    )

                    await appendFailedToDecryptProteusMessage(
                        eventData: eventData,
                        error: error.proteusError
                    )
                } catch {
                    WireLogger.updateEvent.error(
                        "failed to decrypt proteus event, dropping: \(String(describing: error))",
                        attributes: logAttributes
                    )
                }

            case let .conversation(.mlsMessageAdd(eventData)):

                WireLogger.updateEvent.info(
                    "decrypting MLS add message event...",
                    attributes: logAttributes
                )

                do {
                    let decryptedEventData = try await mlsMessageDecryptor.decryptedMessageAddEventData(
                        from: eventData,
                        context: context
                    )
                    decryptedEvents.append(.conversation(.mlsMessageAdd(decryptedEventData)))

                } catch let error as MLSMessageDecryptorError {
                    switch error {
                    case let .wrongEpoch(mlsGroupID):
                        WireLogger.updateEvent.error(
                            "failed to decrypt MLS due to `WrongEpoch` for group \(mlsGroupID)",
                            attributes: logAttributes
                        )
                        brokenMLSGroupIDs.insert(mlsGroupID.description)
                    default:
                        WireLogger.updateEvent.error(
                            "failed to decrypt MLS add message event, dropping: \(String(describing: error))",
                            attributes: logAttributes
                        )
                    }
                } catch {
                    WireLogger.updateEvent.error(
                        "failed to decrypt MLS add message event, dropping: \(String(describing: error))",
                        attributes: logAttributes
                    )
                }

            case let .conversation(.mlsWelcome(eventData)):

                do {
                    try await mlsMessageDecryptor.decryptedWelcomeMessageEventData(
                        from: eventData,
                        context: context
                    )
                } catch {
                    WireLogger.updateEvent.error(
                        "failed to decrypt MLS welcome message event, dropping: \(String(describing: error))",
                        attributes: logAttributes
                    )
                }

            default:
                // No decryption needed.
                decryptedEvents.append(event)
            }
        }

        return EventDecryptorResult(events: decryptedEvents, brokenMLSGroupIDs: brokenMLSGroupIDs)
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
            sender: (eventData.senderID.id, eventData.senderID.domain),
            senderClientID: eventData.messageSenderClientID,
            remoteIdentityChanged: error == .RemoteIdentityChanged,
            date: eventData.timestamp
        )

        await messageLocalStore.addSystemMessage(
            messageType: systemMessageType,
            conversationID: eventData.conversationID.id,
            conversationDomain: eventData.conversationID.domain
        )
    }

}

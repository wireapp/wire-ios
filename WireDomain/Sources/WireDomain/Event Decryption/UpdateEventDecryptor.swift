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

// MARK: - UpdateEventDecryptorProtocol

// sourcery: AutoMockable
/// Decrypt the E2EE content within update events.
protocol UpdateEventDecryptorProtocol {
    /// Decrypt events in the given event envelope.
    ///
    /// - Parameter eventEnvelope: An event envelope that contains events received from the server.
    /// - Returns: A list of decrypted update events.

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope) async throws -> [UpdateEvent]
}

// MARK: - UpdateEventDecryptor

struct UpdateEventDecryptor: UpdateEventDecryptorProtocol {
    private let proteusMessageDecryptor: any ProteusMessageDecryptorProtocol
    private let context: NSManagedObjectContext

    init(
        proteusService: any ProteusServiceInterface,
        context: NSManagedObjectContext
    ) {
        self.proteusMessageDecryptor = ProteusMessageDecryptor(
            proteusService: proteusService,
            managedObjectContext: context
        )
        self.context = context
    }

    init(
        proteusMessageDecryptor: any ProteusMessageDecryptorProtocol,
        context: NSManagedObjectContext
    ) {
        self.proteusMessageDecryptor = proteusMessageDecryptor
        self.context = context
    }

    func decryptEvents(in eventEnvelope: UpdateEventEnvelope) async throws -> [UpdateEvent] {
        let logAttributes: LogAttributes = [
            .eventId: eventEnvelope.id.safeForLoggingDescription,
            .public: true,
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

                } catch let error as ProteusError {
                    WireLogger.updateEvent.error(
                        "failed to decrypt proteus event payload, dropping: \(error.localizedDescription)",
                        attributes: logAttributes
                    )

                    await appendFailedToDecryptProteusMessage(
                        eventData: eventData,
                        error: error
                    )
                } catch {
                    WireLogger.updateEvent.error(
                        "failed to decrypt proteus event, dropping: \(error.localizedDescription)",
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
        if error == .outdatedMessage || error == .duplicateMessage {
            return
        }

        await context.perform { [context] in
            guard
                let conversation = ZMConversation.fetch(
                    with: eventData.conversationID.uuid,
                    domain: eventData.conversationID.domain,
                    in: context
                ),
                let sender = ZMUser.fetch(
                    with: eventData.senderID.uuid,
                    domain: eventData.senderID.domain,
                    in: context
                ),
                let senderClient = sender.clients.first(where: {
                    $0.remoteIdentifier == eventData.messageSenderClientID
                })
            else {
                return
            }

            conversation.appendDecryptionFailedSystemMessage(
                at: eventData.timestamp,
                sender: sender,
                client: senderClient,
                errorCode: error.rawValue
            )
        }
    }
}

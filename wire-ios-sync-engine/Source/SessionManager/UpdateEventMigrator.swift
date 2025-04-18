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
import WireDomain
import WireLogging
import WireTransport

struct UpdateEventMigrator {

    private let dao: UpdateEventMigratorDAO
    private let localDomain: String
    private let apiVersion: WireTransport.APIVersion

    init(
        context: NSManagedObjectContext,
        localDomain: String,
        apiVersion: WireTransport.APIVersion
    ) {
        dao = UpdateEventMigratorDAO(context: context)
        self.localDomain = localDomain
        self.apiVersion = apiVersion
    }

    var isMigrationNeeded: Bool {
        let newSyncIsAvailable = apiVersion >= .v8
        let hasLegacyEvents = true
        let didAlreadyMigrate = false

        if didAlreadyMigrate && hasLegacyEvents {
            assertionFailure("update events migrated but some still remain")
        }

        return newSyncIsAvailable && !didAlreadyMigrate && hasLegacyEvents
    }

    func migrateLegacyUpdateEvents() async throws {
        WireLogger.sync.debug("migrating legacy update events...")

        // Store new events starting at this index.
        var currentIndex = try await dao.indexOfLastEventEnvelope() + 1

        // TODO: pass in private keys
        while let legacyEvents = await dao.nextBatchOfLegacyEvents(privateKeys: nil) {
            WireLogger.sync.debug("found \(legacyEvents.count) legacy events to migrate...")

            for legacyEvent in legacyEvents {
                // Map it to the new event model.
                guard let newUpdateEvent = UpdateEvent(
                    legacyEvent: legacyEvent,
                    localDomain: localDomain
                ) else {
                    WireLogger.sync.warn("legacy event does not need mapping, skipping...")
                    continue
                }

                guard let eventID = legacyEvent.uuid else {
                    WireLogger.sync.warn("legacy event is missing id, skipping...")
                    continue
                }

                // Wrap it in an envelope.
                let newUpdateEventEnvelope = UpdateEventEnvelope(
                    id: eventID,
                    events: [newUpdateEvent],
                    isTransient: legacyEvent.isTransient
                )

                WireLogger.sync.debug(
                    "storing new event",
                    attributes: [.eventId: eventID]
                )

                // Store the new event.
                try await dao.insertEventEnvelope(
                    newUpdateEventEnvelope,
                    index: currentIndex
                )

                // Store the next event at this index.
                currentIndex += 1
            }
        }

        WireLogger.sync.debug("no more legacy events to migrate...")
        WireLogger.sync.debug("deleting all legacy events...")
        try await dao.deleteAllLegacyEvents()

        WireLogger.sync.debug("saving database changes...")
        try await dao.save()

        WireLogger.sync.debug("legacy event migration complete")
    }

}

private extension UpdateEvent {

    init?(
        legacyEvent: ZMUpdateEvent,
        localDomain: String
    ) {
        switch legacyEvent.type {
        case .conversationDelete:
            guard let event = Self.conversationDeleteEvent(
                from: legacyEvent,
                localDomain: localDomain
            ) else {
                return nil
            }

            self = .conversation(.delete(event))

        case .conversationMessageAdd:
            guard let event = Self.conversationMLSMessageAddEvent(
                from: legacyEvent,
                localDomain: localDomain
            ) else {
                return nil
            }

            self = .conversation(.mlsMessageAdd(event))

        case .conversationMLSWelcome:
            guard let event = Self.conversationMLSWelcomeEvent(
                from: legacyEvent,
                localDomain: localDomain
            ) else {
                return nil
            }

            self = .conversation(.mlsWelcome(event))

        case .conversationOtrMessageAdd:
            guard let event = Self.conversationProteusMessageAddEvent(
                from: legacyEvent,
                localDomain: localDomain
            ) else {
                return nil
            }

            self = .conversation(.proteusMessageAdd(event))

        case .federationConnectionRemoved:
            guard let event = Self.federationConnectionRemovedEvent(
                from: legacyEvent
            ) else {
                return nil
            }
            
            self = .federation(.connectionRemoved(event))

        case .federationDelete:
            guard let event = Self.federationDeleteEvent(
                from: legacyEvent
            ) else {
                return nil
            }

            self = .federation(.delete(event))

        case .userPushRemove:
            self = .user(.pushRemove)

        default:
            return nil
        }
    }

    // MARK: - Conversation events

    private static func conversationDeleteEvent(
        from event: ZMUpdateEvent,
        localDomain: String
    ) -> ConversationDeleteEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.ConversationEvent<Payload.UpdateConversationDeleted>.self,
                from: event.payload
            ),
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain),
            let timestamp = payload.timestamp
        else {
            return nil
        }

        return ConversationDeleteEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp
        )
    }

    private static func conversationMLSMessageAddEvent(
        from event: ZMUpdateEvent,
        localDomain: String
    ) -> ConversationMLSMessageAddEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.ConversationEvent<DecryptedMLSMessageAddEvent>.self,
                from: event.payload
            ),
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain),
            let timestamp = payload.timestamp
        else {
            return nil
        }

        // Each mls message can actually produce multiple messages
        // when it is decrypted. The legacy code will multiply the
        // single ZMUpdateEvent, replacing the original encrypted
        // message with one of the decrypted messages. For this
        // reason we only have one decrypted message here. This
        // differs from the new code, which will store all decrypted
        // messages as an additional value in the add event. This
        // means we will map of the legacy add events into a corresponding new add event with a single decrypted
        // message.
        let decryptedMessage = ConversationMLSMessageAddEvent.DecryptedMessage(
            message: payload.data.text,
            senderClientID: payload.data.sender
        )

        return ConversationMLSMessageAddEvent(
            conversationID: conversationID,
            senderID: senderID,
            subconversation: payload.subconversationType?.rawValue,
            message: decryptedMessage.message,
            timestamp: timestamp,
            decryptedMessages: [decryptedMessage]
        )
    }

    private static func conversationMLSWelcomeEvent(
        from event: ZMUpdateEvent,
        localDomain: String
    ) -> ConversationMLSWelcomeEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.ConversationEvent<MLSWelcomeEvent>.self,
                from: event.payload
            ),
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain)
        else {
            return nil
        }

        return ConversationMLSWelcomeEvent(
            conversationID: conversationID,
            senderID: senderID,
            welcomeMessage: payload.data.message
        )
    }

    private static func conversationProteusMessageAddEvent(
        from event: ZMUpdateEvent,
        localDomain: String
    ) -> ConversationProteusMessageAddEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.ConversationEvent<DecryptedProteusMessageEvent>.self,
                from: event.payload
            ),
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain),
            let timestamp = payload.timestamp
        else {
            return nil
        }

        // We no longer have the encrypted message, but it
        // doesn't matter.
        let message = MessageContent(
            encryptedMessage: "Not available",
            decryptedMessage: payload.data.text
        )

        // External data is still encrypted because we only
        // decrypt when processing the update event.
        let externalData = payload.data.external.map { external in
            MessageContent(
                encryptedMessage: external,
                decryptedMessage: nil
            )
        }

        return ConversationProteusMessageAddEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            message: message,
            externalData: externalData,
            messageSenderClientID: payload.data.sender,
            messageRecipientClientID: payload.data.recipient
        )
    }

    // MARK: - Federation events

    private static func federationConnectionRemovedEvent(from event: ZMUpdateEvent) -> FederationConnectionRemovedEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.ConnectionRemoved.self,
                from: event.payload
            )
        else {
            return nil
        }

        return FederationConnectionRemovedEvent(domains: Set(payload.domains))
    }

    private static func federationDeleteEvent(from event: ZMUpdateEvent) -> FederationDeleteEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.FederationDelete.self,
                from: event.payload
            )
        else {
            return nil
        }

        return FederationDeleteEvent(domain: payload.domain)
    }

}

private extension Payload.ConversationEvent {

    func conversationID(localDomain: String) -> ConversationID? {
        guard let uuid = qualifiedID?.uuid ?? id else {
            return nil
        }

        return ConversationID(
            uuid: uuid,
            domain: qualifiedID?.domain ?? localDomain
        )
    }

    func senderID(localDomain: String) -> UserID? {
        guard let uuid = qualifiedFrom?.uuid ?? from else {
            return nil
        }

        return UserID(
            uuid: uuid,
            domain: qualifiedFrom?.domain ?? localDomain
        )
    }

}

private struct DecryptedMLSMessageAddEvent: EventData, Codable {

    static var eventType: ZMUpdateEventType {
        .conversationMLSMessageAdd
    }

    let text: String
    let sender: String?

}

private struct MLSWelcomeEvent: EventData, Codable {

    static var eventType: ZMUpdateEventType {
        .conversationMLSWelcome
    }

    let message: String

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        message = try container.decode(String.self)
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(message)
    }

}

private struct DecryptedProteusMessageEvent: EventData, Codable {

    static var eventType: ZMUpdateEventType {
        .conversationOtrMessageAdd
    }

    let text: String
    let external: String?
    let sender: String
    let recipient: String

}

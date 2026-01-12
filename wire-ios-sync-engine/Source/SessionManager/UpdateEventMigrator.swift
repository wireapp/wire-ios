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
import WireDomain
import WireLogging
import WireNetwork
import WireTransport

struct UpdateEventMigrator {

    private let dao: any UpdateEventMigratorDAOProtocol
    private let localDomain: String

    init(
        dao: any UpdateEventMigratorDAOProtocol,
        localDomain: String
    ) {
        self.dao = dao
        self.localDomain = localDomain
    }

    func isMigrationNeeded() async throws -> Bool {
        try await dao.existsLegacyEvent()
    }

    func migrateLegacyUpdateEvents() async throws {
        do {
            try await internalMigrateLegacyUpdateEvents()
        } catch {
            WireLogger.sync.error(
                "failed to migrate legacy update events, discarding changes. " +
                    "Error: \(String(describing: error))"
            )
            await dao.discardChanges()
            throw error
        }
    }

    private func internalMigrateLegacyUpdateEvents() async throws {
        WireLogger.sync.debug("migrating legacy update events...")

        // Store new events starting at this index.
        var currentIndex = try await dao.indexOfLastEventEnvelope() + 1

        // TODO: [WPB-17302] pass in private keys
        while let legacyEvents = await dao.nextBatchOfLegacyEvents(privateKeys: nil) {
            WireLogger.sync.debug("found \(legacyEvents.count) legacy events to migrate...")

            for legacyEvent in legacyEvents {
                // Map it to the new event model.
                let newUpdateEvent: UpdateEvent?
                do {
                    newUpdateEvent = try UpdateEvent(
                        legacyEvent: legacyEvent,
                        localDomain: localDomain
                    )
                } catch {
                    WireLogger.sync.error(
                        """
                        failed to map legacy event, skipping... \
                        reason: \(String(describing: error))
                        """
                    )
                    continue
                }

                guard let newUpdateEvent else {
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

            WireLogger.sync.debug("deleting batch of legacy events...")
            await dao.deleteNextBatchOfLegacyEvents()

            WireLogger.sync.debug("saving...")
            try await dao.save()
        }

        WireLogger.sync.debug("legacy event migration complete")
    }

}

private extension UpdateEvent {

    enum Failure: Error {

        case failedToDecodeLegacyEvent(any Error)
        case missingRequiredField

    }

    init?(
        legacyEvent: ZMUpdateEvent,
        localDomain: String
    ) throws {
        switch legacyEvent.type {
        case .conversationDelete:
            let event = try Self.conversationDeleteEvent(
                from: legacyEvent,
                localDomain: localDomain
            )

            self = .conversation(.delete(event))

        case .conversationMemberLeave:
            let event = try Self.conversationMemberLeaveEvent(
                from: legacyEvent,
                localDomain: localDomain
            )

            self = .conversation(.memberLeave(event))

        case .conversationMLSMessageAdd:
            let event = try Self.conversationMLSMessageAddEvent(
                from: legacyEvent,
                localDomain: localDomain
            )

            self = .conversation(.mlsMessageAdd(event))

        case .conversationMLSWelcome:
            let event = try Self.conversationMLSWelcomeEvent(
                from: legacyEvent,
                localDomain: localDomain
            )

            self = .conversation(.mlsWelcome(event))

        case .conversationOtrMessageAdd:
            let event = try Self.conversationProteusMessageAddEvent(
                from: legacyEvent,
                localDomain: localDomain
            )

            self = .conversation(.proteusMessageAdd(event))

        case .federationConnectionRemoved:
            let event = try Self.federationConnectionRemovedEvent(
                from: legacyEvent
            )

            self = .federation(.connectionRemoved(event))

        case .federationDelete:
            let event = try Self.federationDeleteEvent(
                from: legacyEvent
            )

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
    ) throws -> ConversationDeleteEvent {
        let payload: Payload.ConversationEvent<Payload.UpdateConversationDeleted>
        do {
            payload = try EventPayloadDecoder().decode(
                type(of: payload),
                from: event.payload
            )
        } catch {
            throw Failure.failedToDecodeLegacyEvent(error)
        }

        guard
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain),
            let timestamp = payload.timestamp
        else {
            throw Failure.missingRequiredField
        }

        return ConversationDeleteEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp
        )
    }

    private static func conversationMemberLeaveEvent(
        from event: ZMUpdateEvent,
        localDomain: String
    ) throws -> ConversationMemberLeaveEvent {
        let payload: Payload.ConversationEvent<Payload.UpdateConversationMemberLeave>
        do {
            payload = try EventPayloadDecoder().decode(
                type(of: payload),
                from: event.payload
            )
        } catch {
            throw Failure.failedToDecodeLegacyEvent(error)
        }

        guard
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain),
            let timestamp = payload.timestamp,
            let leaveReason = payload.data.reason
        else {
            throw Failure.missingRequiredField
        }

        var removedUserIDs = Set<UserID>()

        for userID in payload.data.userIDs ?? [] {
            removedUserIDs.insert(
                UserID(
                    id: userID,
                    domain: localDomain
                )
            )
        }

        for qualifiedUserID in payload.data.qualifiedUserIDs ?? [] {
            removedUserIDs.insert(
                UserID(
                    id: qualifiedUserID.uuid,
                    domain: qualifiedUserID.domain
                )
            )
        }

        let reason = switch leaveReason {
        case .left:
            ConversationMemberLeaveReason.userLeft
        case .removed:
            ConversationMemberLeaveReason.userRemoved
        case .userDeleted:
            ConversationMemberLeaveReason.userDeleted
        }

        return ConversationMemberLeaveEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            removedUserIDs: removedUserIDs,
            reason: reason
        )
    }

    private static func conversationMLSMessageAddEvent(
        from event: ZMUpdateEvent,
        localDomain: String
    ) throws -> ConversationMLSMessageAddEvent {
        let payload: Payload.ConversationEvent<DecryptedMLSMessageAddEvent>
        do {
            payload = try EventPayloadDecoder().decode(
                type(of: payload),
                from: event.payload
            )
        } catch {
            throw Failure.failedToDecodeLegacyEvent(error)
        }

        guard
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain),
            let timestamp = payload.timestamp
        else {
            throw Failure.missingRequiredField
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
    ) throws -> ConversationMLSWelcomeEvent {
        let payload: Payload.ConversationEvent<MLSWelcomeEvent>
        do {
            payload = try EventPayloadDecoder().decode(
                type(of: payload),
                from: event.payload
            )
        } catch {
            throw Failure.failedToDecodeLegacyEvent(error)
        }

        guard
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain)
        else {
            throw Failure.missingRequiredField
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
    ) throws -> ConversationProteusMessageAddEvent {
        let payload: Payload.ConversationEvent<DecryptedProteusMessageEvent>
        do {
            payload = try EventPayloadDecoder().decode(
                type(of: payload),
                from: event.payload
            )
        } catch {
            throw Failure.failedToDecodeLegacyEvent(error)
        }

        guard
            let conversationID = payload.conversationID(localDomain: localDomain),
            let senderID = payload.senderID(localDomain: localDomain),
            let timestamp = payload.timestamp
        else {
            throw Failure.missingRequiredField
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

    private static func federationConnectionRemovedEvent(
        from event: ZMUpdateEvent
    ) throws -> FederationConnectionRemovedEvent {
        let payload: Payload.ConnectionRemoved
        do {
            payload = try EventPayloadDecoder().decode(
                type(of: payload),
                from: event.payload
            )
        } catch {
            throw Failure.failedToDecodeLegacyEvent(error)
        }

        return FederationConnectionRemovedEvent(domains: Set(payload.domains))
    }

    private static func federationDeleteEvent(
        from event: ZMUpdateEvent
    ) throws -> FederationDeleteEvent {
        let payload: Payload.FederationDelete
        do {
            payload = try EventPayloadDecoder().decode(
                type(of: payload),
                from: event.payload
            )
        } catch {
            throw Failure.failedToDecodeLegacyEvent(error)
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
            id: uuid,
            domain: qualifiedID?.domain ?? localDomain
        )
    }

    func senderID(localDomain: String) -> UserID? {
        guard let uuid = qualifiedFrom?.uuid ?? from else {
            return nil
        }

        return UserID(
            id: uuid,
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
        self.message = try container.decode(String.self)
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

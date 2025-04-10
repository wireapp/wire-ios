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
import WireTransport

struct UpdateEventMigrator {

    var isMigrationNeeded: Bool {
        let newSyncIsAvailable = true
        let hasLegacyEvents = true
        let didAlreadyMigrate = false

        if didAlreadyMigrate && hasLegacyEvents {
            assertionFailure("update events migrated but some still remain")
        }

        return newSyncIsAvailable &&
               !didAlreadyMigrate &&
               hasLegacyEvents
    }

    func migrateLegacyUpdateEvents() async throws {
        // fetch legacy events
        // map them
        // store them
        // delete legacy events
        // save event database
    }

}

private extension UpdateEvent {

    init?(_ legacyEvent: ZMUpdateEvent) {
        let localDomain: String? = "local.com"

        switch legacyEvent.type {
        case .conversationDelete:
            guard let event = Self.conversationDeleteEvent(from: legacyEvent) else {
                return nil
            }

            self = event

        case .conversationMemberJoin:
            guard let event = Self.conversationMemberJoinEvent(from: legacyEvent) else {
                return nil
            }

            self = event

        default:
            return nil
        }
    }

    private static func conversationDeleteEvent(from event: ZMUpdateEvent) -> UpdateEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.ConversationEvent<Payload.UpdateConversationDeleted>.self,
                from: event.payload
            ),
            let conversationID = payload.conversationID,
            let senderID = payload.senderID,
            let timestamp = payload.timestamp
        else {
            return nil
        }

        let eventData = ConversationDeleteEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp
        )

        return .conversation(.delete(eventData))
    }

    private static func conversationMemberJoinEvent(from event: ZMUpdateEvent) -> UpdateEvent? {
        let decoder = EventPayloadDecoder()
        guard
            let payload = try? decoder.decode(
                Payload.ConversationEvent<Payload.UpdateConversationMemberJoin>.self,
                from: event.payload
            ),
            let conversationID = payload.conversationID,
            let senderID = payload.senderID,
            let timestamp = payload.timestamp,
            let members = payload.data.users
        else {
            return nil
        }

        let memberData = members.map { member in
            Conversation.Member(
                qualifiedID: member.qualifiedID.map { id in
                    QualifiedID(
                        uuid: id.uuid,
                        domain: id.domain
                    )
                },
                id: member.id,
                qualifiedTarget: member.qualifiedTarget.map { id in
                    QualifiedID(
                        uuid: id.uuid,
                        domain: id.domain
                    )
                },
                target: member.target,
                conversationRole: member.conversationRole,
                service: member.service.map { service in
                    Service(
                        id: service.id,
                        provider: service.provider
                    )
                },
                archived: member.archived,
                archivedReference: member.archivedReference,
                hidden: member.hidden,
                hiddenReference: member.hiddenReference,
                mutedStatus: member.mutedStatus,
                mutedReference: member.mutedReference
            )
        }

        let eventData = ConversationMemberJoinEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: timestamp,
            members: memberData
        )

        return .conversation(.memberJoin(eventData))
    }

}

private extension Payload.ConversationEvent {

    var conversationID: ConversationID? {
        let localDomain: String? = "local.com"
        guard
            let uuid = qualifiedID?.uuid ?? id,
            let domain = qualifiedID?.domain ?? localDomain
        else {
            return nil
        }

        return ConversationID(
            uuid: uuid,
            domain: domain
        )
    }

    var senderID: UserID? {
        let localDomain: String? = "local.com"
        guard
            let uuid = qualifiedFrom?.uuid ?? from,
            let domain = qualifiedFrom?.domain ?? localDomain
        else {
            return nil
        }

        return UserID(
            uuid: uuid,
            domain: domain
        )
    }

}

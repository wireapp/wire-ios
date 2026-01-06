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

public extension Conversation {

    /// Represents a conversation's member.

    struct Member: Equatable, Sendable {

        public let qualifiedID: QualifiedID?
        public let id: UUID?
        public let qualifiedTarget: QualifiedID?
        public let target: UUID?
        public let conversationRole: String?
        public let service: Service?
        public let archived: Bool?
        public let archivedReference: Date?
        public let hidden: Bool?
        public let hiddenReference: String?
        public let mutedStatus: Int?
        public let mutedReference: Date?

        public init(
            qualifiedID: QualifiedID? = nil,
            id: UUID? = nil,
            qualifiedTarget: QualifiedID? = nil,
            target: UUID? = nil,
            conversationRole: String? = nil,
            service: Service? = nil,
            archived: Bool? = nil,
            archivedReference: Date? = nil,
            hidden: Bool? = nil,
            hiddenReference: String? = nil,
            mutedStatus: Int? = nil,
            mutedReference: Date? = nil
        ) {
            self.qualifiedID = qualifiedID
            self.id = id
            self.qualifiedTarget = qualifiedTarget
            self.target = target
            self.conversationRole = conversationRole
            self.service = service
            self.archived = archived
            self.archivedReference = archivedReference
            self.hidden = hidden
            self.hiddenReference = hiddenReference
            self.mutedStatus = mutedStatus
            self.mutedReference = mutedReference
        }
    }

}

extension Conversation {
    struct MemberV0: Equatable, Decodable, Sendable, ToAPIModelConvertible {

        let qualifiedID: QualifiedIDV0?
        let id: UUID?
        let qualifiedTarget: QualifiedIDV0?
        let target: UUID?
        let conversationRole: String?
        let service: ServiceV0?
        let archived: Bool?
        let archivedReference: Date?
        let hidden: Bool?
        let hiddenReference: String?
        let mutedStatus: Int?
        let mutedReference: Date?

        init(
            qualifiedID: QualifiedIDV0? = nil,
            id: UUID? = nil,
            qualifiedTarget: QualifiedIDV0? = nil,
            target: UUID? = nil,
            conversationRole: String? = nil,
            service: ServiceV0? = nil,
            archived: Bool? = nil,
            archivedReference: Date? = nil,
            hidden: Bool? = nil,
            hiddenReference: String? = nil,
            mutedStatus: Int? = nil,
            mutedReference: Date? = nil
        ) {
            self.qualifiedID = qualifiedID
            self.id = id
            self.qualifiedTarget = qualifiedTarget
            self.target = target
            self.conversationRole = conversationRole
            self.service = service
            self.archived = archived
            self.archivedReference = archivedReference
            self.hidden = hidden
            self.hiddenReference = hiddenReference
            self.mutedStatus = mutedStatus
            self.mutedReference = mutedReference
        }

        enum CodingKeys: String, CodingKey {

            case qualifiedID = "qualified_id"
            case id
            case qualifiedTarget = "qualified_target"
            case target
            case conversationRole = "conversation_role"
            case service
            case archived = "otr_archived"
            case archivedReference = "otr_archived_ref"
            case hidden = "otr_hidden"
            case hiddenReference = "otr_hidden_ref"
            case mutedStatus = "otr_muted_status"
            case mutedReference = "otr_muted_ref"

        }

        func toAPIModel() -> Member {
            Conversation.Member(
                qualifiedID: qualifiedID?.toAPIModel(),
                id: id,
                qualifiedTarget: qualifiedTarget?.toAPIModel(),
                target: target,
                conversationRole: conversationRole,
                service: service?.toAPIModel(),
                archived: archived,
                archivedReference: archivedReference,
                hidden: hidden,
                hiddenReference: hiddenReference,
                mutedStatus: mutedStatus,
                mutedReference: mutedReference
            )
        }
    }

}

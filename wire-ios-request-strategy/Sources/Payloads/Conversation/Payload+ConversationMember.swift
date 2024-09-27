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

extension Payload {
    struct ConversationMember: CodableEventData {
        // MARK: Lifecycle

        init(
            id: UUID? = nil,
            qualifiedID: QualifiedID? = nil,
            target: UUID? = nil,
            qualifiedTarget: QualifiedID? = nil,
            service: Service? = nil,
            mutedStatus: Int? = nil,
            mutedReference: Date? = nil,
            archived: Bool? = nil,
            archivedReference: Date? = nil,
            hidden: Bool? = nil,
            hiddenReference: String? = nil,
            conversationRole: String? = nil
        ) {
            self.id = id
            self.qualifiedID = qualifiedID
            self.target = target
            self.qualifiedTarget = qualifiedTarget
            self.service = service
            self.mutedStatus = mutedStatus
            self.mutedReference = mutedReference
            self.archived = archived
            self.archivedReference = archivedReference
            self.hidden = hidden
            self.hiddenReference = hiddenReference
            self.conversationRole = conversationRole
        }

        // MARK: Internal

        struct Service: Codable {
            let id: UUID
            let provider: UUID
        }

        enum CodingKeys: String, CodingKey {
            case id
            case qualifiedID = "qualified_id"
            case target
            case qualifiedTarget = "qualified_target"
            case service
            case mutedStatus = "otr_muted_status"
            case mutedReference = "otr_muted_ref"
            case archived = "otr_archived"
            case archivedReference = "otr_archived_ref"
            case hidden = "otr_hidden"
            case hiddenReference = "otr_hidden_ref"
            case conversationRole = "conversation_role"
        }

        static var eventType: ZMUpdateEventType {
            .conversationMemberUpdate
        }

        let id: UUID?
        let qualifiedID: QualifiedID?
        let target: UUID?
        let qualifiedTarget: QualifiedID?
        let service: Service?
        let mutedStatus: Int?
        let mutedReference: Date?
        let archived: Bool?
        let archivedReference: Date?
        let hidden: Bool?
        let hiddenReference: String?
        let conversationRole: String?
    }
}

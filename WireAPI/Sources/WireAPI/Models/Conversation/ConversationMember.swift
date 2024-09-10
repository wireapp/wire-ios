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

extension Conversation {
    /// Represents a conversation's member.

    public struct Member: Equatable, Codable {
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
    }
}

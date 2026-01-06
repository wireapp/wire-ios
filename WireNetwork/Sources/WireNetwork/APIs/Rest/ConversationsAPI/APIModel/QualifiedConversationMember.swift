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

struct QualifiedConversationMember: Decodable, ToAPIModelConvertible {

    struct Service: Decodable, ToAPIModelConvertible {
        let id: UUID
        let provider: UUID

        func toAPIModel() -> WireNetwork.Service {
            .init(
                id: id,
                provider: provider
            )
        }
    }

    enum CodingKeys: String, CodingKey {
        case archived = "otr_archived"
        case archivedReference = "otr_archived_ref"
        case conversationRole = "conversation_role"
        case hidden = "otr_hidden"
        case hiddenReference = "otr_hidden_ref"
        case id
        case mutedReference = "otr_muted_ref"
        case mutedStatus = "otr_muted_status"
        case qualifiedID = "qualified_id"
        case qualifiedTarget = "qualified_target"
        case service
        case target
    }

    let archived: Bool?
    let archivedReference: UTCTime?
    let conversationRole: String?
    let hidden: Bool?
    let hiddenReference: String?
    let id: UUID?
    let mutedStatus: Int?
    let mutedReference: UTCTime?
    let qualifiedID: QualifiedIDV0?
    let qualifiedTarget: QualifiedIDV0?
    let service: ServiceV0?
    let target: UUID?

    func toAPIModel() -> Conversation.Member {
        Conversation.Member(
            qualifiedID: qualifiedID?.toAPIModel(),
            id: id,
            qualifiedTarget: qualifiedTarget?.toAPIModel(),
            target: target,
            conversationRole: conversationRole,
            service: service?.toAPIModel(),
            archived: archived,
            archivedReference: archivedReference?.date,
            hidden: hidden,
            hiddenReference: hiddenReference,
            mutedStatus: mutedStatus,
            mutedReference: mutedReference?.date
        )
    }
}

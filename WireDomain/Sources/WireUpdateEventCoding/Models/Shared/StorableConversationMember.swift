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

struct StorableConversationMember: Equatable, Codable, Sendable {

    private let qualifiedID: StorableQualifiedID?
    private let id: UUID?
    private let qualifiedTarget: StorableQualifiedID?
    private let target: UUID?
    private let conversationRole: String?
    private let service: StorableService?
    private let archived: Bool?
    private let archivedReference: Date?
    private let hidden: Bool?
    private let hiddenReference: String?
    private let mutedStatus: Int?
    private let mutedReference: Date?

    init(_ value: WireAPI.Conversation.Member) {
        self.qualifiedID = value.qualifiedID.map { StorableQualifiedID($0) }
        self.id = value.id
        self.qualifiedTarget = value.qualifiedTarget.map { StorableQualifiedID($0) }
        self.target = value.target
        self.conversationRole = value.conversationRole
        self.service = value.service.map { StorableService(id: $0.id, provider: $0.provider) }
        self.archived = value.archived
        self.archivedReference = value.archivedReference
        self.hidden = value.hidden
        self.hiddenReference = value.hiddenReference
        self.mutedStatus = value.mutedStatus
        self.mutedReference = value.mutedReference
    }

    func toAPIModel() -> WireAPI.Conversation.Member {
        return .init(
            qualifiedID: self.qualifiedID?.toAPIModel(),
            id: self.id,
            qualifiedTarget: self.qualifiedTarget?.toAPIModel(),
            target: self.target,
            conversationRole: self.conversationRole,
            service: self.service.map { WireAPI.Service(id: $0.id, provider: $0.provider) },
            archived: self.archived,
            archivedReference: self.archivedReference,
            hidden: self.hidden,
            hiddenReference: self.hiddenReference,
            mutedStatus: self.mutedStatus,
            mutedReference: self.mutedReference
        )
    }

}

private struct StorableService: Equatable, Codable, Sendable {

    let id: UUID
    let provider: UUID

}

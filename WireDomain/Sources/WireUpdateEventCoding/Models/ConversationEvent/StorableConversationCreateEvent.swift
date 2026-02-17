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
import WireNetwork

struct StorableConversationCreateEvent: Equatable, Codable, Sendable {

    private let conversationID: StorableQualifiedID
    private let senderID: StorableQualifiedID
    private let timestamp: Date
    private let conversation: StorableConversation

    init(_ value: WireNetwork.ConversationCreateEvent) {
        self.conversationID = StorableQualifiedID(value.conversationID)
        self.senderID = StorableQualifiedID(value.senderID)
        self.timestamp = value.timestamp
        self.conversation = StorableConversation(
            id: value.conversation.id,
            qualifiedID: value.conversation.qualifiedID.map { StorableQualifiedID($0) },
            teamID: value.conversation.teamID,
            type: value.conversation.type.map { StorableConversationType($0) },
            messageProtocol: value.conversation.messageProtocol.map { StorableConversationMessageProtocol($0) },
            mlsGroupID: value.conversation.mlsGroupID,
            cipherSuite: value.conversation.cipherSuite.map { StorableMLSCipherSuite($0) },
            epoch: value.conversation.epoch,
            epochTimestamp: value.conversation.epochTimestamp,
            creator: value.conversation.creator,
            members: value.conversation.members.map { StorableConversationMembers($0) },
            name: value.conversation.name,
            messageTimer: value.conversation.messageTimer,
            readReceiptMode: value.conversation.readReceiptMode,
            access: value.conversation.access?.map { StorableConversationAccessMode($0) },
            accessRoles: value.conversation.accessRoles?.map { StorableConversationAccessRole($0) },
            legacyAccessRole: value.conversation.legacyAccessRole.map { StorableConversationAccessRoleLegacy($0) },
            lastEvent: value.conversation.lastEvent,
            lastEventTime: value.conversation.lastEventTime,
            groupType: value.conversation.groupType.map { StorableConversationGroupType($0) },
            addPermission: value.conversation.addPermission.map { StorableChannelPermission($0) },
            cellsState: value.conversation.cellsState.map { StorableCellsState($0) }
        )
    }

    func toAPIModel() -> WireNetwork.ConversationCreateEvent {
        .init(
            conversationID: conversationID.toAPIModel(),
            senderID: senderID.toAPIModel(),
            timestamp: timestamp,
            conversation: WireNetwork.Conversation(
                id: conversation.id,
                qualifiedID: conversation.qualifiedID?.toAPIModel(),
                teamID: conversation.teamID,
                type: conversation.type?.toAPIModel(),
                messageProtocol: conversation.messageProtocol?.toAPIModel(),
                mlsGroupID: conversation.mlsGroupID,
                cipherSuite: conversation.cipherSuite?.toAPIModel(),
                epoch: conversation.epoch,
                epochTimestamp: conversation.epochTimestamp,
                creator: conversation.creator,
                members: conversation.members?.toAPIModel(),
                name: conversation.name,
                messageTimer: conversation.messageTimer,
                readReceiptMode: conversation.readReceiptMode,
                access: conversation.access?.map { $0.toAPIModel() }.toSet(),
                accessRoles: conversation.accessRoles?.map { $0.toAPIModel() }.toSet(),
                legacyAccessRole: conversation.legacyAccessRole.map { $0.toAPIModel() },
                lastEvent: conversation.lastEvent,
                lastEventTime: conversation.lastEventTime,
                groupType: conversation.groupType?.toAPIModel(),
                addPermission: conversation.addPermission?.toAPIModel(),
                cellsState: conversation.cellsState?.toAPIModel()
            )
        )
    }

}

private struct StorableConversation: Equatable, Codable, Sendable {

    let id: UUID?
    let qualifiedID: StorableQualifiedID?
    let teamID: UUID?
    let type: StorableConversationType?
    let messageProtocol: StorableConversationMessageProtocol?
    let mlsGroupID: String?
    let cipherSuite: StorableMLSCipherSuite?
    let epoch: UInt?
    let epochTimestamp: Date?
    let creator: UUID?
    let members: StorableConversationMembers?
    let name: String?
    let messageTimer: TimeInterval?
    let readReceiptMode: Int?
    let access: [StorableConversationAccessMode]?
    let accessRoles: [StorableConversationAccessRole]?
    let legacyAccessRole: StorableConversationAccessRoleLegacy?
    let lastEvent: String?
    let lastEventTime: Date?
    let groupType: StorableConversationGroupType?
    let addPermission: StorableChannelPermission?
    let cellsState: StorableCellsState?

}

private enum StorableConversationType: String, Codable, Sendable {

    case group
    case `self`
    case oneOnOne
    case connection

    init(_ value: WireNetwork.ConversationType) {
        switch value {
        case .group:
            self = .group
        case .self:
            self = .self
        case .oneOnOne:
            self = .oneOnOne
        case .connection:
            self = .connection
        }
    }

    func toAPIModel() -> WireNetwork.ConversationType {
        switch self {
        case .group:
            .group
        case .self:
            .self
        case .oneOnOne:
            .oneOnOne
        case .connection:
            .connection
        }
    }

}

private enum StorableConversationGroupType: String, Codable, Sendable {

    case group
    case channel

    init(_ value: WireNetwork.ConversationGroupType) {
        switch value {
        case .group:
            self = .group
        case .channel:
            self = .channel
        }
    }

    func toAPIModel() -> WireNetwork.ConversationGroupType {
        switch self {
        case .group:
            .group
        case .channel:
            .channel
        }
    }

}

private enum StorableCellsState: String, Codable, Sendable {

    case ready
    case pending
    case disabled

    init(_ value: WireNetwork.Conversation.CellsState) {
        switch value {
        case .ready:
            self = .ready
        case .pending:
            self = .pending
        case .disabled:
            self = .disabled
        }
    }

    func toAPIModel() -> WireNetwork.Conversation.CellsState {
        switch self {
        case .ready:
            .ready
        case .pending:
            .pending
        case .disabled:
            .disabled
        }
    }
}

private struct StorableConversationMembers: Equatable, Codable, Sendable {

    let others: [StorableConversationMember]
    let selfMember: StorableConversationMember?

    init(_ value: WireNetwork.Conversation.Members) {
        self.others = value.others.map { StorableConversationMember($0) }
        self.selfMember = value.selfMember.map { StorableConversationMember($0) }
    }

    func toAPIModel() -> WireNetwork.Conversation.Members {
        .init(
            others: others.map { $0.toAPIModel() },
            selfMember: selfMember?.toAPIModel()
        )
    }

}

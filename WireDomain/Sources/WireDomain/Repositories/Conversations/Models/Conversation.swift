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

import WireDataModel

public struct Conversation: Equatable {

    struct Members: Equatable {
        let others: [Member]
        let selfMember: Member?

        struct Member: Equatable {
            let qualifiedID: QualifiedID?
            let id: UUID?
            let qualifiedTarget: QualifiedID?
            let target: UUID?
            let conversationRole: String?
            let service: Service?
            let archived: Bool?
            let archivedReference: Date?
            let hidden: Bool?
            let hiddenReference: String?
            let mutedStatus: Int?
            let mutedReference: Date?

            struct Service: Equatable {
                let id: UUID
                let provider: UUID
            }
        }
    }

    enum GroupType {
        case group
        case channel
    }

    public enum ChannelPermission: String {
        case admins
        case everyone
    }

    public enum CellsState: Equatable, Sendable {
        case ready
        case pending
        case disabled
    }

    let id: UUID?
    let qualifiedID: QualifiedID?
    let teamID: UUID?
    let type: BackendConversationType?
    let messageProtocol: MessageProtocol?
    let mlsGroupID: String?
    let cipherSuite: MLSCipherSuite?
    let epoch: UInt?
    let epochTimestamp: Date?
    let creator: UUID?
    let members: Members?
    let name: String?
    let messageTimer: TimeInterval?
    let readReceiptMode: Int?
    let access: [String]?
    let accessRoles: [String]?
    let legacyAccessRole: ConversationAccessRole?
    let lastEvent: String?
    let lastEventTime: Date?
    let groupType: GroupType?
    let addPermission: ChannelPermission?
    let cellsState: CellsState?

}

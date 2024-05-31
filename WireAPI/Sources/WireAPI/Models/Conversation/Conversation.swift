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

public struct Conversation {
    var qualifiedID: QualifiedID?
    var id: UUID?
    var type: Int?
    var creator: UUID?
    var cipherSuite: UInt16?
    var access: [String]?
    var accessRoles: [String]?
    var legacyAccessRole: String?
    var name: String?
    var members: Members?
    var lastEvent: String?
    var lastEventTime: String?
    var teamID: UUID?
    var messageTimer: TimeInterval?
    var readReceiptMode: Int?
    var messageProtocol: String?
    var mlsGroupID: String?
    var epoch: UInt?
    var epochTimestamp: Date?
}

// MARK: -

extension Conversation {
    struct Members {
        let selfMember: Member
        let others: [Member]
    }
}

// MARK: -

extension Conversation {
    struct Member {
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

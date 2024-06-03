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
    var access: [String]?
    var accessRoles: [String]?
    var cipherSuite: UInt16?
    var creator: UUID?
    var epoch: UInt?
    var epochTimestamp: Date?
    var id: UUID?
    var lastEvent: String?
    var lastEventTime: String?
    var legacyAccessRole: String?
    var members: Members?
    var messageProtocol: String?
    var messageTimer: TimeInterval?
    var mlsGroupID: String?
    var name: String?
    var qualifiedID: QualifiedID?
    var readReceiptMode: Int?
    var teamID: UUID?
    var type: Int?
}

// MARK: -

extension Conversation {
    struct Members {
        let others: [Member]
        let selfMember: Member
    }
}

// MARK: -

extension Conversation {
    struct Member {
        let archived: Bool?
        let archivedReference: Date?
        let conversationRole: String?
        let hidden: Bool?
        let hiddenReference: String?
        let id: UUID?
        let mutedReference: Date?
        let mutedStatus: Int?
        let qualifiedID: QualifiedID?
        let qualifiedTarget: QualifiedID?
        let service: Service?
        let target: UUID?
    }
}

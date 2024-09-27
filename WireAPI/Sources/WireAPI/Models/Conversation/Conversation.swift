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

/// Metadata for a conversation.

public struct Conversation: Equatable, Codable {
    // MARK: Public

    /// The unqualified conversation id.

    public var id: UUID?

    /// The qualified conversation id.

    public var qualifiedID: ConversationID?

    /// The owning team id.

    public var teamID: UUID?

    /// The conversation's type.

    public var type: ConversationType?

    /// The conversation's message protocol.

    public var messageProtocol: ConversationMessageProtocol?

    /// The id of the associated mls group.

    public var mlsGroupID: String?

    /// The mls ciphersuite used for E2EE communcation.

    public var cipherSuite: MLSCipherSuite?

    /// The current mls group epoch.

    public var epoch: UInt?

    /// When the mls epoch changed.

    public var epochTimestamp: Date?

    /// The user id of the conversation's creator.

    public var creator: UUID?

    /// The conversation's participants.

    public var members: Members?

    /// The conversation's name.

    public var name: String?

    /// The number of seconds after which messages will self delete.

    public var messageTimer: TimeInterval?

    /// The conversation's read receipt setting.

    public var readReceiptMode: Int?

    /// How users can join a conversation.

    public var access: Set<ConversationAccessMode>?

    /// Which users are allowed to be participants.

    public var accessRoles: Set<ConversationAccessRole>?

    /// LEGACY: Which users are allowed to be participants.
    ///
    /// This can be removed when api v3 is the minimum supported version.

    public var legacyAccessRole: ConversationAccessRoleLegacy?

    public var lastEvent: String?

    public var lastEventTime: Date?

    // MARK: Internal

    enum CodingKeys: String, CodingKey {
        case id
        case qualifiedID = "qualified_id"
        case teamID = "team"
        case type
        case messageProtocol = "protocol"
        case mlsGroupID = "group_id"
        case cipherSuite = "cipher_suite"
        case epoch
        case epochTimestamp = "epoch_timestamp"
        case creator
        case members
        case name
        case messageTimer = "message_timer"
        case readReceiptMode = "receipt_mode"
        case access
        case accessRoles = "access_role_v2"
        case legacyAccessRole = "access_role"
        case lastEvent = "last_event"
        case lastEventTime = "last_event_time"
    }
}

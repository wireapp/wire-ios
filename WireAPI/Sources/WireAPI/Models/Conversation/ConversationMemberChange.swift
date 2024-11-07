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

/// Changed metadata for a member of a conversation.

public struct ConversationMemberChange: Equatable, Codable, Sendable {

    /// The id of the member.

    public let id: UserID

    /// The member's new role.

    public let newRoleName: String?

    /// The member's new mute status.
    ///
    /// This is only relevant for the self user.

    public let newMuteStatus: Int?

    /// The reference date of the new mute status.
    ///
    /// This is only relevant for the self user.

    public let muteStatusReferenceDate: Date?

    /// The member's new archived status.
    ///
    /// This is only relevant for the self user.

    public let newArchivedStatus: Bool?

    /// The reference date of the new archived status.
    ///
    /// This is only relevant for the self user.

    public let archivedStatusReferenceDate: Date?

}

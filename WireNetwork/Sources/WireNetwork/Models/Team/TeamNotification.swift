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

public import Foundation

public struct TeamNotification: Equatable, Sendable {

    /// The id of the notification envelope, used as a cursor when
    /// fetching subsequent notifications.

    public let id: UUID

    /// The kind of event the notification represents.

    public let kind: Kind

    public init(id: UUID, kind: Kind) {
        self.id = id
        self.kind = kind
    }

    public enum Kind: Equatable, Sendable {

        /// A user has joined a team.

        case memberJoin(TeamMemberJoinNotification)

    }

}

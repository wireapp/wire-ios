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

/// User profile for a user

public struct User: Equatable {

    /// The unique id of the user

    public let id: UserID

    /// The user's full name

    public let name: String

    /// The users's unique handle

    public let handle: String?

    /// Team ID if the user belongs to a team

    public let teamID: UUID?

    /// Color accent of the user

    public let accentID: Int

    /// The user's profile image assets

    public let assets: [UserAsset]

    /// Deleted is `True` if the user has been deleted

    public let deleted: Bool?

    /// The email associated with this user

    public let email: String?

    /// The date when user will expire
    ///
    /// Only set of guest (ephemeral) users

    public let expiresAt: Date?

    /// Service information associated with this user

    public let service: Service?

    /// Messaging protocols which this user supports

    public let supportedProtocols: Set<MessageProtocol>?

    /// The user's legalhold status

    public let legalholdStatus: LegalholdStatus
}

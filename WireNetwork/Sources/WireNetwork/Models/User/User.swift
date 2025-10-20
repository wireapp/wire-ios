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

public import Foundation

/// User profile for a user

public struct User: Equatable, Sendable {

    /// The unique id of the user

    public var id: UserID

    /// The user's full name

    public var name: String

    /// The users's unique handle

    public var handle: String?

    /// Team ID if the user belongs to a team

    public var teamID: UUID?

    /// The type of a user: regular, app or bot.
    ///
    /// - returns: One of the three values `regular`, `app` or `bot` if talking to an API of version 12 or later, `nil` otherwise.

    public var type: UserType?

    /// Color accent of the user

    public var accentID: Int

    /// The user's profile image assets

    public var assets: [UserAsset]

    /// Deleted is `True` if the user has been deleted

    public var deleted: Bool?

    /// The email associated with this user

    public var email: String?

    /// The date when user will expire
    ///
    /// Only set of guest (ephemeral) users

    public var expiresAt: Date?

    /// Service information associated with this user

    public var service: Service?

    /// Messaging protocols which this user supports

    public var supportedProtocols: Set<MessageProtocol>?

    /// The user's legalhold status

    public var legalholdStatus: LegalholdStatus

}

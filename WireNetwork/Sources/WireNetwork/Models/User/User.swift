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

/// User profile for a user

public struct User: Equatable, Sendable {

    /// The unique id of the user

    public let id: UserID

    /// The user's full name

    public let name: String

    /// The users's unique handle

    public let handle: String?

    /// Team ID if the user belongs to a team

    public let teamID: UUID?

    /// The type of a user: regular, app or bot.
    ///
    /// - returns: One of the three values `regular`, `app` or `bot` if talking to an API of version 12 or later, `nil`
    /// otherwise.

    public let type: UserType?

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

    public init(
        id: UserID,
        name: String,
        handle: String?,
        teamID: UUID?,
        type: UserType?,
        accentID: Int,
        assets: [UserAsset],
        deleted: Bool?,
        email: String?,
        expiresAt: Date?,
        service: Service?,
        supportedProtocols: Set<MessageProtocol>?,
        legalholdStatus: LegalholdStatus
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.teamID = teamID
        self.type = type
        self.accentID = accentID
        self.assets = assets
        self.deleted = deleted
        self.email = email
        self.expiresAt = expiresAt
        self.service = service
        self.supportedProtocols = supportedProtocols
        self.legalholdStatus = legalholdStatus
    }

}

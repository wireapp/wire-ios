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

/// Register User response

public struct RegisterUserResponse: Equatable, Sendable {

    /// The unique id of the user

    public let id: String

    /// The qualified id of the user

    public let qualifiedID: UserID

    /// The user's full name

    public let name: String

    /// Team ID if the user belongs to a team

    public let teamID: UUID?

    /// Color accent of the user

    public let accentID: Int

    /// The user identity managing system
    ///
    public let managedBy: ManagingSystem?

    /// The user's profile image assets

    public let assets: [UserAsset]?

    // Removed picture from parsing - WPB-20534

    /// The email associated with this user

    public let email: String?

    /// Status of registered user

    public let status: String?

    /// Messaging protocols which this user supports

    public let supportedProtocols: Set<MessageProtocol>?

}

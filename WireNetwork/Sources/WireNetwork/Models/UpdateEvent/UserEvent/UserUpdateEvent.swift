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

/// An event where a user's metadata was updated.

public struct UserUpdateEvent: Equatable, Sendable {

    /// The updated user's id.

    public let userID: UUID

    /// The new accent color id.

    public let accentColorID: Int?

    /// The new user name.

    public let name: String?

    /// The new user handle.

    public let handle: String?

    /// The new email address.

    public let email: String?

    /// Whether the user's sso id was deleted.

    public let isSSOIDDeleted: Bool?

    /// The new user assets.

    public let assets: [UserAsset]?

    /// The new supported protocols.

    public let supportedProtocols: Set<MessageProtocol>?

    /// The new text status.

    public let textStatus: String?

    /// Whether `text_status` key was present in the event payload.
    /// `true` means the field was explicitly sent (even if empty/null) and should be applied.
    /// `false` means the field was absent and the local value should be left unchanged.

    public let isTextStatusPresent: Bool

    public init(
        userID: UUID,
        accentColorID: Int?,
        name: String?,
        handle: String?,
        email: String?,
        isSSOIDDeleted: Bool?,
        assets: [UserAsset]?,
        supportedProtocols: Set<MessageProtocol>?,
        textStatus: String? = nil,
        isTextStatusPresent: Bool = false
    ) {
        self.userID = userID
        self.accentColorID = accentColorID
        self.name = name
        self.handle = handle
        self.email = email
        self.isSSOIDDeleted = isSSOIDDeleted
        self.assets = assets
        self.supportedProtocols = supportedProtocols
        self.textStatus = textStatus
        self.isTextStatusPresent = isTextStatusPresent
    }

}

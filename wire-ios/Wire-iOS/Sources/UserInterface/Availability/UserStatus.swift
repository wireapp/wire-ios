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

import WireDataModel

/// The status of the user, consisting of its name and availability.
public struct UserStatus {

    public var avatar: Avatar

    public var handle: String

    /// The name of the users.
    public var name: String

    public var availability: Availability

    /// `true` if the user has a valid certificate (MLS), `false` otherwise.
    public var isCertified: Bool

    /// `true` if the user has been verified (Proteus), `false` otherwise.
    public var isVerified: Bool

    public init(
        avatar: Avatar = .text(""),
        handle: String = "",
        name: String = "",
        availability: Availability = Availability.none,
        isCertified: Bool = false,
        isVerified: Bool = false
    ) {
        self.avatar = avatar
        self.handle = handle
        self.name = name
        self.availability = availability
        self.isCertified = isCertified
        self.isVerified = isVerified
    }

    // MARK: - Avatar

    /// The different, mutually-exclusive forms of avatars.
    public enum Avatar: Equatable {

        case image(UIImage)
        case text(String)

        public init() {
            self = .image(resource: .unavailableUser)
        }

        static func image(resource: ImageResource) -> Self {
            .image(.init(resource: resource))
        }
    }
}

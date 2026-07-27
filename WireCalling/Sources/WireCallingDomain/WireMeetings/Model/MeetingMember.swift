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
public import WireFoundation

public struct MeetingMember: Sendable {

    public let qualifiedID: QualifiedID
    public let name: String
    public let handle: String

    /// The member's initials, used as an avatar fallback when no image is available.
    public let initials: String

    /// The member's accent color, used as the background behind the initials.
    public let accentColor: WireAccentColor

    /// The member's profile image data, if available; when `nil` the initials are shown instead.
    public let avatarImageData: Data?

    public init(
        qualifiedID: QualifiedID,
        name: String,
        handle: String,
        initials: String = "",
        accentColor: WireAccentColor = .default,
        avatarImageData: Data? = nil
    ) {
        self.qualifiedID = qualifiedID
        self.name = name
        self.handle = handle
        self.initials = initials
        self.accentColor = accentColor
        self.avatarImageData = avatarImageData
    }

}

// MARK: - Hashable

extension MeetingMember: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(qualifiedID)
    }

    public static func == (lhs: MeetingMember, rhs: MeetingMember) -> Bool {
        lhs.qualifiedID == rhs.qualifiedID
    }

}

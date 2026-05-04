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

/// An event where a team was created.

public struct TeamCreateEvent: Equatable, Sendable {

    /// The team id.

    public let identifier: UUID

    /// The team name.

    public let name: String

    /// The team creator id.

    public let creator: UUID

    /// The team icon.

    public let icon: String

    /// The team icon key.

    public let iconKey: String?

    /// The team splash screen.

    public let splashScreen: String?

    public init(
        identifier: UUID,
        name: String,
        creator: UUID,
        icon: String,
        iconKey: String?,
        splashScreen: String?
    ) {
        self.identifier = identifier
        self.name = name
        self.creator = creator
        self.icon = icon
        self.iconKey = iconKey
        self.splashScreen = splashScreen
    }

}

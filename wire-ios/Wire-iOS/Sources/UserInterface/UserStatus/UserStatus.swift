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

/// The status of the user, consisting of its name,
/// handle, availability and verification status.
struct UserStatus {
    // MARK: Lifecycle

    init(
        name: String,
        availability: Availability,
        isE2EICertified: Bool,
        isProteusVerified: Bool
    ) {
        self.name = name
        self.availability = availability
        self.isE2EICertified = isE2EICertified
        self.isProteusVerified = isProteusVerified
    }

    init() {}

    // MARK: Internal

    var name = ""

    var availability = Availability.none

    // TODO: [WPB-6770]: (tech dept) consider adding `UserLegalHoldStatus`

    /// `true` if the user has a valid certificate (MLS), `false` otherwise.
    var isE2EICertified = false

    /// `true` if the user has been verified (Proteus), `false` otherwise.
    var isProteusVerified = false
}

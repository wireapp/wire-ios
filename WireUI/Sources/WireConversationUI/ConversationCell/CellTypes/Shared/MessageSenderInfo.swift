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

import WireAccountImageUI
import WireFoundation

/// Combines the info about the sender of a message, both for the image and the text.
public // TODO: public?
struct MessageSenderInfo: Hashable, Sendable {

    var accountImageSource: AccountImageSource
    var availability: Availability?

    /// If `nil` only the account image of a message is visible.
    var details: Details?

    init() {
        self.accountImageSource = .text("")
    }

    /// The info for the sender's name to be visible next to the account image.
    struct Details: Hashable, Sendable {
        var name: String
        var accentColor: WireAccentColor
        var isGuest: Bool
    }

}

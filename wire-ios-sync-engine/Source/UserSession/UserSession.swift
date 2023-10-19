//
// Wire
// Copyright (C) 2023 Wire Swiss GmbH
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

/// An abstraction of the user session for use in the presentation
/// layer.

public protocol UserSession {

    /// Whether the session needs to be unlocked by the user
    /// via passcode or biometric authentication.

    var isLocked: Bool { get }

    /// The user who is logged into this session.
    ///
    /// This can only be used on the main thread.

    var selfUser: ZMUser { get }

}

extension ZMUserSession: UserSession {

    public var isLocked: Bool {
        return isDatabaseLocked || appLockController.isLocked
    }

    public var selfUser: ZMUser {
        return ZMUser.selfUser(inUserSession: self)
    }

}

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

import Foundation

/// An event concerning users.

public enum UserEvent: Equatable {

    /// The self user has added a new client.

    case clientAdd(UserClientAddEvent)

    /// A self user's client was removed.

    case clientRemove(UserClientRemoveEvent)

    /// A connection to another user has been updated.

    case connection(UserConnectionEvent)

    /// A contact has joined Wire.

    case contactJoin(UserContactJoinEvent)

    /// A user was deleted.

    case delete(UserDeleteEvent)

    /// Legalhold was disabled for a user.

    case legalholdDisable(UserLegalholdDisableEvent)

    /// Legalhold was enabled for a user.

    case legalholdEnable(UserLegalholdEnableEvent)

    /// Legalhold has been requested for a user.

    case legalholdRequest

    /// One of the self user's persisted properties was set.

    case propertiesSet

    /// One of the self user's persisted properties was deleted.

    case propertiesDelete

    /// One of the self user's push tokens was removed.

    case pushRemove

    /// A user's metadata was updated.

    case update

}

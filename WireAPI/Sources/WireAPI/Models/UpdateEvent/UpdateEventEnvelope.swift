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

/// A container for update events.

public struct UpdateEventEnvelope: Equatable {

    /// The id of the event.

    public let id: UUID

    /// The event payloads.

    public let payloads: [UpdateEvent]

    /// Whether this event is transient.
    ///
    /// If `true`, then the event is not stored on the backend and is
    /// only sent through the push channel as it occurs.

    public let isTransient: Bool

}

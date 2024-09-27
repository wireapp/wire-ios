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

import WireAPI

// MARK: - UserLegalholdRequestEventProcessorProtocol

/// Process user legalhold request events.

protocol UserLegalholdRequestEventProcessorProtocol {
    /// Process a user legalhold request event.
    ///
    /// - Parameter event: A user legalhold request event.

    func processEvent(_ event: UserLegalholdRequestEvent) async throws
}

// MARK: - UserLegalholdRequestEventProcessor

struct UserLegalholdRequestEventProcessor: UserLegalholdRequestEventProcessorProtocol {
    func processEvent(_: UserLegalholdRequestEvent) async throws {
        // TODO: [WPB-10196]
        assertionFailure("not implemented yet")
    }
}

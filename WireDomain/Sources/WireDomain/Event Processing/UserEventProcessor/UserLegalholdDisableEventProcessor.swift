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

/// Process user legalhold disable events.

protocol UserLegalholdDisableEventProcessorProtocol {

    /// Process a user legalhold disable event.
    ///
    /// - Parameter event: A user legalhold disable event.

    func processEvent(_ event: UserLegalholdDisableEvent) async throws

}

struct UserLegalholdDisableEventProcessor: UserLegalholdDisableEventProcessorProtocol {

    let repository: any UserRepositoryProtocol

    func processEvent(_: UserLegalholdDisableEvent) async throws {
        try await repository.disableUserLegalHold()
    }

}

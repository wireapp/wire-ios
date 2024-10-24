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
import WireDataModel

/// Process team member leave events.
///
protocol TeamMemberLeaveEventProcessorProtocol {

    /// Process a team member leave event.
    ///
    /// - Parameter event: A team member leave event.

    func processEvent(_ event: TeamMemberLeaveEvent) async throws

}

struct TeamMemberLeaveEventProcessor: TeamMemberLeaveEventProcessorProtocol {

    let repository: any TeamRepositoryProtocol

    func processEvent(_ event: TeamMemberLeaveEvent) async throws {
        try await repository.deleteMembership(
            for: event.userID,
            domain: nil,
            at: event.time
        )
    }

}

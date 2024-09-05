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
import WireAPI

/// Process team update events.

protocol TeamEventProcessorProtocol {

    /// Process a team update event.
    ///
    /// Processing an event is the app's only chance to consume
    /// some remote changes to update its local state.
    ///
    /// - Parameter event: A team update event.

    func processEvent(_ event: TeamEvent) async throws

}

struct TeamEventProcessor {

    let deleteEventProcessor: any TeamDeleteEventProcessorProtocol
    let memberLeaveEventProcessor: any TeamMemberLeaveEventProcessorProtocol
    let memberUpdateEventProcessor: any TeamMemberUpdateEventProcessorProtocol

    func processEvent(_ event: TeamEvent) async throws {
        switch event {
        case .delete:
            try await deleteEventProcessor.processEvent()

        case .memberLeave(let event):
            try await memberLeaveEventProcessor.processEvent(event)

        case .memberUpdate(let event):
            try await memberUpdateEventProcessor.processEvent(event)
        }
    }

}

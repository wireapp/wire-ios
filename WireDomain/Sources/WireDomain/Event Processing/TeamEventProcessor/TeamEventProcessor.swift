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

import Foundation
import WireNetwork

struct TeamEventProcessor: TeamEventProcessorProtocol {

    let deleteEventProcessor: any TeamDeleteEventProcessorProtocol
    let memberLeaveEventProcessor: any TeamMemberLeaveEventProcessorProtocol
    let memberUpdateEventProcessor: any TeamMemberUpdateEventProcessorProtocol
    let createEventProcessor: any TeamCreateEventProcessorProtocol

    func processEvent(_ event: TeamEvent) async throws {
        switch event {
        case .delete:
            await deleteEventProcessor.processEvent()

        case let .memberLeave(event):
            try await memberLeaveEventProcessor.processEvent(event)

        case let .memberUpdate(event):
            try await memberUpdateEventProcessor.processEvent(event)

        case let .create(event):
            await createEventProcessor.processEvent(event)
        }
    }

}

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

import Foundation

/// A scheduler that dequeues tickets in priority order.

final class PriorityOrderWorkScheduler: WorkScheduler {

    private var blockerQueue: [any WorkTicket] = []
    private var highQueue: [any WorkTicket] = []
    private var mediumQueue: [any WorkTicket] = []
    private var lowQueue: [any WorkTicket] = []

    func enqueueTicket(_ ticket: any WorkTicket) {
        switch ticket.priority {
        case .low:
            lowQueue.append(ticket)
        case .medium:
            mediumQueue.append(ticket)
        case .high:
            highQueue.append(ticket)
        case .blocker:
            blockerQueue.append(ticket)
        }
    }

    func dequeueNextTicket() -> (any WorkTicket)? {
        if !blockerQueue.isEmpty {
            blockerQueue.removeFirst()
        } else if !highQueue.isEmpty {
            highQueue.removeFirst()
        } else if !mediumQueue.isEmpty {
            mediumQueue.removeFirst()
        } else if !lowQueue.isEmpty {
            lowQueue.removeFirst()
        } else {
            nil
        }
    }

}

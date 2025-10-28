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

final class ThreeTierWorkScheduler: WorkScheduler {

    private var queue0: [any WorkTicket] = []
    private var queue1: [any WorkTicket] = []
    private var queue2: [any WorkTicket] = []

    func enqueueTicket(_ ticket: any WorkTicket) {
        switch ticket.priority {
        case .critical, .blocker:
            queue0.append(ticket)
        case .high, .medium:
            queue1.append(ticket)
        case .low:
            queue2.append(ticket)
        }
    }

    func dequeueNextTicket() -> (any WorkTicket)? {
        if !queue0.isEmpty {
            queue0.removeFirst()
        } else if !queue1.isEmpty {
            queue1.removeFirst()
        } else if !queue2.isEmpty {
            queue2.removeFirst()
        } else {
            nil
        }
    }

}

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

/// A scheduler that dequeues items in priority order.

actor PriorityOrderWorkItemScheduler: WorkItemScheduler {

    private var blockerQueue: [any WorkItem] = []
    private var highQueue: [any WorkItem] = []
    private var mediumQueue: [any WorkItem] = []
    private var lowQueue: [any WorkItem] = []

    func enqueueItem(_ item: any WorkItem) async {
        switch item.priority {
        case .low:
            lowQueue.append(item)
        case .medium:
            mediumQueue.append(item)
        case .high:
            highQueue.append(item)
        case .blocker:
            blockerQueue.append(item)
        }
    }

    func dequeueNextItem() async -> (any WorkItem)? {
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

    func clearAllItems() async {
        blockerQueue.removeAll()
        highQueue.removeAll()
        mediumQueue.removeAll()
        lowQueue.removeAll()
    }
}

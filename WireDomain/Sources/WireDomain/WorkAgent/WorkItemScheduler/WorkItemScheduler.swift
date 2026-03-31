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

/// A component responsible for managing and ordering pending work items.
///
/// The `WorkItemScheduler` acts as the central queue for the app’s internal
/// work management system. It accepts items and determines the order in
/// which they should be executed based on their assigned priority and
/// other scheduling policies.

protocol WorkItemScheduler: Sendable {

    /// Add an item to the scheduler.
    ///
    /// - Parameter item: The item to enqueue.

    func enqueueItem(_ item: any WorkItem) async

    /// Retrieves and removes the next item to be performed.
    ///
    /// - Returns: The next available item.

    func dequeueNextItem() async -> (any WorkItem)?

    /// Clears all items from queues

    func clearAllItems() async
}

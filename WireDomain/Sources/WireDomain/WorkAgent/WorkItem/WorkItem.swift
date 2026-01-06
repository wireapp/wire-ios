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

/// An item of work that can be performed.
///
/// A `Workitem` is a pending operation that can be performed when instructed
/// to. Instances are created and scheduled via the `WorkAgent`.

protocol WorkItem: Sendable {

    /// A unique identifier for this item.

    var id: UUID { get }

    /// The urgency or importance of this ticket.

    var priority: WorkItemPriority { get }

    /// Start the work for this item.

    func start() async throws
}

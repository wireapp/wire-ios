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

/// A request describing a unit of work to be performed by the work scheduler.
///
/// A `WorkTicket` encapsulates the essential metadata for a pending operation,
/// including its unique identifier, originating worker, and execution priority.
/// Conforming types should include additional information necessary for its
/// worker to perform the work it represents.
///
/// Tickets are typically created by a `Worker` and then submitted to a
/// `WorkAgent`, which is responsible for scheduling and informing the worker
/// when they can perform the ticket.

protocol WorkTicket: Sendable {

    /// A unique identifier for this ticket.

    var id: UUID { get }

    /// The identifier of the worker that created this ticket.

    var workerID: UUID { get }

    /// The urgency or importance of this ticket.

    var priority: WorkTicketPriority { get }

}

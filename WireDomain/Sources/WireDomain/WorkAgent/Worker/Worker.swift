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

/// Represents a component responsible for performing units of work.
///
/// A `Worker` produces a `Ticket` for each unit of work it needs to
/// perform and submits it to the `WorkAgent`. The agent will inform
/// the worker when it can perform the work. The worker is responsible
/// for handling `Task` cancellation and throwing `WorkTicketRecoveryStrategy`
/// to inform the agent how to proceed in case of failure.

protocol Worker: Sendable {

    /// The type of ticket this worker can handle.

    associatedtype Ticket: WorkTicket

    /// A unique identifier for this worker.

    var id: UUID { get }

    /// Performs the work described by a ticket.
    ///
    /// This method can be invoked with any ticket but will be rejected
    /// if it is incompatible with the worker, which would be a developer
    /// error
    ///
    /// - Parameter ticket: The ticket describing the work to perform.
    /// - Throws: `WorkTicketRecoveryStrategy.drop` if the ticket is incompatible.

    func performWork(for ticket: any WorkTicket) async throws

    /// Performs the work described by a ticket.
    ///
    /// - Parameter ticket: The ticket describing the work to perform.
    /// - Throws: `WorkTicketRecoveryStrategy`.

    func performWork(for ticket: Ticket) async throws

}

extension Worker {

    func performWork(for ticket: any WorkTicket) async throws {
        guard let ticket = ticket as? Ticket else {
            throw WorkTicketRecoveryStrategy.drop
        }

        try await performWork(for: ticket)
    }

}

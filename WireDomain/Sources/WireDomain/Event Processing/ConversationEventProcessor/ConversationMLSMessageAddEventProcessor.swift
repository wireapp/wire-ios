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

// MARK: - ConversationMLSMessageAddEventProcessorProtocol

/// Process conversation mls message add events.

protocol ConversationMLSMessageAddEventProcessorProtocol {
    /// Process a conversation mls message add event.
    ///
    /// - Parameter event: A conversation mls message add event.

    func processEvent(_ event: ConversationMLSMessageAddEvent) async throws
}

// MARK: - ConversationMLSMessageAddEventProcessor

struct ConversationMLSMessageAddEventProcessor: ConversationMLSMessageAddEventProcessorProtocol {
    func processEvent(_: ConversationMLSMessageAddEvent) async throws {
        // TODO: [WPB-10172]
        assertionFailure("not implemented yet")
    }
}

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

// MARK: - ConversationCodeUpdateEventProcessorProtocol

/// Process conversation code update events.

protocol ConversationCodeUpdateEventProcessorProtocol {
    /// Process a conversation code update event.
    ///
    /// - Parameter event: A conversation code update event.

    func processEvent(_ event: ConversationCodeUpdateEvent) async throws
}

// MARK: - ConversationCodeUpdateEventProcessor

struct ConversationCodeUpdateEventProcessor: ConversationCodeUpdateEventProcessorProtocol {
    func processEvent(_: ConversationCodeUpdateEvent) async throws {
        // TODO: [WPB-10165]
        assertionFailure("not implemented yet")
    }
}

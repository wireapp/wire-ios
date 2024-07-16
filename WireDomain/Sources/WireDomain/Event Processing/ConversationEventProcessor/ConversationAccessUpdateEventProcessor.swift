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

import Foundation
import WireAPI

/// Process conversation access update events.

protocol ConversationAccessUpdateEventProcessorProtocol {

    /// Process a conversation access update event.
    ///
    /// - Parameter event: A conversation access update event.

    func processEvent(_ event: ConversationAccessUpdateEvent) async throws

}

struct ConversationAccessUpdateEventProcessor: ConversationAccessUpdateEventProcessorProtocol {

    func processEvent(_ event: ConversationAccessUpdateEvent) async throws {
        // TODO: [WPB-10164]
        // Existing implementation is `WireRequestStrategy.ConversationEventProcessor`:
        // - fetch or create conversation.
        // - set the new access modes on the conversation.
        // - set the new access roles on the conversation.
        // - perhaps we can remove the legacy role from the payload.

        assertionFailure("not implemented yet")
    }

}

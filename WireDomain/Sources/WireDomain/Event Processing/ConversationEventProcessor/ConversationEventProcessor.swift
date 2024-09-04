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

import CoreData
import WireAPI

/// Process conversation update events.
protocol ConversationEventProcessorProtocol {

    /// Process a conversation update event.
    ///
    /// Processing an event is the app's only chance to consume
    /// some remote changes to update its local state.

    func processConversationEvent() async throws

}

struct ConversationEventProcessor: CategorizedEventProcessorProtocol {

    private let builder: any ConversationEventProcessorBuilder = EventProcessorBuilder()
    let event: ConversationEvent
    let context: NSManagedObjectContext

    func processCategorizedEvent() async throws {
        let processor = builder.makeConversationProcessor(
            for: event,
            context: context
        )

        try await processor.processConversationEvent()
    }

}

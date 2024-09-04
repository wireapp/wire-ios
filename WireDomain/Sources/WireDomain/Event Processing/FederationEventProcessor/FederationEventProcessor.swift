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
import Foundation
import WireAPI

/// Process federation update events.
protocol FederationEventProcessorProtocol {

    /// Process a federation update event.
    ///
    /// Processing an event is the app's only chance to consume
    /// some remote changes to update its local state.
    ///
    func processFederationEvent() async throws

}

struct FederationEventProcessor: CategorizedEventProcessorProtocol {

    private let builder: any FederationEventProcessorBuilder = EventProcessorBuilder()
    let event: FederationEvent
    let context: NSManagedObjectContext

    func processCategorizedEvent() async throws {
        let processor = builder.makeFederationProcessor(
            for: event,
            context: context
        )

        try await processor.processFederationEvent()
    }

}

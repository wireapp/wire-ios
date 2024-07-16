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

/// Process federation update events.

protocol FederationEventProcessorProtocol {

    /// Process a federation update event.
    ///
    /// Processing an event is the app's only chance to consume
    /// some remote changes to update its local state.
    ///
    /// - Parameter event: A federation update event.

    func processEvent(_ event: FederationEvent) async throws

}

struct FederationEventProcessor {

    let connectionRemovedEventProcessor: any FederationConnectionRemovedEventProcessorProtocol
    let deleteEventProcessor: any FederationDeleteEventProcessorProtocol

    func processEvent(_ event: FederationEvent) async throws {
        switch event {
        case .connectionRemoved(let event):
            try await connectionRemovedEventProcessor.processEvent(event)

        case .delete(let event):
            try await deleteEventProcessor.processEvent(event)
        }
    }

}

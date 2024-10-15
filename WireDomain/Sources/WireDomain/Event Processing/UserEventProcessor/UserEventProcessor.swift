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

/// Process user update events.

protocol UserEventProcessorProtocol {

    /// Process a user update event.
    ///
    /// Processing an event is the app's only chance to consume
    /// some remote changes to update its local state.
    ///
    /// - Parameter event: A user update event.

    func processEvent(_ event: UserEvent) async throws

}

struct UserEventProcessor {

    let clientAddEventProcessor: any UserClientAddEventProcessorProtocol
    let clientRemoveEventProcessor: any UserClientRemoveEventProcessorProtocol
    let connectionEventProcessor: any UserConnectionEventProcessorProtocol
    let deleteEventProcessor: any UserDeleteEventProcessorProtocol
    let legalholdDisableEventProcessor: any UserLegalholdDisableEventProcessorProtocol
    let legalholdEnableEventProcessor: any UserLegalholdEnableEventProcessorProtocol
    let legalholdRequestEventProcessor: any UserLegalholdRequestEventProcessorProtocol
    let propertiesSetEventProcessor: any UserPropertiesSetEventProcessorProtocol
    let propertiesDeleteEventProcessor: any UserPropertiesDeleteEventProcessorProtocol
    let pushRemoveEventProcessor: any UserPushRemoveEventProcessorProtocol
    let updateEventProcessor: any UserUpdateEventProcessorProtocol

    func processEvent(_ event: UserEvent) async throws {
        switch event {
        case .clientAdd(let event):
            try await clientAddEventProcessor.processEvent(event)

        case .clientRemove(let event):
            try await clientRemoveEventProcessor.processEvent(event)

        case .connection(let event):
            try await connectionEventProcessor.processEvent(event)

        case .contactJoin(let event):
            /// This event is not processed, we only show a notification to the user.
            break

        case .delete(let event):
            try await deleteEventProcessor.processEvent(event)

        case .legalholdDisable(let event):
            try await legalholdDisableEventProcessor.processEvent(event)

        case .legalholdEnable(let event):
            try await legalholdEnableEventProcessor.processEvent(event)

        case .legalholdRequest(let event):
            try await legalholdRequestEventProcessor.processEvent(event)

        case .propertiesSet(let event):
            try await propertiesSetEventProcessor.processEvent(event)

        case .propertiesDelete(let event):
            try await propertiesDeleteEventProcessor.processEvent(event)

        case .pushRemove:
            pushRemoveEventProcessor.processEvent()

        case .update(let event):
            try await updateEventProcessor.processEvent(event)
        }
    }

}

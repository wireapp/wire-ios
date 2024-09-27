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

// MARK: - UserEventProcessorProtocol

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

// MARK: - UserEventProcessor

struct UserEventProcessor {
    let clientAddEventProcessor: any UserClientAddEventProcessorProtocol
    let clientRemoveEventProcessor: any UserClientRemoveEventProcessorProtocol
    let connectionEventProcessor: any UserConnectionEventProcessorProtocol
    let contactJoinEventProcessor: any UserContactJoinEventProcessorProtocol
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
        case let .clientAdd(event):
            try await clientAddEventProcessor.processEvent(event)

        case let .clientRemove(event):
            try await clientRemoveEventProcessor.processEvent(event)

        case let .connection(event):
            try await connectionEventProcessor.processEvent(event)

        case let .contactJoin(event):
            try await contactJoinEventProcessor.processEvent(event)

        case let .delete(event):
            try await deleteEventProcessor.processEvent(event)

        case let .legalholdDisable(event):
            try await legalholdDisableEventProcessor.processEvent(event)

        case let .legalholdEnable(event):
            try await legalholdEnableEventProcessor.processEvent(event)

        case let .legalholdRequest(event):
            try await legalholdRequestEventProcessor.processEvent(event)

        case let .propertiesSet(event):
            try await propertiesSetEventProcessor.processEvent(event)

        case let .propertiesDelete(event):
            try await propertiesDeleteEventProcessor.processEvent(event)

        case .pushRemove:
            try await pushRemoveEventProcessor.processEvent()

        case let .update(event):
            try await updateEventProcessor.processEvent(event)
        }
    }
}

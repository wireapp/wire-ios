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

/// `ZMUserSession.init` needs to create an object which conforms to `UpdateEventProcessor`.
/// This protocol allows for providing it a mock factory for unit tests.
public protocol EventProcessorFactory {
    func create(
        storeProvider: CoreDataStack,
        eventProcessingTracker: EventProcessingTrackerProtocol,
        earService: EARServiceInterface,
        eventConsumers: [ZMEventConsumer],
        eventAsyncConsumers: [ZMEventAsyncConsumer]
    ) -> UpdateEventProcessor
}

extension EventProcessorFactory where Self == DefaultEventProcessorFactory {
    static var `default`: DefaultEventProcessorFactory { .init() }
}

struct DefaultEventProcessorFactory: EventProcessorFactory {

    func create(
        storeProvider: CoreDataStack,
        eventProcessingTracker: EventProcessingTrackerProtocol,
        earService: EARServiceInterface,
        eventConsumers: [ZMEventConsumer],
        eventAsyncConsumers: [ZMEventAsyncConsumer]
    ) -> UpdateEventProcessor {
        EventProcessor(
            storeProvider: storeProvider,
            eventProcessingTracker: eventProcessingTracker,
            earService: earService,
            eventConsumers: eventConsumers,
            eventAsyncConsumers: eventAsyncConsumers
        )
    }
}

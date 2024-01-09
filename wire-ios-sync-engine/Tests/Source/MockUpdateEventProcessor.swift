//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
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

@testable import WireSyncEngine

@objcMembers
public class MockUpdateEventProcessor: NSObject, UpdateEventProcessor {

    public var processedEvents: [ZMUpdateEvent] = []
    public var bufferedEvents: [ZMUpdateEvent] = []

    public func bufferEvents(_ events: [WireTransport.ZMUpdateEvent]) async {
        bufferedEvents.append(contentsOf: events)
    }

    public func processEvents(_ events: [WireTransport.ZMUpdateEvent]) async {
        processedEvents.append(contentsOf: events)
    }

    public func processBufferedEvents() async {
        processedEvents.append(contentsOf: bufferedEvents)
        bufferedEvents.removeAll()
    }
}

// MARK: EventProcessorFactory + mock

extension EventProcessorFactory where Self == MockEventProcessorFactory {
    static var mock: MockEventProcessorFactory { .init() }
}

struct MockEventProcessorFactory: EventProcessorFactory {

    func create(
        storeProvider _: CoreDataStack,
        eventProcessingTracker _: EventProcessingTrackerProtocol,
        earService _: EARServiceInterface,
        eventConsumers _: [ZMEventConsumer],
        eventAsyncConsumers _: [ZMEventAsyncConsumer]
    ) -> UpdateEventProcessor {
        MockUpdateEventProcessor()
    }
}

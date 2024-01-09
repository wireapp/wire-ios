//
// Wire
// Copyright (C) 2021 Wire Swiss GmbH
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

protocol NotifyUpdateEventProcessor: UpdateEventProcessor {
    func processEvents(_ events: [ZMUpdateEvent], shouldBuffer: Bool)
}

@objc
public protocol UpdateEventProcessor: AnyObject {

    /// Buffer events in-memory until the next call to `processBufferedEvents`
    ///
    /// - Parameters:
    ///     - events: events to buffer
    func bufferEvents(_ events: [ZMUpdateEvent]) async

    /// Decrypt, persist and process events
    ///
    /// - Parameters:
    ///     - events: events to process
    ///
    /// If encryption at rest is enabled and the application is not authenticated only
    /// calling events will be processed. The function returns when all events have
    /// finished processing.
    func processEvents(_ events: [ZMUpdateEvent]) async throws

    /// Forward any buffered events to `processEvents`
    func processBufferedEvents() async throws
}

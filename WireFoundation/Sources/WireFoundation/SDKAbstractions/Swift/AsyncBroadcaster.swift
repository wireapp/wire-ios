//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

/// Multicasts events to any number of `AsyncStream` observers.
///
/// `AsyncStream` itself supports only a single consumer, so each observer
/// gets its own stream and events are yielded to all active streams.
public final class AsyncBroadcaster<Element: Sendable>: @unchecked Sendable {

    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    public init() {}

    /// Returns a stream that emits on every `broadcast(_:)` until the
    /// consuming task is cancelled.
    public func makeStream() -> AsyncStream<Element> {
        AsyncStream { continuation in
            let id = UUID()
            lock.withLock { continuations[id] = continuation }
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                lock.withLock { _ = continuations.removeValue(forKey: id) }
            }
        }
    }

    public func broadcast(_ element: Element) {
        let active = lock.withLock { Array(continuations.values) }
        for continuation in active {
            continuation.yield(element)
        }
    }

}

extension AsyncBroadcaster where Element == Void {

    public func broadcast() {
        broadcast(())
    }

}

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
public final class AsyncMulticaster<Element: Sendable>: @unchecked Sendable {

    private let lock = NSLock()
    private var continuations: [UUID: AsyncStream<Element>.Continuation] = [:]

    public init() {}

    deinit {
        // A dropped continuation never finishes its stream (see SE-0406),
        // so observers would hang forever once the multicaster is gone.
        let active = lock.withLock { Array(continuations.values) }
        for continuation in active {
            continuation.finish()
        }
    }

    /// Returns a stream that emits on every `broadcast(_:)` until the
    /// consuming task is cancelled or the multicaster is deallocated.
    ///
    /// - Parameter bufferingPolicy: How elements are buffered for a slow
    ///   consumer. Use `.bufferingNewest(1)` for signal-like streams where
    ///   only the latest element matters.
    public func makeStream(
        bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<Element> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
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

public extension AsyncMulticaster where Element == Void {

    func broadcast() {
        broadcast(())
    }

}

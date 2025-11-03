//
// Wire
// Copyright (C) 2025 Wire Swiss GmbH
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
import WireFoundation
import WireLegacyLogging

/// PushChannel using new consumable notifications
public final class PushChannelV2: PushChannelV2Protocol {

    public enum Element: Equatable {
        case syncMarker(id: String, deliveryTag: UInt64)
        case events([UpdateEventEnvelope])
        case missedEvents
    }

    enum InternalElement: Equatable {
        case syncMarker(id: String, deliveryTag: UInt64)
        case event(UpdateEventEnvelope)
        case missedEvents
    }

    public typealias Stream = AsyncThrowingStream<Element, any Error>

    private let webSocket: any WebSocketProtocol
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var keepAliveTask: Task<Void, any Error>?
    private let keepAliveInterval: TimeInterval

    private var batchTask: Task<Void, any Error>?
    private let batchInterval: TimeInterval
    private let batchBuffer = BatchBuffer()

    let maxBatchEventsCount: Int

    private var batchSize: Int
    private var (stream, continuation) = AsyncThrowingStream<Element, any Error>.makeStream()

    /// Initialize PushChannel with Async Stream capabitilites
    /// - Parameters:
    ///   - webSocket: webSocket to use
    ///   - keepAliveInterval: interval for sending ping and keep webSocket open
    ///   - maxBatchEventsCount: maxBatchEventsCount number of events per batch. Minimum valid value is 1.
    ///   - batchDelay: timeInterval to wait for elements until batch is returned
    public init(
        webSocket: any WebSocketProtocol,
        keepAliveInterval: TimeInterval,
        maxBatchEventsCount: Int,
        batchDelay: TimeInterval
    ) {
        self.webSocket = webSocket
        self.keepAliveInterval = keepAliveInterval
        self.maxBatchEventsCount = max(maxBatchEventsCount, 1)
        self.batchSize = self.maxBatchEventsCount
        self.batchInterval = batchDelay
    }

    public func open() async throws -> AsyncThrowingStream<Element, any Error> {
        // We don't want to proceed if not necessary (in case we've
        // gone to the background)
        try Task.checkCancellation()

        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV2)

        let sourceStream = try await webSocket.open()

        Task { [weak self] in
            guard let self else { return }

            do {
                for try await message in sourceStream {

                    let result: PushChannelV2.InternalElement
                    do {
                        result = try receiveMessage(message)
                    } catch PushChannelError.receivedInvalidMessage {
                        WireLogger.pushChannel.warn(
                            "ignore invalid message, continue",
                            attributes: .pushChannelV2
                        )
                        continue
                    } catch {
                        throw error
                    }

                    switch result {
                    case let .event(event):
                        WireLogger.pushChannel.debug("event notification received", attributes: .pushChannelV2)
                        await batchBuffer.append(event)
                        if await batchBuffer.count() >= batchSize {
                            let drained = await batchBuffer.drain()
                            continuation.yield(.events(drained))
                            WireLogger.pushChannel
                                .debug(
                                    "reached batch of size '\(drained.count)' yield, batchSize '\(batchSize)'"
                                )
                        }

                    case .missedEvents:
                        WireLogger.pushChannel.debug("missedEvents notification received", attributes: .pushChannelV2)
                        continuation.yield(.missedEvents)

                    case let .syncMarker(id, deliveryTag):
                        WireLogger.pushChannel.debug(
                            "synchronization notification received",
                            attributes: .pushChannelV2
                        )
                        // we're uptodate, let's give any remaining batch if any
                        let drained = await batchBuffer.drain()
                        if !drained.isEmpty {
                            continuation.yield(.events(drained))
                            WireLogger.pushChannel
                                .debug(
                                    "syncMarker reached \(id) batch of size '\(drained.count)' yield"
                                )
                        }
                        continuation.yield(.syncMarker(id: id, deliveryTag: deliveryTag))
                    }

                }
                // just in case to handle left batch if haven't deal with everything when we go to background
                let drained = await batchBuffer.drain()
                if !drained.isEmpty {
                    continuation.yield(.events(drained))
                    WireLogger.pushChannel.debug("end batch of size '\(drained.count)' yield")
                }

            } catch {
                WireLogger.pushChannel.error("got error: \(error)", attributes: .pushChannelV2)
                continuation.finish(throwing: error)
                await close()
                return
            }
            continuation.finish()
        }

        // The server will drop the connection (possibly silently)
        // if the client doesn’t send a ping message every so often.
        setUpKeepAliveTask()

        // Every `batchInterval`, this task returns the batchBuffer content
        // even if it did not collect the batchSize
        setUpBatchTask()

        return stream
    }

    public func close() async {
        WireLogger.pushChannel.debug("closing push channel", attributes: .pushChannelV2)

        await webSocket.close()

        tearDownKeepAliveTask()
        tearDownBatchTask()

        if !(await batchBuffer.isEmpty()) {
            let drained = await batchBuffer.drain()
            WireLogger.pushChannel.debug(
                "closing, drain batch '\(drained.count)'",
                attributes: .pushChannelV2
            )
            continuation.yield(.events(drained))
        }
    }

    public func disableBatching(_ disabled: Bool) async {
        batchSize = disabled ? 1 : maxBatchEventsCount
        if disabled {
            tearDownBatchTask()
            if !(await batchBuffer.isEmpty()) {
                let drained = await batchBuffer.drain()
                WireLogger.pushChannel.debug(
                    "drain batch '\(drained.count)'",
                    attributes: .pushChannelV2
                )
                continuation.yield(.events(drained))
            }
        } else {
            setUpBatchTask()
        }
    }

    // MARK: - Batch task

    private func setUpBatchTask() {
        WireLogger.pushChannel.debug("batchTask setup", attributes: .pushChannelV2)
        tearDownBatchTask()
        batchTask = Task { [weak self] in
            guard let self else { return }
            do {
                while batchSize > 1 {
                    try await Task.sleep(for: .seconds(batchInterval))
                    if !(await batchBuffer.isEmpty()) {
                        let drained = await batchBuffer.drain()
                        WireLogger.pushChannel.debug(
                            "timeout yielding batch '\(drained.count)'",
                            attributes: .pushChannelV2
                        )
                        continuation.yield(.events(drained))
                    }
                }
            } catch {
                WireLogger.pushChannel.warn("batch task was cancelled", attributes: .pushChannelV2)
                tearDownBatchTask()
            }
        }
    }

    private func tearDownBatchTask() {
        guard let batchTask else { return }
        WireLogger.pushChannel.debug("tearing down batch task", attributes: .pushChannelV2)
        batchTask.cancel()
        self.batchTask = nil
    }

    // MARK: - Keep alive

    private func setUpKeepAliveTask() {
        tearDownKeepAliveTask()
        keepAliveTask = Task {  [weak self] in
            guard let self else { return }
            do {
                while true {
                    try Task.checkCancellation()
                    try await Task.sleep(for: .seconds(keepAliveInterval))
                    WireLogger.pushChannel.debug("sending keep alive ping", attributes: .pushChannelV2)
                    await webSocket.sendPing()
                }
            } catch {
                WireLogger.pushChannel.warn("keep alive task was cancelled", attributes: .pushChannelV2)
            }
        }
    }

    private func tearDownKeepAliveTask() {
        guard let keepAliveTask else { return }
        WireLogger.pushChannel.debug("tearing down keep alive task", attributes: .pushChannelV2)
        keepAliveTask.cancel()
        self.keepAliveTask = nil
    }

    // MARK: - Acknowledgement

    public func acknowledgeEvent(deliveryTag: UInt64, multiple: Bool = false) async throws {
        WireLogger.pushChannel.debug(
            "acknowledgeEvent \(deliveryTag)",
            attributes: .pushChannelV2, [.multipleEvents: multiple]
        )
        let acknowledgement = EventAcknowledgment(
            deliveryTag: deliveryTag,
            multiple: multiple
        )
        let data = try encoder.encode(acknowledgement)
        try await write(data: data)
    }

    public func acknowledgeFullSync() async throws {
        WireLogger.pushChannel.debug("acknowledgeFullSync", attributes: .pushChannelV2)
        let acknowledgement = FullSyncAcknowledgment()
        let data = try encoder.encode(acknowledgement)
        try await write(data: data)
    }

    // MARK: - Helpers

    private func receiveMessage(_ message: URLSessionWebSocketTask.Message) throws -> InternalElement {

        switch message {
        case let .data(data):
            WireLogger.pushChannel.debug(
                "received web socket data, decoding...",
                attributes: .pushChannelV2
            )
            let envelope = try decoder.decode(WebSocketNotification.self, from: data)

            switch envelope.type {
            case .event:
                if let element = envelope.updateEventEnveloppe {
                    return .event(element)
                } else {
                    WireLogger.pushChannel.debug(
                        "received web socket invalid data \(String(describing: data)), ignoring...",
                        attributes: .pushChannelV2
                    )
                    throw PushChannelError.receivedInvalidMessage
                }
            case .synchronization:
                if let data = envelope.synchronizationData {
                    return .syncMarker(id: data.markerId, deliveryTag: data.deliveryTag)
                } else {
                    throw PushChannelError.receivedInvalidMessage
                }
            case .notificationsMissed:
                return .missedEvents
            }

        case .string:
            WireLogger.pushChannel.debug(
                "received web socket string, ignoring...",
                attributes: .pushChannelV2
            )
            throw PushChannelError.receivedInvalidMessage

        @unknown default:
            WireLogger.pushChannel.debug(
                "received web socket message, ignoring...",
                attributes: .pushChannelV2
            )
            throw PushChannelError.receivedInvalidMessage
        }
    }

    private func write(data: Data) async throws {
        WireLogger.pushChannel.debug("write data to push channel", attributes: .pushChannelV2)
        try await webSocket.write(data: data)
    }
}

actor BatchBuffer {
    private var buffer: [UpdateEventEnvelope] = []

    func append(_ event: UpdateEventEnvelope) {
        buffer.append(event)
    }

    func isEmpty() -> Bool {
        buffer.isEmpty
    }

    func count() -> Int {
        buffer.count
    }

    func drain() -> [UpdateEventEnvelope] {
        defer { buffer.removeAll() }
        return buffer
    }
}

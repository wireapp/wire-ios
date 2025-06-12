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
import WireLogging

/// PushChannel using new async stream
public final class PushChannelV2: PushChannelV2Protocol {

    public enum Element: Equatable {
        case syncing(eventsCount: Int)
        case upToDate
        case event(UpdateEventEnvelope)
        case missedEvents
    }

    public typealias Stream = AsyncThrowingStream<Element, any Error>

    private let webSocket: any WebSocketProtocol
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    private var keepAliveTask: Task<Void, any Error>?
    private let keepAliveInterval: TimeInterval

    private var numberOfReceivedEvents = 0
    private var remainingEventCount: Int?

    private var (stream, continuation) = AsyncThrowingStream<Element, any Error>.makeStream()

    /// Initialize PushChannel with Async Stream capabitilites
    /// - Parameters:
    ///   - webSocket: webSocket to use
    ///   - keepAliveInterval: interval for sending ping and keep webSocket open
    public init(
        webSocket: any WebSocketProtocol,
        keepAliveInterval: TimeInterval
    ) {
        self.webSocket = webSocket
        self.keepAliveInterval = keepAliveInterval
    }

    public func open() async throws -> AsyncThrowingStream<Element, any Error> {
        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV2)

        let sourceStream = try await webSocket.open()

        Task { [weak self] in
            guard let self else { return }
            do {
                for try await message in sourceStream {

                    let result = try receiveMessage(message)

                    continuation.yield(result)
                    if numberOfReceivedEvents == remainingEventCount {
                        continuation.yield(.upToDate)
                    }
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

        return stream
    }

    public func close() async {
        WireLogger.pushChannel.debug("closing push channel", attributes: .pushChannelV2)

        await webSocket.close()
        tearDownKeepAliveTask()
    }

    // MARK: - Keep alive

    private func setUpKeepAliveTask() {
        tearDownKeepAliveTask()
        keepAliveTask = Task { [keepAliveInterval] in
            do {
                while true {
                    try await Task.sleep(for: .seconds(keepAliveInterval))
                    WireLogger.pushChannel.debug("sending keep alive ping", attributes: .pushChannelV2)
                    await webSocket.sendPing()
                }
            } catch {
                WireLogger.pushChannel.warn("keep alive task was cancelled", attributes: .pushChannelV2)
                tearDownKeepAliveTask()
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
        WireLogger.pushChannel.debug("acknowledgeEvent \(deliveryTag)", attributes: .pushChannelV2)
        let acknowledgement = EventAcknowledgment(
            deliveryTag: deliveryTag,
            multiple: multiple
        )
        let data = try JSONEncoder().encode(acknowledgement)
        try await write(data: data)
    }

    public func acknowledgeFullSync() async throws {
        WireLogger.pushChannel.debug("acknowledgeFullSync", attributes: .pushChannelV2)
        let acknowledgement = FullSyncAcknowledgment()
        let data = try encoder.encode(acknowledgement)
        try await write(data: data)
    }

    public func acknowledgeMessageCount() async throws {
        WireLogger.pushChannel.debug("acknowledgeMessageCount", attributes: .pushChannelV2)
        let acknowledgement = MessageCountAcknowledgment()
        let data = try encoder.encode(acknowledgement)
        try await write(data: data)
    }

    // MARK: - Helpers

    private func receiveMessage(_ message: URLSessionWebSocketTask.Message) throws -> Element {

        switch message {
        case let .data(data):
            WireLogger.pushChannel.debug("received web socket data, decoding...", attributes: .pushChannelV2)
            let envelope = try decoder.decode(WebSocketNotification.self, from: data)

            switch envelope.type {
            case .event:
                if let element = envelope.updateEventEnveloppe {
                    numberOfReceivedEvents += 1
                    return Element.event(element)
                } else {
                    WireLogger.pushChannel.debug(
                        "received web socket invalid data \(String(describing: data)), ignoring...",
                        attributes: .pushChannelV2
                    )
                    throw PushChannelError.receivedInvalidMessage
                }
            case .messagesCount:
                WireLogger.pushChannel.info(
                    "\(envelope.messageCount) until we're up to date",
                    attributes: .pushChannelV2
                )
                remainingEventCount = envelope.messageCount
                numberOfReceivedEvents = 0
                return .syncing(eventsCount: envelope.messageCount)
            case .notificationsMissed:
                return Element.missedEvents
            }

        case .string:
            WireLogger.pushChannel.debug("received web socket string, ignoring...", attributes: .pushChannelV2)
            throw PushChannelError.receivedInvalidMessage

        @unknown default:
            WireLogger.pushChannel.debug("received web socket message, ignoring...", attributes: .pushChannelV2)
            throw PushChannelError.receivedInvalidMessage
        }
    }

    private func write(data: Data) async throws {
        WireLogger.pushChannel.debug("write data to push channel", attributes: .pushChannelV2)
        try await webSocket.write(data: data)
    }
}

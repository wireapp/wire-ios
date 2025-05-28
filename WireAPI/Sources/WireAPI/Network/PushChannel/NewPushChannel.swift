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
public final class NewPushChannel: NewPushChannelProtocol {

    public enum Element: Equatable {
        case upToDate
        case event(UpdateEventEnvelope)
        case missedEvents
    }

    public typealias Stream = AsyncThrowingStream<Element, any Error>

    private let webSocket: any WebSocketProtocol
    private let decoder = JSONDecoder()

    private let timeout: TimeInterval
    private var timeoutTask: Task<Void, any Error>?

    private let channelState = ChannelState()

    private var keepAliveTask: Task<Void, any Error>?
    private let keepAliveInterval: TimeInterval

    private var (stream, continuation) = AsyncThrowingStream<Element, any Error>.makeStream()

    /// Initial PushChannel with Async Stream capabitilites
    /// - Parameters:
    ///   - webSocket: webSocket to use
    ///   - keepAliveInterval: interval for sending ping and keep webSocket open
    ///   - timeout: interval after we consider we're up to date with events
    public init(
        webSocket: any WebSocketProtocol,
        keepAliveInterval: TimeInterval = 5,
        timeout: TimeInterval = 1
    ) {
        self.webSocket = webSocket
        self.keepAliveInterval = keepAliveInterval
        self.timeout = timeout
    }

    deinit {
        timeoutTask?.cancel()
    }

    public func open() async throws -> AsyncThrowingStream<Element, any Error> {
        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV3)

        let sourceStream = try await webSocket.open()
        await channelState.websocketOpened()
        setupTimeoutTask()

        Task { [weak self] in
            guard let self else { return }
            do {
                for try await message in sourceStream {

                    let result = try await receiveMessage(message)
                    continuation.yield(result)

                    await channelState.stopProcessing()
                    setupTimeoutTask()
                }
            } catch {
                WireLogger.pushChannel.error("got error: \(error)", attributes: .pushChannelV3)
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
        WireLogger.pushChannel.debug("closing push channel", attributes: .pushChannelV3)

        await webSocket.close()
        tearDownTimeoutTask()
        tearDownKeepAliveTask()
    }

    func receiveMessage(_ message: URLSessionWebSocketTask.Message) async throws -> Element {
        timeoutTask?.cancel()
        await channelState.receivedMessage()
        await channelState.startProcessing()

        switch message {
        case let .data(data):
            WireLogger.pushChannel.debug(
                "received web socket data, decoding..., \(String(data: data, encoding: .utf8))",
                attributes: .pushChannelV3
            )
            let envelope = try decoder.decode(WebSocketNotification.self, from: data)
            if envelope.type == .event {
                return Element.event(envelope.toAPIModel())
            } else {
                return Element.missedEvents
            }

        case .string:
            WireLogger.pushChannel.debug("received web socket string, ignoring...", attributes: .pushChannelV3)
            throw PushChannelError.receivedInvalidMessage

        @unknown default:
            WireLogger.pushChannel.debug("received web socket message, ignoring...", attributes: .pushChannelV3)
            throw PushChannelError.receivedInvalidMessage
        }

    }

    // MARK: - Keep alive

    private func setUpKeepAliveTask() {
        tearDownKeepAliveTask()
        keepAliveTask = Task { [keepAliveInterval] in
            do {
                while true {
                    try await Task.sleep(for: .seconds(keepAliveInterval))
                    WireLogger.pushChannel.debug("sending keep alive ping")
                    await webSocket.sendPing()
                }
            } catch {
                WireLogger.pushChannel.warn("keep alive task was cancelled")
                tearDownKeepAliveTask()
            }
        }
    }

    private func tearDownKeepAliveTask() {
        guard let keepAliveTask else { return }
        WireLogger.pushChannel.debug("tearing down keep alive task")
        keepAliveTask.cancel()
        self.keepAliveTask = nil
    }

    // MARK: - Timeout

    private func setupTimeoutTask() {
        tearDownTimeoutTask()
        timeoutTask = Task { [timeout] in
            do {
                while true {
                    try Task.checkCancellation()
                    try await Task.sleep(nanoseconds: 100_000_000)
                    if await channelState.wait(timeout: timeout) {
                        if await channelState.catchingUp {
                            WireLogger.pushChannel.debug("caught up")
                            await channelState.caughtUp()
                            continuation.yield(.upToDate)
                            break
                        }
                    }
                }
            } catch {
                WireLogger.pushChannel.warn("timeoutTask was cancelled")
                tearDownTimeoutTask()
            }
        }
    }

    private func tearDownTimeoutTask() {
        guard let timeoutTask else { return }
        WireLogger.pushChannel.debug("tearing down timeoutTask")
        timeoutTask.cancel()
        self.timeoutTask = nil
    }

    // MARK: - Acknowledgement

    public func ackEvent(deliveryTag: UInt64, multiple: Bool = false) async throws {
        WireLogger.pushChannel.debug("ackEvent \(deliveryTag)", attributes: .pushChannelV3)
        let acknowledgement = EventAcknowledgmentNotification(
            deliveryTag: deliveryTag,
            multiple: multiple
        )
        let data = try JSONEncoder().encode(acknowledgement)
        try await write(data: data)
    }

    public func ackFullSync() async throws {
        WireLogger.pushChannel.debug("ackFullSync", attributes: .pushChannelV3)
        let acknowledgement = FullSyncAcknowledgmentNotification()
        let data = try JSONEncoder().encode(acknowledgement)
        try await write(data: data)
    }

    // MARK: - Helpers

    private func write(data: Data) async throws {
        WireLogger.pushChannel.debug("write data to push channel", attributes: .pushChannelV3)
        try await webSocket.write(data: data)
    }
}

private actor ChannelState {
    private var lastMessageUpdate = Date()
    var isProcessing = false
    var catchingUp = false

    func receivedMessage() {
        lastMessageUpdate = Date()
    }

    func websocketOpened() {
        catchingUp = true
    }

    func startProcessing() {
        isProcessing = true
    }

    func stopProcessing() {
        isProcessing = false
    }

    func timeSinceLastMessage() -> TimeInterval {
        Date().timeIntervalSince(lastMessageUpdate)
    }

    func caughtUp() {
        catchingUp = false
    }

    func wait(timeout: TimeInterval) -> Bool {
        timeSinceLastMessage() > timeout && !isProcessing
    }
}

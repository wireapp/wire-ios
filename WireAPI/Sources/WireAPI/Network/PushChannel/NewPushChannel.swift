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
    private let encoder = JSONEncoder()

    private let upToDateThreshold: TimeInterval
    private var upToDateTask: Task<Void, any Error>?

    private let channelState: ChannelState

    private var keepAliveTask: Task<Void, any Error>?
    private let keepAliveInterval: TimeInterval

    private var (stream, continuation) = AsyncThrowingStream<Element, any Error>.makeStream()

    /// Initialize PushChannel with Async Stream capabitilites
    /// - Parameters:
    ///   - webSocket: webSocket to use
    ///   - keepAliveInterval: interval for sending ping and keep webSocket open
    ///   - upToDateThreshold: interval after we consider we're up to date with events
    public init(
        webSocket: any WebSocketProtocol,
        keepAliveInterval: TimeInterval,
        upToDateThreshold: TimeInterval
    ) {
        self.webSocket = webSocket
        self.keepAliveInterval = keepAliveInterval
        self.upToDateThreshold = upToDateThreshold
        self.channelState = ChannelState(caughtUpTimeInterval: upToDateThreshold)
    }

    deinit {
        upToDateTask?.cancel()
    }

    public func open() async throws -> AsyncThrowingStream<Element, any Error> {
        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV3)

        let sourceStream = try await webSocket.open()
        await channelState.websocketOpened()
        setupUpToDateTask()

        Task { [weak self] in
            guard let self else { return }
            do {
                for try await message in sourceStream {

                    upToDateTask?.cancel()
                    await channelState.receivedMessage()

                    let result = try receiveMessage(message)
                    continuation.yield(result)

                    setupUpToDateTask()
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
        tearDownUpToDateTask()
        tearDownKeepAliveTask()
    }

    func receiveMessage(_ message: URLSessionWebSocketTask.Message) throws -> Element {

        switch message {
        case let .data(data):
            WireLogger.pushChannel.debug("received web socket data, decoding...", attributes: .pushChannelV3)
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
                    WireLogger.pushChannel.debug("sending keep alive ping", attributes: .pushChannelV3)
                    await webSocket.sendPing()
                }
            } catch {
                WireLogger.pushChannel.warn("keep alive task was cancelled", attributes: .pushChannelV3)
                tearDownKeepAliveTask()
            }
        }
    }

    private func tearDownKeepAliveTask() {
        guard let keepAliveTask else { return }
        WireLogger.pushChannel.debug("tearing down keep alive task", attributes: .pushChannelV3)
        keepAliveTask.cancel()
        self.keepAliveTask = nil
    }

    // MARK: - Timeout

    private func setupUpToDateTask() {
        tearDownUpToDateTask()
        upToDateTask = Task {
            do {
                try await Task.sleep(for: .seconds(channelState.timeUntilCaughtUp()))
                // we reach here when time between events is significant enough that we're up to date
                if await channelState.catchingUp {
                    WireLogger.pushChannel.debug("caught up", attributes: .pushChannelV3)
                    await channelState.caughtUp()
                    continuation.yield(.upToDate)
                }

            } catch {
                WireLogger.pushChannel.warn("upToDateTask was cancelled", attributes: .pushChannelV3)
                tearDownUpToDateTask()
            }
        }
    }

    private func tearDownUpToDateTask() {
        guard let upToDateTask else { return }
        WireLogger.pushChannel.debug("tearing down upToDateTask", attributes: .pushChannelV3)
        upToDateTask.cancel()
        self.upToDateTask = nil
    }

    // MARK: - Acknowledgement

    public func acknowledgeEvent(deliveryTag: UInt64, multiple: Bool = false) async throws {
        WireLogger.pushChannel.debug("acknowledgeEvent \(deliveryTag)", attributes: .pushChannelV3)
        let acknowledgement = EventAcknowledgment(
            deliveryTag: deliveryTag,
            multiple: multiple
        )
        let data = try JSONEncoder().encode(acknowledgement)
        try await write(data: data)
    }

    public func acknowledgeFullSync() async throws {
        WireLogger.pushChannel.debug("acknowledgeFullSync", attributes: .pushChannelV3)
        let acknowledgement = FullSyncAcknowledgment()
        let data = try encoder.encode(acknowledgement)
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
    var caughtUpTimeInterval: TimeInterval = 0.0

    init(
        lastMessageUpdate: Date = Date(),
        isProcessing: Bool = false,
        catchingUp: Bool = false,
        caughtUpTimeInterval: TimeInterval
    ) {
        self.lastMessageUpdate = lastMessageUpdate
        self.isProcessing = isProcessing
        self.catchingUp = catchingUp
        self.caughtUpTimeInterval = caughtUpTimeInterval
    }

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

    func timeUntilCaughtUp() -> TimeInterval {
        caughtUpTimeInterval + timeSinceLastMessage()
    }
    func caughtUp() {
        catchingUp = false
    }

    func isCaughtUp() -> Bool {
        timeSinceLastMessage() > caughtUpTimeInterval && !isProcessing && catchingUp
    }
}

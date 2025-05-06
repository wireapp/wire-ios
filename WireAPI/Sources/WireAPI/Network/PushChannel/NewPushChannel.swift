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

public final class NewPushChannel: NewPushChannelProtocol {

    public enum Element {
        case upToDate
        case event(UpdateEventEnvelope)
    }
    
    public typealias Stream = AsyncThrowingStream<Element, any Error>
    
    private let webSocket: any WebSocketProtocol
    private let decoder = JSONDecoder()
    private let timeout: TimeInterval = 5
    
    public init(webSocket: any WebSocketProtocol) {
        self.webSocket = webSocket
    }
    
    public func open() async throws -> AsyncThrowingStream<Element, any Error> {
        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV3)

        let mappedSequence = try await webSocket.open().map { [decoder] message in
            switch message {
            case let .data(data):
                WireLogger.pushChannel.debug("received web socket data, decoding..., \(String(data: data, encoding: .utf8))", attributes: .pushChannelV3)
                let envelope = try decoder.decode(WebSocketNotification.self, from: data)
                if envelope.type == .event {
                    return envelope.toAPIModel()
                } else {
                    throw PushChannelError.missingEvents
                }
            case .string:
                WireLogger.pushChannel.debug("received web socket string, ignoring...", attributes: .pushChannelV3)
                throw PushChannelError.receivedInvalidMessage

            @unknown default:
                WireLogger.pushChannel.debug("received web socket message, ignoring...", attributes: .pushChannelV3)
                throw PushChannelError.receivedInvalidMessage
            }
        }

        // Materialize the mapped sequence into a stream first
        let baseStream = AsyncThrowingStream<NewPushChannel.Element, any Error> { continuation in
            Task { [weak self] in
                do {
                    for try await element in mappedSequence {
                        let result = continuation.yield(.event(element))
                        WireLogger.pushChannel.debug("Yield result: \(result)", attributes: .pushChannelV3)

                    }
                    WireLogger.pushChannel.debug("finished sequence", attributes: .pushChannelV3)
                    continuation.finish()
                    
                } catch {
                    WireLogger.pushChannel.debug("failed to get next web socket message: \(error)", attributes: .pushChannelV3)
                    continuation.finish(throwing: error)
                    await self?.close()
                }
            }
        }

        return withIdleTimeout(baseStream, timeout: timeout, onTimeout: { continuation in
            WireLogger.pushChannel.debug("idle timeout occurred, we're up to date", attributes: .pushChannelV3)
           let result = continuation.yield(.upToDate)
            WireLogger.pushChannel.debug("Yield result: \(result)", attributes: .pushChannelV3)
        })
    }
    
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
    
    public func close() async {
        WireLogger.pushChannel.debug("closing push channel", attributes: .pushChannelV3)
        await webSocket.close()
    }
    
    // MARK: - Helpers
    
    private func write(data: Data) async throws {
        WireLogger.pushChannel.debug("write data to push channel", attributes: .pushChannelV3)
        try await webSocket.write(data: data)
    }
}

actor LastMessageTracker {
    private var timestamp = Date()

    func update() {
        timestamp = Date()
    }

    func timeSinceLastMessage() -> TimeInterval {
        Date().timeIntervalSince(timestamp)
    }
}


/// Wraps any `AsyncSequence` with idle timeout enforcement.
private func withIdleTimeout<S: AsyncSequence>(
    _ sequence: S,
    timeout: TimeInterval,
    onTimeout: @escaping (_ continuation: AsyncThrowingStream<S.Element, any Error>.Continuation) -> Void
) -> AsyncThrowingStream<S.Element, any Error> {
    AsyncThrowingStream { continuation  in
        let lastMessageTime = LastMessageTracker()

        // Processing task
        let processingTask = Task {
            do {
                for try await value in sequence {
                    await lastMessageTime.update()
                    continuation.yield(value)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }

        // Watchdog task
        let watchdogTask = Task {
            do {
                while !Task.isCancelled {
                    try await Task.sleep(nanoseconds: 1_000_000_000)

                    let elapsed = await lastMessageTime.timeSinceLastMessage()
                    if elapsed > timeout {
                        processingTask.cancel()
                        onTimeout(continuation)
                        break
                    }
                }
            } catch {
                // Cancelled = normal
            }
        }

        continuation.onTermination = { _ in
            processingTask.cancel()
            watchdogTask.cancel()
        }
    }
}

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
    private var timeoutTimer: Timer?
    
    public init(webSocket: any WebSocketProtocol) {
        self.webSocket = webSocket
    }
        
    public func open() async throws -> AsyncThrowingStream<Element, any Error> {
        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV3)

        let mapped = try await webSocket.open().map { [decoder] message in
            switch message {
            case let .data(data):
                WireLogger.pushChannel.debug("received web socket data, decoding..., \(String(data: data, encoding: .utf8))", attributes: .pushChannelV3)
                let envelope = try decoder.decode(WebSocketNotification.self, from: data)
                if envelope.type == .event {
                    return Element.event(envelope.toAPIModel())
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

        let stream = mapped.toStream()
        var iterator = stream.makeAsyncIterator()

        return AsyncThrowingStream { continuation in
            func startTimeoutTimer() {
                timeoutTimer?.invalidate()
                timeoutTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { _ in
                    WireLogger.pushChannel.debug("timeout waiting for push event", attributes: .pushChannelV3)
                    continuation.yield(.upToDate)
                    Task { await self.close() }
                }
                RunLoop.main.add(timeoutTimer!, forMode: .common)
            }

            startTimeoutTimer()

            Task {
                do {
                    while let element = try await iterator.next() {
                        timeoutTimer?.invalidate()
                        continuation.yield(element)
                        startTimeoutTimer()
                    }
                    timeoutTimer?.invalidate()
                    continuation.finish()
                } catch {
                    timeoutTimer?.invalidate()
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                timeoutTimer?.invalidate()
            }
        }
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

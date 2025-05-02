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

public final class NewPushChannel: PushChannelProtocol {

    public typealias Stream = AsyncThrowingStream<UpdateEventEnvelope, any Error>

    private let webSocket: any WebSocketProtocol
    private let decoder = JSONDecoder()

    public init(webSocket: any WebSocketProtocol) {
        self.webSocket = webSocket
    }

    public func open() async throws -> Stream {
        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV3)
        return try await webSocket.open().map { [weak self, decoder] message in
            do {
                switch message {
                case let .data(data):
                    WireLogger.pushChannel.debug("received web socket data, decoding...", attributes: .pushChannelV3)
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
            } catch {
                WireLogger.pushChannel.debug("failed to get next web socket message: \(error)", attributes: .pushChannelV3)
                await self?.close()
                throw error
            }
        }.toStream()
    }

    public func ack(deliveryTag: UInt64, multiple: Bool = false) async throws {
        let acknowledgement = EventAcknowledgmentNotification(
            deliveryTag: deliveryTag,
            multiple: multiple
        )
        let data = try JSONEncoder().encode(acknowledgement)
        try await write(data: data)
    }

    public func ackFullSync() async throws {
        let acknowledgement = FullSyncAcknowledgmentNotification()
        let data = try JSONEncoder().encode(acknowledgement)
        try await write(data: data)
    }

    public func close() async {
        WireLogger.pushChannel.debug("closing push channel", attributes: .pushChannelV3)
        await webSocket.close()
    }

    private func write(data: Data) async throws {
        WireLogger.pushChannel.debug("write data to push channel", attributes: .pushChannelV3)
        try await webSocket.write(data: data)
    }
}

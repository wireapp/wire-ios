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

public actor PushChannel: PushChannelProtocol {

    public typealias Stream = AsyncThrowingStream<UpdateEventEnvelope, any Error>

    // MARK: - Properties

    private let webSocket: any WebSocketProtocol
    private let decoder = JSONDecoder()

    private var keepAliveTask: Task<Void, any Error>?
    private let keepAliveInterval: TimeInterval

    // MARK: - Init

    public init(
        webSocket: any WebSocketProtocol,
        keepAliveInterval: TimeInterval
    ) {
        self.webSocket = webSocket
        self.keepAliveInterval = keepAliveInterval
    }

    // MARK: - Public

    public func open() async throws -> Stream {
        WireLogger.pushChannel.debug("opening new push channel")
        let stream = try await webSocket.open().map { [weak self, decoder] message in
            do {
                switch message {
                case let .data(data):
                    WireLogger.pushChannel.debug("received web socket data, decoding...")
                    let envelope = try decoder.decode(UpdateEventEnvelopeV0.self, from: data)
                    return envelope.toAPIModel()

                case .string:
                    WireLogger.pushChannel.debug("received web socket string, ignoring...")
                    throw PushChannelError.receivedInvalidMessage

                @unknown default:
                    WireLogger.pushChannel.debug("received unknown web socket message, ignoring...")
                    throw PushChannelError.receivedInvalidMessage
                }
            } catch {
                WireLogger.pushChannel.debug("failed to get next web socket message: \(error)")
                await self?.close()
                throw error
            }
        }.toStream()

        // The server will drop the connection (possibly silently)
        // if the client doesn’t send a ping message every so often.
        setUpKeepAliveTask()

        return stream
    }

    public func close() async {
        WireLogger.pushChannel.debug("closing push channel")
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
                    await sendKeepAlivePing()
                }
            } catch {
                WireLogger.pushChannel.warn("keep alive task was cancelled")
                tearDownKeepAliveTask()
            }
        }
    }

    private func sendKeepAlivePing() async {
        do {
            WireLogger.pushChannel.debug("sending keep alive ping")
            try await webSocket.write(Data())
        } catch {
            WireLogger.pushChannel.error("failed to send keep alive ping: \(error)")
        }
    }

    private func tearDownKeepAliveTask() {
        guard let keepAliveTask else { return }
        WireLogger.pushChannel.debug("tearing down keep alive task")
        keepAliveTask.cancel()
        self.keepAliveTask = nil
    }

}

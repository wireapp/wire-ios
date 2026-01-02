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

public import Foundation

import WireFoundation
import WireLogging

public typealias PushChannelV1 = PushChannel
public typealias PushChannelV1Procotol = PushChannelProtocol

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
        // We don't want to proceed if not necessary (in case we've
        // gone to the background)
        try Task.checkCancellation()

        WireLogger.pushChannel.debug("opening new push channel", attributes: .pushChannelV1)
        let stream = try await webSocket.open().map { [weak self, decoder] message in
            do {
                switch message {
                case let .data(data):
                    WireLogger.pushChannel.debug("received web socket data, decoding...", attributes: .pushChannelV1)
                    let envelope = try decoder.decode(UpdateEventEnvelopeV0.self, from: data)
                    return envelope.toAPIModel()

                case .string:
                    WireLogger.pushChannel.debug("received web socket string, ignoring...", attributes: .pushChannelV1)
                    throw PushChannelError.receivedInvalidMessage

                @unknown default:
                    WireLogger.pushChannel.debug(
                        "received unknown web socket message, ignoring...",
                        attributes: .pushChannelV1
                    )
                    throw PushChannelError.receivedInvalidMessage
                }
            } catch {
                WireLogger.pushChannel.debug(
                    "failed to get next web socket message: \(error)",
                    attributes: .pushChannelV1
                )
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
                    WireLogger.pushChannel.debug("sending keep alive ping 🍒", attributes: .pushChannelV1)
                    try await webSocket.sendPing()
                }
            } catch {
                WireLogger.pushChannel.warn("keep alive task was cancelled 🍒", attributes: .pushChannelV1)
                await webSocket.cancel(withError: error)
                tearDownKeepAliveTask()
            }
        }
    }

    private func tearDownKeepAliveTask() {
        guard let keepAliveTask else { return }
        WireLogger.pushChannel.debug("tearing down keep alive task", attributes: .pushChannelV1)
        keepAliveTask.cancel()
        self.keepAliveTask = nil
    }

    public func write(data: Data) async throws {
        // do nothing
    }
}

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

import WireLogging

public actor WebSocket: WebSocketProtocol {

    public typealias Stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, any Error>

    private let connection: any URLSessionWebSocketTaskProtocol
    private var continuation: Stream.Continuation?

    public init(connection: any URLSessionWebSocketTaskProtocol) {
        self.connection = connection
    }

    deinit {
        connection.cancel(with: .goingAway, reason: nil)
        continuation?.finish()
    }

    public func open() async throws -> Stream {
        WireLogger.webSocket.debug("open")
        connection.resume()

        if #available(iOS 17, *) {
            return Stream { continuation in
                self.continuation = continuation

                Task {
                    var isAlive = true

                    while isAlive, connection.isOpen {
                        do {
                            let message = try await connection.receive()
                            WireLogger.webSocket.debug("received message")
                            continuation.yield(message)
                            try Task.checkCancellation()
                        } catch {
                            continuation.finish(throwing: error)
                            isAlive = false
                        }
                    }

                    continuation.finish()
                }
            }
        } else {
            // This is the solution pre-iOS17, see for more details:
            // https://www.donnywals.com/iterating-over-web-socket-messages-with-async-await-in-swift/
            return Stream { continuation in
                self.continuation = continuation

                @Sendable
                func yieldNextMessage() {
                    guard connection.isOpen else {
                        continuation.finish()
                        return
                    }

                    connection.receive { result in
                        switch result {
                        case let .success(message):
                            continuation.yield(message)
                            yieldNextMessage()

                        case let .failure(error):
                            continuation.finish(throwing: error)
                        }
                    }
                }

                yieldNextMessage()
            }
        }
    }

    public func close() async {
        connection.cancel(with: .goingAway, reason: nil)
        continuation?.finish()
        continuation = nil
    }

//    public func sendPing() async {
//        connection.sendPing { error in
//            if let error {
//                WireLogger.pushChannel.warn("failed to send keep alive ping: \(error)")
//            }
//        }
//    }
    public func sendPing() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            connection.sendPing { error in
                if let error {
                    WireLogger.pushChannel.warn("failed to send keep alive ping: \(error)")
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func cancel(withError error: any Error) async {
        WireLogger.webSocket.debug("cancelling with error: \(error)")
        continuation?.finish(throwing: error)
        connection.cancel(with: .abnormalClosure, reason: nil)
        continuation = nil
    }

    public func write(data: Data) async throws {
        try await connection.send(.data(data))
    }

    public func write(string: String) async throws {
        try await connection.send(.string(string))
    }

}

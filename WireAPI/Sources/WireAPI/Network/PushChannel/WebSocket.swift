//
// Wire
// Copyright (C) 2024 Wire Swiss GmbH
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

final class WebSocket: WebSocketProtocol {

    typealias Stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, any Error>

    private let connection: any URLSessionWebSocketTaskProtocol
    private var continuation: Stream.Continuation?

    init(connection: any URLSessionWebSocketTaskProtocol) {
        self.connection = connection
    }

    deinit {
        close()
    }

    func open() throws -> Stream {
        connection.resume()

        if #available(iOS 17, *) {
            return Stream { continuation in
                self.continuation = continuation

                Task {
                    var isAlive = true

                    while isAlive, connection.isOpen {
                        do {
                            let message = try await connection.receive()
                            continuation.yield(message)
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

                func yieldNextMessage() {
                    guard connection.isOpen else {
                        continuation.finish()
                        return
                    }

                    connection.receive { result in
                        switch result {
                        case .success(let message):
                            continuation.yield(message)
                            yieldNextMessage()

                        case .failure(let error):
                            continuation.finish(throwing: error)
                        }
                    }
                }

                yieldNextMessage()
            }
        }
    }

    func close() {
        connection.cancel(with: .goingAway, reason: nil)
        continuation?.finish()
    }

}

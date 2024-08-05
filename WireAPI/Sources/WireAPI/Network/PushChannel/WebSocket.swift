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

// sourcery: AutoMockable
protocol URLSessionWebSocketTaskProtocol {

    var isOpen: Bool { get }

    func resume()

    func cancel(
        with closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    )

    func receive(completionHandler: @escaping (Result<URLSessionWebSocketTask.Message, any Error>) -> Void)

}

extension URLSessionWebSocketTask: URLSessionWebSocketTaskProtocol {

    var isOpen: Bool {
        closeCode == .invalid
    }

}

final class WebSocket: AsyncSequence {

    typealias Element = Stream.Element
    typealias Stream = AsyncThrowingStream<URLSessionWebSocketTask.Message, Error>

    private let connection: any URLSessionWebSocketTaskProtocol
    private lazy var stream = makeStream()
    private var continuation: Stream.Continuation?

    init(connection: any URLSessionWebSocketTaskProtocol) {
        self.connection = connection
        connection.resume()
    }

    deinit {
        close()
    }

    func close() {
        // TODO: is this the right code?
        connection.cancel(with: .goingAway, reason: nil)
        continuation?.finish()
    }

    private func makeStream() -> Stream {
        Stream { continuation in
            self.continuation = continuation

            func yieldNextMessage() {
                guard connection.isOpen else {
                    continuation.finish()
                    return
                }

                // Note: From iOS 17 we can use the await variant of this. See  https://www.donnywals.com/iterating-over-web-socket-messages-with-async-await-in-swift/
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

    func makeAsyncIterator() -> Stream.AsyncIterator {
        stream.makeAsyncIterator()
    }

}

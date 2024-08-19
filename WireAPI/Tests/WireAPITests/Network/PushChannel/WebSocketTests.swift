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

import XCTest

@testable import WireAPI
@testable import WireAPISupport

final class WebSocketTests: XCTestCase {

    var connection: MockURLSessionWebSocketTaskProtocol!

    override func setUp() async throws {
        try await super.setUp()
        connection = MockURLSessionWebSocketTaskProtocol()
        connection.resume_MockMethod = {}
        connection.cancelWithReason_MockMethod = { _, _ in }
    }

    override func tearDown() async throws {
        connection = nil
        try await super.tearDown()
    }

    func testWebSocketResumesConnectionWhenCreated() async throws {
        // When
        _ = WebSocket(connection: connection)

        // Then
        XCTAssertEqual(connection.resume_Invocations.count, 1)
    }

    func testWebSocketCancelsWhenItDeinitializes() async throws {
        // When
        {
            _ = WebSocket(connection: self.connection)
        }()

        // Then
        let invocations = connection.cancelWithReason_Invocations
        try XCTAssertCount(invocations, count: 1)
        XCTAssertEqual(invocations[0].closeCode, .goingAway)
        XCTAssertNil(invocations[0].reason)
    }

    func testWebSocketCloses() async throws {
        // Given we're iterating over the web socket
        let sut = WebSocket(connection: connection)

        // Mock sending one message
        connection.underlyingIsOpen = true

        var shouldSendData = true
        connection.receiveCompletionHandler_MockMethod = { handler in
            guard shouldSendData else { return }
            shouldSendData = false
            handler(.success(.data(Data())))
        }

        let didReceiveMessage = XCTestExpectation()
        let didFinishIterating = XCTestExpectation()

        Task {
            for try await _ in sut.makeStream() {
                didReceiveMessage.fulfill()
            }

            didFinishIterating.fulfill()
        }

        // Wait for iteration to be in progress
        await fulfillment(of: [didReceiveMessage], timeout: 0.5)

        // When
        sut.close()

        // Then the stream finished successfully
        await fulfillment(of: [didFinishIterating], timeout: 0.5)

        // Then the connection was cancelled
        let invocations = connection.cancelWithReason_Invocations
        try XCTAssertCount(invocations, count: 1)
        XCTAssertEqual(invocations[0].closeCode, .goingAway)
        XCTAssertNil(invocations[0].reason)
    }

    func testWebSocketFinishesIfConnectionCloses() async throws {
        // Given we're iterating over the web socket
        let sut = WebSocket(connection: connection)

        // Mock sending messages
        connection.underlyingIsOpen = true
        connection.receiveCompletionHandler_MockMethod = { handler in
            Task {
                do {
                    // Space the messages 0.5s apart
                    try await Task.sleep(nanoseconds: 500_000)
                    handler(.success(.data(Data())))
                } catch {
                    XCTFail("failed to mock web socket data: \(error)")
                }
            }
        }

        let didReceiveMessage = XCTestExpectation()
        didReceiveMessage.assertForOverFulfill = false
        let didFinishIterating = XCTestExpectation()

        Task {
            do {
                for try await _ in sut.makeStream() {
                    didReceiveMessage.fulfill()
                }
            } catch {
                XCTFail("failed to iterate stream: \(error)")
                return
            }

            didFinishIterating.fulfill()
        }

        // Wait for iteration to be in progress
        await fulfillment(of: [didReceiveMessage], timeout: 0.5)

        // When
        connection.underlyingIsOpen = false

        // Then the stream finished successfully
        await fulfillment(of: [didFinishIterating], timeout: 0.5)
    }

    func testWebSocketFinishesIfConnectionHasError() async throws {
        // Given we're iterating over the web socket
        let sut = WebSocket(connection: connection)
        var shouldSendError = false

        // Mock sending messages
        connection.underlyingIsOpen = true
        connection.receiveCompletionHandler_MockMethod = { handler in
            if shouldSendError {
                handler(.failure("some error"))
                return
            }

            Task {
                do {
                    // Space the messages 0.5s apart
                    try await Task.sleep(nanoseconds: 500_000)
                    handler(.success(.data(Data())))
                } catch {
                    XCTFail("failed to mock web socket data: \(error)")
                }
            }
        }

        let didReceiveMessage = XCTestExpectation()
        didReceiveMessage.assertForOverFulfill = false
        let didFinishIteratingDueToError = XCTestExpectation()

        Task {
            do {
                for try await _ in sut.makeStream() {
                    didReceiveMessage.fulfill()
                }
            } catch {
                didFinishIteratingDueToError.fulfill()
            }
        }

        // Wait for iteration to be in progress
        await fulfillment(of: [didReceiveMessage], timeout: 0.5)

        // When
        shouldSendError = true

        // Then the stream finished with an error
        await fulfillment(of: [didFinishIteratingDueToError], timeout: 0.5)
    }

    func testWebSocketIteratesSuccessfully() async throws {
        // Given we're iterating over the web socket
        let sut = WebSocket(connection: connection)
        let messages = ["message1", "message2", "message3", "message4", "message5"]
        var messageData = messages.reversed().compactMap {
            $0.data(using: .utf8)
        }

        // Mock sending messages
        connection.underlyingIsOpen = true
        connection.receiveCompletionHandler_MockMethod = { handler in
            guard let message = messageData.popLast() else {
                return
            }

            Task {
                do {
                    // Space the messages 0.5s apart
                    try await Task.sleep(nanoseconds: 500_000)
                    handler(.success(.data(Data())))
                } catch {
                    XCTFail("failed to mock web socket data: \(error)")
                }
            }
        }

        let didReceiveMessage = XCTestExpectation()
        didReceiveMessage.expectedFulfillmentCount = 5

        let task = Task {
            var receivedMessageData = [Data]()

            // When
            for try await message in sut.makeStream() {
                if case .data(let data) = message {
                    receivedMessageData.append(data)
                }

                didReceiveMessage.fulfill()
            }

            return receivedMessageData.map {
                String(decoding: $0, as: UTF8.self)
            }
        }

        // Wait for messages to be received then we can close
        await fulfillment(of: [didReceiveMessage], timeout: 0.5)
        sut.close()

        // Then all messages were received in order
        let receivedMessages = try await task.value
        XCTAssertEqual(receivedMessages, messages)
    }

}

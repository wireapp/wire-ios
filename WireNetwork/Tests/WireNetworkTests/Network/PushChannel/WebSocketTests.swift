//
// Wire
// Copyright (C) 2026 Wire Swiss GmbH
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

@testable import WireNetwork
@testable import WireNetworkSupport

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

    func testWebSocketCloses() async throws {
        // Given we're iterating over the web socket
        let sut = WebSocket(connection: connection)

        // Mock sending one message
        connection.underlyingIsOpen = true

        connection.receive_MockMethod = {
            // Space the messages 0.5s apart
            try await Task.sleep(nanoseconds: 500_000)
            return .data(Data())
        }

        let didReceiveMessage = XCTestExpectation()
        didReceiveMessage.assertForOverFulfill = false
        let didFinishIterating = XCTestExpectation()

        Task {
            do {
                for try await _ in try await sut.open() {
                    didReceiveMessage.fulfill()
                }
            } catch {
                XCTFail("unexpected error: \(error)")
            }

            didFinishIterating.fulfill()
        }

        // Wait for iteration to be in progress
        await fulfillment(of: [didReceiveMessage], timeout: 1)

        // When
        await sut.close()

        // Then the stream finished successfully
        await fulfillment(of: [didFinishIterating], timeout: 1)

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
        connection.receive_MockMethod = {
            // Space the messages 0.5s apart
            try await Task.sleep(nanoseconds: 500_000)
            return .data(Data())
        }

        let didReceiveMessage = XCTestExpectation()
        didReceiveMessage.assertForOverFulfill = false
        let didFinishIterating = XCTestExpectation()

        Task {
            do {
                for try await _ in try await sut.open() {
                    didReceiveMessage.fulfill()
                }
            } catch {
                XCTFail("failed to iterate stream: \(error)")
                return
            }

            didFinishIterating.fulfill()
        }

        // Wait for iteration to be in progress
        await fulfillment(of: [didReceiveMessage], timeout: 1)

        // When
        connection.underlyingIsOpen = false

        // Then the stream finished successfully
        await fulfillment(of: [didFinishIterating], timeout: 1)
    }

    func testWebSocketFinishesIfConnectionHasError() async throws {
        // Given we're iterating over the web socket
        let sut = WebSocket(connection: connection)
        var shouldSendError = false

        // Mock sending messages
        connection.underlyingIsOpen = true
        connection.receive_MockMethod = {
            if shouldSendError {
                throw "some error"
            }

            // Space the messages 0.5s apart
            try await Task.sleep(nanoseconds: 500_000)
            return .data(Data())
        }

        let didReceiveMessage = XCTestExpectation()
        didReceiveMessage.assertForOverFulfill = false
        let didFinishIteratingDueToError = XCTestExpectation()

        Task {
            do {
                for try await _ in try await sut.open() {
                    didReceiveMessage.fulfill()
                }
            } catch {
                didFinishIteratingDueToError.fulfill()
            }
        }

        // Wait for iteration to be in progress
        await fulfillment(of: [didReceiveMessage], timeout: 1)

        // When
        shouldSendError = true

        // Then the stream finished with an error
        await fulfillment(of: [didFinishIteratingDueToError], timeout: 1)
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
        connection.receive_MockMethod = {
            guard let message = messageData.popLast() else {
                throw "no more messages"
            }

            // Space the messages 0.5s apart
            try await Task.sleep(nanoseconds: 500_000)
            return .data(message)
        }

        var receivedMessageData = [Data]()

        // When
        do {
            for try await message in try await sut.open() {
                if case let .data(data) = message {
                    receivedMessageData.append(data)
                }
            }
        } catch let error as String where error == "no more messages" {
            // no op
        } catch {
            XCTFail("unexpected error: \(error)")
            return
        }

        let receivedMessages = receivedMessageData.map {
            String(decoding: $0, as: UTF8.self)
        }

        // Then all messages were received in order
        XCTAssertEqual(receivedMessages, messages)
    }

    func testWebSocketSendsDataSuccessfully() async throws {
        // GIVEN
        connection.send_MockMethod = { _ in }

        let sut = WebSocket(connection: connection)
        let testData = Data("test".utf8)

        // WHEN
        try await sut.write(data: testData)

        // THEN
        try XCTAssertCount(connection.send_Invocations, count: 1)
        let result = try XCTUnwrap(connection.send_Invocations.first)
        if case URLSessionWebSocketTask.Message.data(testData) = result {
            // successful
        } else {
            XCTFail("unexpected message written: \(result)")
        }
    }

    func testWebSocketSendsStringSuccessfully() async throws {
        // GIVEN
        connection.send_MockMethod = { _ in }

        let sut = WebSocket(connection: connection)
        let testString = "test"

        // WHEN
        try await sut.write(string: testString)

        // THEN
        try XCTAssertCount(connection.send_Invocations, count: 1)
        let result = try XCTUnwrap(connection.send_Invocations.first)
        if case URLSessionWebSocketTask.Message.string(testString) = result {
            // successful
        } else {
            XCTFail("unexpected message written: \(result)")
        }
    }

}

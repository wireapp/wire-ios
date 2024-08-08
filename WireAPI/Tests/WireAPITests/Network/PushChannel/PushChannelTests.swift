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

final class PushChannelTests: XCTestCase {

    var sut: PushChannel!
    var request: URLRequest!
    var urlSession: URLSessionMock!
    var webSocketConnection: MockURLSessionWebSocketTaskProtocol!

    override func setUp() async throws {
        try await super.setUp()
        let url = try XCTUnwrap(URL(string: "www.example.com"))
        request = URLRequest(url: url)
        urlSession = URLSessionMock()
        webSocketConnection = MockURLSessionWebSocketTaskProtocol()

        sut = PushChannel(
            request: request,
            urlSession: urlSession
        )

        // Mocks
        webSocketConnection.resume_MockMethod = { }
        webSocketConnection.cancelWithReason_MockMethod = { _, _ in }
        urlSession.webSocket = WebSocket(connection: webSocketConnection)
    }

    override func tearDown() async throws {
        request = nil
        urlSession = nil
        webSocketConnection = nil
        sut = nil
        try await super.tearDown()
    }

    func testOpenPushChannel() async throws {
        // Given some envelopes that will be delivered through the push channel
        var mockEnvelopes = [
            try MockJSONPayloadResource(name: "LiveUpdateEventEnvelope1"),
            try MockJSONPayloadResource(name: "LiveUpdateEventEnvelope2"),
            try MockJSONPayloadResource(name: "LiveUpdateEventEnvelope3")
        ]

        webSocketConnection.underlyingIsOpen = true
        webSocketConnection.receiveCompletionHandler_MockMethod = { handler in
            guard !mockEnvelopes.isEmpty else {
                // Don't call the handler, this will cause the stream to pause
                return
            }
            
            let envelope = mockEnvelopes.removeFirst()
            handler(.success(.data(envelope.jsonData)))
        }

        // When the push channel is open and the stream is iterated
        let liveEventEnvelopes = try await sut.open()

        var receivedEnvelopes = [UpdateEventEnvelope]()
        for try await envelope in liveEventEnvelopes {
            receivedEnvelopes.append(envelope)

            if receivedEnvelopes.count == 3 {
                break
            }
        }

        // Then envelopes are received
        try XCTAssertCount(receivedEnvelopes, count: 3)
        XCTAssertEqual(receivedEnvelopes[0], Scaffolding.envelope1)
        XCTAssertEqual(receivedEnvelopes[1], Scaffolding.envelope2)
        XCTAssertEqual(receivedEnvelopes[2], Scaffolding.envelope3)
    }

    func testClosingPushChannel() async throws {
        // Given an open push channel that is being iterated
        var mockEnvelopes = [
            try MockJSONPayloadResource(name: "LiveUpdateEventEnvelope1")
        ]

        webSocketConnection.underlyingIsOpen = true
        webSocketConnection.receiveCompletionHandler_MockMethod = { handler in
            guard !mockEnvelopes.isEmpty else {
                // Don't call the handler, this will cause the stream to pause
                return
            }

            let envelope = mockEnvelopes.removeFirst()
            handler(.success(.data(envelope.jsonData)))
        }

        let liveEventEnvelopes = try await sut.open()
        let didReceiveFirstEnvelope = XCTestExpectation()

        let task = Task {
            var receivedEnvelopes = [UpdateEventEnvelope]()
            for try await envelope in liveEventEnvelopes {
                receivedEnvelopes.append(envelope)

                if receivedEnvelopes.count == 1 {
                    didReceiveFirstEnvelope.fulfill()
                }
            }
        }

        await fulfillment(of: [didReceiveFirstEnvelope])

        // When the push channel is closed
        sut.close()
        
        // Then the stream will end
        try await task.value

        // Then the web socket was closed
        let cancelInvocations = webSocketConnection.cancelWithReason_Invocations
        try XCTAssertCount(cancelInvocations, count: 1)
        XCTAssertEqual(cancelInvocations[0].closeCode, .goingAway)
    }

    func testFailureToDecodeClosesPushChannel() async throws {
        // Given an open push channel that is being iterated
        var invalidData: Data? = Data()

        webSocketConnection.underlyingIsOpen = true
        webSocketConnection.receiveCompletionHandler_MockMethod = { handler in
            guard let data = invalidData else {
                // Don't call the handler, this will cause the stream to pause
                return
            }

            invalidData = nil

            // When invalid data is sent
            handler(.success(.data(data)))
        }

        let liveEventEnvelopes = try await sut.open()

        do {
            for try await _ in liveEventEnvelopes {
                // no op
            }
        } catch is DecodingError {
            // Then a decoding error was thrown
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        // Then the web socket was closed
        let cancelInvocations = webSocketConnection.cancelWithReason_Invocations
        try XCTAssertCount(cancelInvocations, count: 1)
        XCTAssertEqual(cancelInvocations[0].closeCode, .goingAway)
    }

    func testReceivingUnknownMessageClosesPushChannel() async throws {
        // Given an open push channel that is being iterated
        var unknownMessage: String? = "a string"

        webSocketConnection.underlyingIsOpen = true
        webSocketConnection.receiveCompletionHandler_MockMethod = { handler in
            guard let message = unknownMessage else {
                // Don't call the handler, this will cause the stream to pause
                return
            }

            unknownMessage = nil

            // When an unknown message is sent
            handler(.success(.string(message)))
        }

        let liveEventEnvelopes = try await sut.open()

        do {
            for try await _ in liveEventEnvelopes {
                // no op
            }
        } catch PushChannelError.receivedInvalidMessage {
            // Then an error is thrown
        } catch {
            XCTFail("unexpected error: \(error)")
        }

        // Then the web socket was closed
        let cancelInvocations = webSocketConnection.cancelWithReason_Invocations
        try XCTAssertCount(cancelInvocations, count: 1)
        XCTAssertEqual(cancelInvocations[0].closeCode, .goingAway)
    }

}

private enum Scaffolding {

    static let envelope1 = UpdateEventEnvelope(
        id: UUID(uuidString: "66c7731b-9985-4b5e-90d7-b8f8ce1cadb9")!,
        events: [
            .conversation(.proteusMessageAdd(proteusMessageAddEvent)),
            .conversation(.protocolUpdate(protocolUpdateEvent))
        ],
        isTransient: false
    )

    static let envelope2 = UpdateEventEnvelope(
        id: UUID(uuidString: "7b406b6e-df92-4844-b20b-2e673ca2d027")!,
        events: [
            .conversation(.receiptModeUpdate(receiptModeUpdateEvent)),
            .conversation(.rename(renameEvent))
        ],
        isTransient: false
    )

    static let envelope3 = UpdateEventEnvelope(
        id: UUID(uuidString: "eb660720-079c-43f3-9a80-1168638c928f")!,
        events: [
            .conversation(.typing(typingEvent)),
            .conversation(.delete(deleteEvent))
        ],
        isTransient: false
    )

    static func fractionalDate(from string: String) -> Date {
        ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
    }

    static func date(from string: String) -> Date {
        ISO8601DateFormatter.internetDateTime.date(from: string)!
    }

    static let conversationID = ConversationID(
        uuid: UUID(uuidString: "a644fa88-2d83-406b-8a85-d4fd8dedad6b")!,
        domain: "example.com"
    )

    static let senderID = UserID(
        uuid: UUID(uuidString: "f55fe9b0-a0cc-4b11-944b-125c834d9b6a")!,
        domain: "example.com"
    )

    static let timestamp = fractionalDate(from: "2024-06-04T15:03:07.598Z")

    static let proteusMessageAddEvent = ConversationProteusMessageAddEvent(
        conversationID: conversationID,
        senderID: senderID,
        timestamp: timestamp,
        message: .ciphertext("foo"),
        externalData: .ciphertext("bar"),
        messageSenderClientID: "abc123",
        messageRecipientClientID: "def456"
    )

    static let protocolUpdateEvent = ConversationProtocolUpdateEvent(
        conversationID: conversationID,
        senderID: senderID,
        newProtocol: .mls
    )

    static let receiptModeUpdateEvent = ConversationReceiptModeUpdateEvent(
        conversationID: conversationID,
        senderID: senderID,
        newRecieptMode: 1
    )

    static let renameEvent = ConversationRenameEvent(
        conversationID: conversationID,
        senderID: senderID,
        timestamp: timestamp,
        newName: "foo"
    )

    static let typingEvent = ConversationTypingEvent(
        conversationID: conversationID,
        senderID: senderID,
        isTyping: true
    )

    static let deleteEvent = ConversationDeleteEvent(
        conversationID: conversationID,
        senderID: senderID,
        timestamp: timestamp
    )

}

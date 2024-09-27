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
    var webSocket: MockWebSocketProtocol!

    override func setUp() async throws {
        try await super.setUp()
        let url = try XCTUnwrap(URL(string: "www.example.com"))
        request = URLRequest(url: url)
        webSocket = MockWebSocketProtocol()
        webSocket.close_MockMethod = {}

        sut = PushChannel(
            request: request,
            webSocket: webSocket
        )
    }

    override func tearDown() async throws {
        request = nil
        webSocket = nil
        sut = nil
        try await super.tearDown()
    }

    func testOpenPushChannel() async throws {
        // Given some envelopes that will be delivered through the push channel
        let mockEnvelope1 = try MockJSONPayloadResource(name: "LiveUpdateEventEnvelope1")
        let mockEnvelope2 = try MockJSONPayloadResource(name: "LiveUpdateEventEnvelope2")
        let mockEnvelope3 = try MockJSONPayloadResource(name: "LiveUpdateEventEnvelope3")

        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            continuation.yield(.data(mockEnvelope1.jsonData))
            continuation.yield(.data(mockEnvelope2.jsonData))
            continuation.yield(.data(mockEnvelope3.jsonData))
            continuation.finish()
        }

        // When the push channel is open and the stream is iterated
        let liveEventEnvelopes = try sut.open()

        var receivedEnvelopes = [UpdateEventEnvelope]()
        for try await envelope in liveEventEnvelopes {
            receivedEnvelopes.append(envelope)
        }

        // Then envelopes are received
        try XCTAssertCount(receivedEnvelopes, count: 3)
        XCTAssertEqual(receivedEnvelopes[0], Scaffolding.envelope1)
        XCTAssertEqual(receivedEnvelopes[1], Scaffolding.envelope2)
        XCTAssertEqual(receivedEnvelopes[2], Scaffolding.envelope3)
    }

    func testClosingPushChannel() async throws {
        // Given an open push channel
        webSocket.open_MockValue = AsyncThrowingStream { _ in }
        _ = try sut.open()

        // When the push channel is closed
        sut.close()

        // Then the web socket was closed
        XCTAssertEqual(webSocket.close_Invocations.count, 1)
    }

    func testFailureToDecodeClosesPushChannel() async throws {
        // Given an open push channel that is being iterated
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            // Send some invalid data
            continuation.yield(.data(Data()))
            // Don't call finish, so the stream stays open.
        }

        let liveEventEnvelopes = try sut.open()

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
        XCTAssertEqual(webSocket.close_Invocations.count, 1)
    }

    func testReceivingUnknownMessageClosesPushChannel() async throws {
        // Given an open push channel that is being iterated
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            // Send some invalid data.
            continuation.yield(.string("some string"))
            // Don't call finish, so the stream stays open.
        }

        let liveEventEnvelopes = try sut.open()

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
        XCTAssertEqual(webSocket.close_Invocations.count, 1)
    }
}

private enum Scaffolding {
    static let envelope1 = UpdateEventEnvelope(
        id: UUID(uuidString: "66c7731b-9985-4b5e-90d7-b8f8ce1cadb9")!,
        events: [
            .conversation(.proteusMessageAdd(proteusMessageAddEvent)),
            .conversation(.protocolUpdate(protocolUpdateEvent)),
        ],
        isTransient: false
    )

    static let envelope2 = UpdateEventEnvelope(
        id: UUID(uuidString: "7b406b6e-df92-4844-b20b-2e673ca2d027")!,
        events: [
            .conversation(.receiptModeUpdate(receiptModeUpdateEvent)),
            .conversation(.rename(renameEvent)),
        ],
        isTransient: false
    )

    static let envelope3 = UpdateEventEnvelope(
        id: UUID(uuidString: "eb660720-079c-43f3-9a80-1168638c928f")!,
        events: [
            .conversation(.typing(typingEvent)),
            .conversation(.delete(deleteEvent)),
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

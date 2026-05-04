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

final class PushChannelV2Tests: XCTestCase {

    var sut: PushChannelV2!
    var request: URLRequest!
    var webSocket: MockWebSocketProtocol!

    override func setUp() async throws {
        try await super.setUp()
        let url = try XCTUnwrap(URL(string: "www.example.com"))
        request = URLRequest(url: url)
        webSocket = MockWebSocketProtocol()
        webSocket.close_MockMethod = {}
        webSocket.sendPing_MockMethod = {}
        sut = PushChannelV2(
            webSocket: webSocket,
            keepAliveInterval: 0.5,
            maxBatchEventsCount: 25,
            batchDelay: 0.5
        )
    }

    override func tearDown() async throws {
        request = nil
        webSocket = nil
        sut = nil
        try await super.tearDown()
    }

    func testOpen_DecodeEventSuccessfully() async throws {
        // Given some envelopes that will be delivered through the push channel
        let mockEnvelope1 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope1")
        let mockEnvelope2 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope2")
        let mockEnvelope3 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope3")

        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            continuation.yield(.data(mockEnvelope1.jsonData))
            continuation.yield(.data(mockEnvelope2.jsonData))
            continuation.yield(.data(mockEnvelope3.jsonData))
            continuation.finish()
        }

        // When the push channel is open and the stream is iterated
        let liveEventEnvelopes = try await sut.open()

        var receivedEnvelopes = [PushChannelV2.Element]()
        for try await envelope in liveEventEnvelopes {
            receivedEnvelopes.append(envelope)
        }

        // Then envelopes are received
        try XCTAssertCount(receivedEnvelopes, count: 1)
        XCTAssertEqual(
            receivedEnvelopes[0],
            .events([Scaffolding.envelope1, Scaffolding.envelope2, Scaffolding.envelope3])
        )
    }

    func testMaxBatchCount0_DefaultsTo1() {
        sut = PushChannelV2(webSocket: webSocket, keepAliveInterval: 0.1, maxBatchEventsCount: 0, batchDelay: 0)

        XCTAssertEqual(sut.maxBatchEventsCount, 1)
    }

    func testMaxBatchCount100() {
        sut = PushChannelV2(webSocket: webSocket, keepAliveInterval: 0.1, maxBatchEventsCount: 100, batchDelay: 0)

        XCTAssertEqual(sut.maxBatchEventsCount, 100)
    }

    func testOpen_UntilUpToDate() async throws {
        // Given some envelopes that will be delivered through the push channel
        let mockEnvelope1 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope1")
        let mockEnvelope2 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope2")
        let endOfQueue = try MockJSONPayloadResource(name: "EndOfQueueEnvelope")

        webSocket.open_MockValue = AsyncThrowingStream { continuation in

            continuation.yield(.data(mockEnvelope1.jsonData))
            continuation.yield(.data(mockEnvelope2.jsonData))
            continuation.yield(.data(endOfQueue.jsonData))
            continuation.finish()
        }

        // When the push channel is open and the stream is iterated
        let liveEventEnvelopes = try await sut.open()

        var receivedEnvelopes = [PushChannelV2.Element]()
        for try await envelope in liveEventEnvelopes {
            receivedEnvelopes.append(envelope)
        }

        // Then envelopes are received
        try XCTAssertCount(receivedEnvelopes, count: 2)

        XCTAssertEqual(receivedEnvelopes[0], .events([Scaffolding.envelope1, Scaffolding.envelope2]))
        XCTAssertEqual(receivedEnvelopes[1], .syncMarker(
            id: Scaffolding.endOfQueueID,
            deliveryTag: Scaffolding.endOfQueueDeliveryTag
        ))
    }

    func testOpen_MissedNotificationsEvent() async throws {
        let mockEnvelopeMissedNotifications = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope4")

        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            continuation.yield(.data(mockEnvelopeMissedNotifications.jsonData))
            continuation.finish()
        }

        // When the push channel is open and the stream is iterated
        let liveEventEnvelopes = try await sut.open()

        var receivedEnvelopes = [PushChannelV2.Element]()
        for try await envelope in liveEventEnvelopes {
            receivedEnvelopes.append(envelope)
        }

        // Then envelopes are received
        try XCTAssertCount(receivedEnvelopes, count: 1)
        XCTAssertEqual(receivedEnvelopes[0], .missedEvents)
    }

    func testClose_CloseWebSocket() async throws {
        // Given an open push channel
        webSocket.open_MockValue = AsyncThrowingStream { _ in }
        _ = try await sut.open()

        // When the push channel is closed
        await sut.close()

        // Then the web socket was closed
        XCTAssertEqual(webSocket.close_Invocations.count, 1)
    }

    func testOpen_FailureToDecodeClosesPushChannel() async throws {
        // Given an open push channel that is being iterated
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            // Send some invalid data
            continuation.yield(.data(Data()))
            // Don't call finish, so the stream stays open.
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
        XCTAssertEqual(webSocket.close_Invocations.count, 1)
    }

    func testOpen_ReceivingUnknownMessage_IsIgnored() async throws {
        // Given an open push channel that is being iterated
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            // Send some invalid data.
            continuation.yield(.string("some string"))
            continuation.finish()
        }

        // should not throw
        _ = try await sut.open()
    }

    func testOpen_SendsKeepAlivePings() async throws {
        // Mock.
        webSocket.open_MockValue = AsyncThrowingStream { _ in }

        // Given an open push channel.
        _ = try await sut.open()

        // When we wait for 1 second.
        try await Task.sleep(for: .seconds(1.5))

        // Then keep alive pings are sent periodically (the timer
        // is not exact so we will we generous in our assertion of
        // at least 2 in 1.5 seconds).
        XCTAssertGreaterThanOrEqual(webSocket.sendPing_Invocations.count, 2)
    }

    func testOpen_WithReceiveUpToDate() async throws {
        // Mock.
        let endOfQueueEnvelope = try MockJSONPayloadResource(name: "EndOfQueueEnvelope")

        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            continuation.yield(.data(endOfQueueEnvelope.jsonData))
        }

        // Given an open push channel.
        let liveEventEnvelopes = try await sut.open()

        var receivedEnvelopes = [PushChannelV2.Element]()
        Task.detached {
            for try await envelope in liveEventEnvelopes {
                receivedEnvelopes.append(envelope)
            }
        }
        // When we wait for 1 second.
        try await Task.sleep(for: .seconds(1.5))

        // Then keep alive pings are sent periodically (the timer
        // is not exact so we will we generous in our assertion of
        // at least 2 in 1.5 seconds).
        XCTAssertGreaterThanOrEqual(webSocket.sendPing_Invocations.count, 2)
        try XCTAssertCount(receivedEnvelopes, count: 1)
        XCTAssertEqual(receivedEnvelopes.last, .syncMarker(
            id: Scaffolding.endOfQueueID,
            deliveryTag: Scaffolding.endOfQueueDeliveryTag
        ))

    }

    func testOpen_TimeoutTriggerIfNoEvents() async throws {
        // Mock.
        webSocket.open_MockValue = AsyncThrowingStream { _ in }

        // Given an open push channel.
        _ = try await sut.open()

        // When we wait for 1 second.
        try await Task.sleep(for: .seconds(1.5))

        // Then keep alive pings are sent periodically (the timer
        // is not exact so we will we generous in our assertion of
        // at least 2 in 1.5 seconds).
        XCTAssertGreaterThanOrEqual(webSocket.sendPing_Invocations.count, 2)
    }

    // MARK: - Batching

    func testOpen_CollectFlushesOnMaxCount() async throws {
        // GIVEN
        let elements = Array(1 ... 100)
        let endOfQueue = try MockJSONPayloadResource(name: "EndOfQueueEnvelope")
        let mockEnvelope5 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope5")
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            for _ in elements {
                continuation.yield(.data(mockEnvelope5.jsonData))
            }
            continuation.yield(.data(endOfQueue.jsonData))
            continuation.finish()
        }

        // WHEN
        let stream = try await sut.open()

        var collected: [PushChannelV2.Element] = []
        for try await element in stream {
            collected.append(element)
        }

        // THEN
        let expectedBatches = 5
        guard collected.count == expectedBatches else {
            XCTFail("wrong number of batches, got \(collected.count), expected \(expectedBatches)")
            return
        }
        let batches = collected[0 ... 3]
        for batch in batches {
            if case let .events(events) = batch {
                try XCTAssertCount(events, count: 25)
            } else {
                XCTFail("wrong number of events in batch, got \(batch), expected .events")
            }
        }

        XCTAssertEqual(collected.last, .syncMarker(
            id: Scaffolding.endOfQueueID,
            deliveryTag: Scaffolding.endOfQueueDeliveryTag
        ))
    }

    func testOpen_CollectFlushes_withUnevenBatchCount() async throws {
        // GIVEN
        let batchSize = 18  // the batch changes
        sut = PushChannelV2(
            webSocket: webSocket,
            keepAliveInterval: 0.5,
            maxBatchEventsCount: batchSize,
            batchDelay: 0.5
        )

        let elements = Array(1 ... 100)
        let endOfQueue = try MockJSONPayloadResource(name: "EndOfQueueEnvelope")
        let mockEnvelope5 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope5")
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            for _ in elements {
                continuation.yield(.data(mockEnvelope5.jsonData))
            }
            continuation.yield(.data(endOfQueue.jsonData))
            continuation.finish()
        }

        // WHEN
        let stream = try await sut.open()

        var collected: [PushChannelV2.Element] = []
        for try await element in stream {
            collected.append(element)
        }

        // THEN
        let expectedBatches = 7
        guard collected.count == expectedBatches else {
            XCTFail("wrong number of batches, got \(collected.count), expected \(expectedBatches)")
            return
        }
        let batches = collected[0 ... 5]
        try XCTAssertCount(batches, count: 6)
        for (index, batch) in batches.enumerated() {
            if case let .events(events) = batch {
                try XCTAssertCount(events, count: index == 5 ? 10 : batchSize)
            } else {
                XCTFail("wrong number of events in batch, got \(batch), expected .events")
            }
        }
        XCTAssertEqual(collected.last, .syncMarker(
            id: Scaffolding.endOfQueueID,
            deliveryTag: Scaffolding.endOfQueueDeliveryTag
        ))

    }

    func testOpen_CollectFlushesMaxCountHigherThanElements() async throws {
        // GIVEN
        let batchSize = 150  // the batch changes
        let nbElements = 100
        sut = PushChannelV2(
            webSocket: webSocket,
            keepAliveInterval: 0.5,
            maxBatchEventsCount: batchSize,
            batchDelay: 0.5
        )

        let elements = Array(1 ... nbElements)
        let endOfQueue = try MockJSONPayloadResource(name: "EndOfQueueEnvelope")
        let mockEnvelope5 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope5")
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            for _ in elements {
                continuation.yield(.data(mockEnvelope5.jsonData))
            }
            continuation.yield(.data(endOfQueue.jsonData))
            continuation.finish()
        }

        // WHEN
        let stream = try await sut.open()

        var collected: [PushChannelV2.Element] = []
        for try await element in stream {
            collected.append(element)
        }

        // THEN
        let expectedBatches = 2
        guard collected.count == expectedBatches else {
            XCTFail("wrong number of batches, got \(collected.count), expected \(expectedBatches)")
            return
        }
        let batch = try XCTUnwrap(collected.first)

        if case let .events(events) = batch {
            try XCTAssertCount(events, count: nbElements)
        } else {
            XCTFail("wrong number of events in batch, got \(batch), expected .events")
        }

        XCTAssertEqual(collected.last, .syncMarker(
            id: Scaffolding.endOfQueueID,
            deliveryTag: Scaffolding.endOfQueueDeliveryTag
        ))
    }

    func testOpen_CollectFlushesOnTimeout() async throws {
        // GIVEN
        let batchSize = 10  // the batch changes
        let nbElements = 3
        sut = PushChannelV2(
            webSocket: webSocket,
            keepAliveInterval: 0.5,
            maxBatchEventsCount: batchSize,
            batchDelay: 0.5
        )

        let endOfQueue = try MockJSONPayloadResource(name: "EndOfQueueEnvelope")
        let mockEnvelope5 = try MockJSONPayloadResource(name: "AsyncLiveUpdateEventEnvelope1")
        webSocket.open_MockValue = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(.data(mockEnvelope5.jsonData))
                try? await Task.sleep(for: .seconds(1))
                continuation.yield(.data(mockEnvelope5.jsonData))
                continuation.yield(.data(mockEnvelope5.jsonData))
                continuation.yield(.data(endOfQueue.jsonData))
                continuation.finish()
            }
        }

        // WHEN
        let stream = try await sut.open()

        var collected: [PushChannelV2.Element] = []
        for try await element in stream {
            collected.append(element)
        }

        // THEN
        let expectedBatches = 3
        guard collected.count == expectedBatches else {
            XCTFail("wrong number of batches, got \(collected.count), expected \(expectedBatches)")
            return
        }
        let batches = collected[0 ... 1]
        try XCTAssertCount(batches, count: 2)
        for (index, batch) in batches.enumerated() {
            if case let .events(events) = batch {
                try XCTAssertCount(events, count: index == 0 ? 1 : 2)
            } else {
                XCTFail("wrong number of events in batch, got \(batch), expected .events")
            }
        }
        XCTAssertEqual(collected.last, .syncMarker(
            id: Scaffolding.endOfQueueID,
            deliveryTag: Scaffolding.endOfQueueDeliveryTag
        ))
    }
}

private enum Scaffolding {

    static func makeEventEnvelope(id: UUID = UUID()) -> UpdateEventEnvelope {
        UpdateEventEnvelope(
            id: id,
            events: [
                .conversation(.proteusMessageAdd(proteusMessageAddEvent))
            ],
            isTransient: false,
            deliveryTag: 1
        )
    }

    static let envelope1 = UpdateEventEnvelope(
        id: UUID(uuidString: "66c7731b-9985-4b5e-90d7-b8f8ce1cadb9")!,
        events: [
            .conversation(.proteusMessageAdd(proteusMessageAddEvent)),
            .conversation(.protocolUpdate(protocolUpdateEvent))
        ],
        isTransient: false,
        deliveryTag: 1
    )

    static let envelope2 = UpdateEventEnvelope(
        id: UUID(uuidString: "7b406b6e-df92-4844-b20b-2e673ca2d027")!,
        events: [
            .conversation(.receiptModeUpdate(receiptModeUpdateEvent)),
            .conversation(.rename(renameEvent))
        ],
        isTransient: false,
        deliveryTag: 2
    )

    static let envelope3 = UpdateEventEnvelope(
        id: UUID(uuidString: "eb660720-079c-43f3-9a80-1168638c928f")!,
        events: [
            .conversation(.typing(typingEvent)),
            .conversation(.delete(deleteEvent))
        ],
        isTransient: false,
        deliveryTag: 3
    )

    static func fractionalDate(from string: String) -> Date {
        ISO8601DateFormatter.fractionalInternetDateTime.date(from: string)!
    }

    static func date(from string: String) -> Date {
        ISO8601DateFormatter.internetDateTime.date(from: string)!
    }

    static let conversationID = ConversationID(
        id: UUID(uuidString: "a644fa88-2d83-406b-8a85-d4fd8dedad6b")!,
        domain: "example.com"
    )

    static let senderID = UserID(
        id: UUID(uuidString: "f55fe9b0-a0cc-4b11-944b-125c834d9b6a")!,
        domain: "example.com"
    )

    static let timestamp = fractionalDate(from: "2024-06-04T15:03:07.598Z")

    static let proteusMessageAddEvent = ConversationProteusMessageAddEvent(
        conversationID: conversationID,
        senderID: senderID,
        timestamp: timestamp,
        message: .init(encryptedMessage: "foo"),
        externalData: .init(encryptedMessage: "bar"),
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
        newReceiptMode: 1
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

    static let endOfQueueID = "78417f78-b513-4c3d-95ce-37166ff12eec"
    static let endOfQueueDeliveryTag: UInt64 = 4

}

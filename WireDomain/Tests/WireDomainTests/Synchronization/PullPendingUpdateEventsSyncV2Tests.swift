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

import Combine
import GenericMessageProtocol
import WireDataModelSupport
import WireDomainSupport
import WireNetwork
import WireNetworkSupport
import XCTest

@testable import WireDomain

class PullPendingUpdateEventsSyncV2Tests: XCTestCase {

    var sut: PullPendingUpdateEventsSyncV2!
    var pushChannelAPI: MockPushChannelV2API!
    var decryptor: MockUpdateEventDecryptorProtocol!
    var updateEventsStore: MockUpdateEventsLocalStoreProtocol!
    var messageLocalStore: MockMessageLocalStoreProtocol!
    var processor: MockUpdateEventProcessorProtocol!
    var databaseSaver: MockDatabaseSaverProtocol!
    var journal: Journal!
    var coreCryptoContext: MockCoreCryptoContextProtocol!
    var coreCryptoProvider: MockCoreCryptoProviderProtocol!
    var coreCrypto: MockCoreCryptoProtocol!

    override func setUp() {
        pushChannelAPI = MockPushChannelV2API()
        decryptor = MockUpdateEventDecryptorProtocol()
        updateEventsStore = MockUpdateEventsLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        processor = MockUpdateEventProcessorProtocol()
        coreCryptoProvider = MockCoreCryptoProviderProtocol()
        coreCryptoContext = MockCoreCryptoContextProtocol()
        coreCrypto = MockCoreCryptoProtocol()
        coreCrypto.mockTransaction(context: coreCryptoContext)

        journal = Journal(
            userID: UUID(),
            storage: UserDefaults.temporary()
        )
        sut = PullPendingUpdateEventsSyncV2(
            selfClientID: Scaffolding.selfClientID,
            pushChannelAPI: pushChannelAPI,
            updateEventsStore: updateEventsStore,
            journal: journal,
            decryptor: decryptor,
            coreCryptoProvider: coreCryptoProvider,
            syncMarkerGenerator: { Scaffolding.markerID }
        )

        // Setup mocks
        coreCryptoProvider.coreCrypto_MockValue = coreCrypto
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ in
            EventDecryptorResult(events: envelope.events, brokenMLSGroupIDs: [Scaffolding.mlsGroupID])
        }

        var indices = [Int64(10), 11, 12, 13, 14, 15]
        updateEventsStore.indexOfLastEventEnvelope_MockMethod = { indices.remove(at: 0) }
        updateEventsStore.persistEventEnvelopeIndex_MockMethod = { _, _ async throws in }
    }

    override func tearDown() {
        sut = nil
        pushChannelAPI = nil
        decryptor = nil
        updateEventsStore = nil
        processor = nil
        databaseSaver = nil
        coreCryptoProvider = nil
        coreCrypto = nil
        coreCryptoContext = nil
        journal = nil
    }

    private func setupPushChannel(stream: AsyncThrowingStream<PushChannelV2.Element, any Error>)
        -> MockPushChannelV2Protocol {
        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()
        pushChannel.close_MockMethod = {}
        pushChannel.open_MockValue = stream
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannelAPI.createPushChannelClientIDMarker_MockMethod = { _, _ in
            pushChannel
        }
        return pushChannel
    }

    func testPull_receiving_no_events() async throws {
        let nbEventsToPull = 0
        let nbOfBatches = 0

        let upstream = AsyncThrowingStream { continuation in
            continuation.yield(PushChannelV2.Element.syncMarker(
                id: Scaffolding.markerID,
                deliveryTag: Scaffolding.markerDeliveryTag
            ))
        }
        try await internalTestPull(
            stream: upstream,
            receivedEventsCount: nbEventsToPull,
            decryptionCount: nbEventsToPull,
            storedEventsCount: nbEventsToPull,
            acknowledgementCount: nbOfBatches + 1
        )
    }

    func testPull_receiving_events() async throws {
        let nbEventsToPull = 5
        let nbOfBatches = 3

        let upstream = AsyncThrowingStream { continuation in
            continuation.yield(PushChannelV2.Element.events([Scaffolding.event2, Scaffolding.event3]))
            continuation.yield(PushChannelV2.Element.events([Scaffolding.event4, Scaffolding.event5]))
            continuation.yield(PushChannelV2.Element.events([Scaffolding.createEvent(
                message: "test",
                timeIntervalSinceNow: -5,
                deliveryTag: 6
            )]))
            continuation.yield(PushChannelV2.Element.syncMarker(
                id: Scaffolding.markerID,
                deliveryTag: Scaffolding.markerDeliveryTag
            ))
            continuation.finish()
        }

        try await internalTestPull(
            stream: upstream,
            receivedEventsCount: nbEventsToPull,
            decryptionCount: nbEventsToPull,
            storedEventsCount: nbEventsToPull,
            acknowledgementCount: nbOfBatches + 1
        )
    }

    func testPull_skipsSyncMarkerIfInterrupted() async throws {
        let nbEventsToPull = 5
        let nbOfBatches = 4

        let upstream = AsyncThrowingStream { continuation in
            continuation.yield(PushChannelV2.Element.events([Scaffolding.event2, Scaffolding.event3]))
            continuation.yield(PushChannelV2.Element.syncMarker(
                id: "ignored marker",
                deliveryTag: 3
            ))
            continuation.yield(PushChannelV2.Element.events([Scaffolding.event4, Scaffolding.event5]))
            continuation.yield(PushChannelV2.Element.events([Scaffolding.createEvent(
                message: "test",
                timeIntervalSinceNow: -5,
                deliveryTag: 6
            )]))
            continuation.yield(PushChannelV2.Element.syncMarker(
                id: Scaffolding.markerID,
                deliveryTag: Scaffolding.markerDeliveryTag
            ))
            continuation.finish()
        }

        let pushChannel = try await internalTestPull(
            stream: upstream,
            receivedEventsCount: nbEventsToPull,
            decryptionCount: nbEventsToPull,
            storedEventsCount: nbEventsToPull,
            acknowledgementCount: nbOfBatches + 1
        )

        // verify acknowledgement of synchronisation marker
        XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations[1].multiple == false)
        XCTAssertTrue(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations[4].multiple == false)
    }

    func testPull_missedEvents() async throws {

        let upstream = AsyncThrowingStream { continuation in
            continuation.yield(PushChannelV2.Element.events([Scaffolding.event2]))
            continuation.yield(PushChannelV2.Element.missedEvents)
            continuation.yield(PushChannelV2.Element.events([Scaffolding.event3]))
        }

        let pushChannel = try await internalTestPull(
            stream: upstream,
            receivedEventsCount: 1,
            decryptionCount: 1,
            storedEventsCount: 1,
            acknowledgementCount: 1
        )

        // the missedEvents should break the stream and not process the last event
        // in reality the event3 will never come before you ack the fullsync
        // ack the fullsync will be done in main app

        XCTAssertEqual(pushChannel.acknowledgeFullSync_Invocations.count, 0)
    }

    @discardableResult
    func internalTestPull(
        stream: AsyncThrowingStream<PushChannelV2.Element, any Error>,
        receivedEventsCount: Int,
        decryptionCount: Int,
        storedEventsCount: Int,
        acknowledgementCount: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> MockPushChannelV2Protocol {
        let pushChannel = setupPushChannel(stream: stream)

        try await sut.pull()

        var receivedEvents: [[UpdateEvent]] = []
        for try await element in sut.stream {
            receivedEvents.append(element)
        }

        // check decryption of events
        XCTAssertEqual(receivedEvents.count, receivedEventsCount, file: file, line: line)
        try XCTAssertCount(
            decryptor.decryptEventsInContext_Invocations,
            count: decryptionCount,
            "decryptionCount mismatch",
            file: file,
            line: line
        )
        // check events stored
        try XCTAssertCount(
            updateEventsStore.indexOfLastEventEnvelope_Invocations,
            count: storedEventsCount,
            "lastEventEnvelopeCount mismatch",
            file: file,
            line: line
        )
        try XCTAssertCount(
            updateEventsStore.persistEventEnvelopeIndex_Invocations,
            count: storedEventsCount,
            "storedEventsCount mismatch",
            file: file,
            line: line
        )

        // check events ack
        try XCTAssertCount(
            pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations,
            count: acknowledgementCount,
            "acknowledgementCount mismatch",
            file: file,
            line: line
        )

        return pushChannel
    }
}

private enum Scaffolding {

    static let selfClientID: String = .randomClientIdentifier()
    static let mlsGroupID = "ASDF"

    static let event2 = createEvent(
        message: "ciao",
        timeIntervalSinceNow: -9,
        deliveryTag: 2
    )

    static let event3 = createEvent(
        message: "hola",
        timeIntervalSinceNow: -8,
        deliveryTag: 3
    )

    static let event4 = createEvent(
        message: "hallo",
        timeIntervalSinceNow: -7,
        deliveryTag: 4
    )

    static let event5 = createEvent(
        message: "bonjour",
        timeIntervalSinceNow: -6,
        deliveryTag: 5
    )

    static func createEvent(
        message: String,
        timeIntervalSinceNow: TimeInterval,
        deliveryTag: UInt64? = nil
    ) -> UpdateEventEnvelope {
        let event = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(
                id: UUID(),
                domain: "example.com"
            ),
            senderID: UserID(
                id: UUID(),
                domain: "example.com"
            ),
            timestamp: Date(timeIntervalSinceNow: timeIntervalSinceNow),
            message: MessageContent(
                encryptedMessage: message,
                decryptedMessage: nil
            ),
            externalData: nil,
            messageSenderClientID: "senderClientID",
            messageRecipientClientID: selfClientID
        )
        return UpdateEventEnvelope(
            id: UUID(),
            events: [.conversation(.proteusMessageAdd(event))],
            isTransient: false,
            deliveryTag: deliveryTag
        )
    }

    static let markerID = "marker-id"
    static let markerDeliveryTag: UInt64 = 123

}

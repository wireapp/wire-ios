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
import XCTest
@testable import WireDomain
import WireDomainSupport
import WireNetworkSupport
import WireNetwork
import WireDataModelSupport
import WireProtos
import Combine

class PullPendingUpdateEventsSyncV2Tests: XCTestCase {
    
    var sut: PullPendingUpdateEventsSyncV2!
    var pushChannelAPI: MockPushChannelV2API!
    var decryptor: MockUpdateEventDecryptorProtocol!
    var updateEventsStore: MockUpdateEventsLocalStoreProtocol!
    var messageLocalStore: MockMessageLocalStoreProtocol!
    var processor: MockUpdateEventProcessorProtocol!
    var databaseSaver: MockDatabaseSaverProtocol!
    var journal: Journal!
    var coreCryptoProvider: MockCoreCryptoProviderProtocol!

    override func setUp() {
        pushChannelAPI = MockPushChannelV2API()
        decryptor = MockUpdateEventDecryptorProtocol()
        updateEventsStore = MockUpdateEventsLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        processor = MockUpdateEventProcessorProtocol()
        coreCryptoProvider = MockCoreCryptoProviderProtocol()
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
            coreCryptoProvider: coreCryptoProvider
        )
        
        
        decryptor.decryptEventsInContext_MockMethod = { envelope, _ async throws in .init(
            events: envelope.events,
            brokenMLSGroupIDs: []
        ) }
        
        
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
        journal = nil
    }

    private func setupPushChannel(stream: AsyncThrowingStream<PushChannelV2.Element, any Error>) -> MockPushChannelV2Protocol {
        // Some live events, some of which were already pulled.
        let pushChannel = MockPushChannelV2Protocol()
        pushChannel.acknowledgeMessageCount_MockMethod = {}
        pushChannel.close_MockMethod = {}
        pushChannel.open_MockValue = stream
        pushChannel.acknowledgeEventDeliveryTagMultiple_MockMethod = { _, _ in }
        pushChannelAPI.createPushChannelClientID_MockMethod = { _ in pushChannel }
        return pushChannel
    }
    
    
    func test_pull_receiving_no_events() async throws {
        let upstream = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(PushChannelV2.Element.syncing(eventsCount: 0))
                continuation.yield(PushChannelV2.Element.upToDate)
            }
        }
        let pushChannel = setupPushChannel(stream: upstream)
        
        
        try await sut.pull()

        var receivedEvents: [[UpdateEvent]] = []
        for try await element in sut.stream {
            receivedEvents.append(element)
        }

        try XCTAssertCount(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations, count: 0)
        try XCTAssertCount(receivedEvents, count: 0)
    }
    
    func test_pull_receiving_events() async throws {
        let nbEventsToPull: Int = 1
        
        let upstream = AsyncThrowingStream { continuation in
            Task {
                continuation.yield(PushChannelV2.Element.syncing(eventsCount: nbEventsToPull))
                continuation.yield(PushChannelV2.Element.event(Scaffolding.event2))
                continuation.yield(PushChannelV2.Element.upToDate)
                continuation.finish()
            }
        }
        let pushChannel = setupPushChannel(stream: upstream)
        
        
        try await sut.pull()
        
        var receivedEvents: [[UpdateEvent]] = []
        for try await element in sut.stream {
            receivedEvents.append(element)
        }

        
        try XCTAssertCount(updateEventsStore.indexOfLastEventEnvelope_Invocations, count: nbEventsToPull)
        try XCTAssertCount(updateEventsStore.persistEventEnvelopeIndex_Invocations, count: nbEventsToPull)
        try XCTAssertCount(pushChannel.acknowledgeEventDeliveryTagMultiple_Invocations, count: 1)
        XCTAssertEqual(receivedEvents.count, 1)
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
                uuid: UUID(),
                domain: "example.com"
            ),
            senderID: UserID(
                uuid: UUID(),
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

}

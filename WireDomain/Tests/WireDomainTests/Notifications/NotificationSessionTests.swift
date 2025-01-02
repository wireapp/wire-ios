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

import WireAPISupport
import XCTest
import WireDataModel
import WireDataModelSupport
@testable import WireAPI
@testable import WireDomain
@testable import WireDomainSupport

final class NotificationSessionTests: XCTestCase {
    private var sut: NotificationSession!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userRepository: MockUserRepositoryProtocol!
    
    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }
    
    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userRepository = MockUserRepositoryProtocol()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()
        registerDependencies()
    }
    
    override func tearDown() async throws {
        stack = nil
        sut = nil
        conversationLocalStore = nil
        userRepository = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }
    
    private func registerDependencies() {
        Injector.register(ConversationLocalStoreProtocol.self) {
            self.conversationLocalStore
        }
        
        Injector.register(UserRepositoryProtocol.self) {
            self.userRepository
        }
    }

    func testNotificationSession_It_Triggers_Callback_When_Pulling_Pending_Events() async throws {
        
        // Given

        let expectation = XCTestExpectation()
        var count = 0

        let updateEventsAPI = MockUpdateEventsAPI()
        updateEventsAPI.getUpdateEventsSelfClientIDSinceEventID_MockValue = .init(fetchPage: { _ in
            if count < 3 {
                count += 1
            }

            // 3 events batches
            return .init(
                element: [Scaffolding.updateEventEnvelope],
                hasMore: count < 3,
                nextStart: .init()
            )
        })

        let updateEventDecryptor = MockUpdateEventDecryptorProtocol()
        updateEventDecryptor.decryptEventsIn_MockValue = [
            Scaffolding.mlsMessageUpdateEvent,
            Scaffolding.proteusMessageUpdateEvent
        ]

        let updateEventsLocalStore = MockUpdateEventsLocalStoreProtocol()
        updateEventsLocalStore.lastEventID_MockValue = .mockID1
        updateEventsLocalStore.indexOfLastEventEnvelope_MockValue = 1
        updateEventsLocalStore.persistEventEnvelopeIndex_MockMethod = { _, _ in }
        updateEventsLocalStore.storeLastEventIDId_MockMethod = { _ in }
        userRepository.isSelfUserIdDomain_MockValue = false
        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = await context.perform({ [self] in
            modelHelper.createGroupConversation(in: context)
        })
        conversationLocalStore.conversationMutedMessageTypesIncludingAvailability_MockValue = .some(.none)
        conversationLocalStore.lastReadServerTimestamp_MockValue = .now

        let updateEventsRepository = UpdateEventsRepository(
            userID: .mockID1,
            selfClientID: UUID.mockID2.uuidString,
            updateEventsAPI: updateEventsAPI,
            pushChannel: MockPushChannelProtocol(),
            updateEventDecryptor: updateEventDecryptor,
            updateEventsLocalStore: updateEventsLocalStore
        )

        sut = NotificationSession(
            updateEventsRepository: updateEventsRepository,
            onNotificationContent: { notification in
                // Then, all 3 events batches have been received
                expectation.fulfill()
            }
        )

        // When

        try await updateEventsRepository.pullPendingEvents()

        await fulfillment(of: [expectation])

    }

    enum Scaffolding {
        static let updateEventEnvelope = UpdateEventEnvelope(
            id: .mockID1,
            events: [mlsMessageUpdateEvent, proteusMessageUpdateEvent],
            isTransient: false
        )

        static let mlsMessageUpdateEvent: UpdateEvent = .conversation(.mlsMessageAdd(mlsMessageAddEvent))

        static let proteusMessageUpdateEvent: UpdateEvent = .conversation(.proteusMessageAdd(proteusMessageAddEvent))

        static let mlsMessageAddEvent = ConversationMLSMessageAddEvent(
            conversationID: ConversationID(uuid: .mockID1, domain: ""),
            senderID: UserID(uuid: .mockID2, domain: ""),
            subconversation: "subconversation",
            message: "message",
            timestamp: .now
        )
        static let proteusMessageAddEvent = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(uuid: .mockID1, domain: ""),
            senderID: UserID(uuid: .mockID2, domain: ""),
            timestamp: .now,
            message: .init(encryptedMessage: "foo"),
            externalData: .init(encryptedMessage: "bar"),
            messageSenderClientID: "abc123",
            messageRecipientClientID: "def456"
        )
    }
}

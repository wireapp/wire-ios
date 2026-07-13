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

import GenericMessageProtocol
import WireDataModel
import WireDataModelSupport
import WireNetwork
import WireTestingPackage
import XCTest
@testable import WireDomain
@testable import WireDomainSupport

final class ProcessCallingEventsUseCaseTests: XCTestCase {

    private var sut: ProcessCallingEventsUseCase!
    private var callingService: MockAVSCallingEventService!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var coordinator: CallKitReportingCoordinator!

    override func setUp() async throws {
        callingService = MockAVSCallingEventService()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        coordinator = CallKitReportingCoordinator(
            accountID: .mockID1,
            avsService: callingService
        )
        sut = ProcessCallingEventsUseCase(
            callingService: callingService,
            clientID: "client-1",
            conversationLocalStore: conversationLocalStore,
            userLocalStore: userLocalStore,
            isFederationEnabled: false,
            accountID: .mockID1
        )
    }

    override func tearDown() async throws {
        sut = nil
        callingService = nil
        conversationLocalStore = nil
        userLocalStore = nil
        coordinator = nil
    }

    // MARK: - Tests

    func test_invoke_withEmptyBatches_callsStartAndEnd() async throws {
        // When
        try await sut.invoke(eventBatches: [], callKitReportingCoordinator: coordinator)

        // Then
        XCTAssertEqual(callingService.startCallCount, 1)
        XCTAssertEqual(callingService.endCallCount, 1)
        XCTAssertTrue(callingService.processInvocations.isEmpty)
    }

    func test_invoke_withCallingEvent_callsStartProcessAndEnd() async throws {
        // Given
        let coreDataStackHelper = CoreDataStackHelper()
        let stack = try await coreDataStackHelper.createStack()
        defer { try? coreDataStackHelper.cleanupDirectory() }

        let context = stack.syncContext
        let (conversation, selfUser, caller) = await context.perform {
            let modelHelper = ModelHelper()
            let conversation = modelHelper.createGroupConversation(in: context)
            let selfUser = modelHelper.createSelfUser(in: context)
            let caller = modelHelper.createUser(in: context)
            return (conversation, selfUser, caller)
        }

        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.isGroupConversation_MockValue = true
        conversationLocalStore.nameFor_MockValue = "Group Chat"
        userLocalStore.fetchSelfUser_MockValue = selfUser
        userLocalStore.fetchOrCreateUserIdDomain_MockValue = caller
        userLocalStore.nameFor_MockValue = .some("Caller Name")
        userLocalStore.teamNameFor_MockValue = .some(nil)

        let callingMessage = GenericMessage(
            content: Calling(content: "{}", conversationId: .init(uuid: .mockID2, domain: "example.com")),
            nonce: .mockID3
        )
        let callingData = (try callingMessage.serializedData()).base64EncodedString()
        let event = ConversationProteusMessageAddEvent(
            conversationID: ConversationID(id: .mockID2, domain: "example.com"),
            senderID: UserID(id: .mockID4, domain: "example.com"),
            timestamp: .now,
            message: MessageContent(encryptedMessage: "encrypted", decryptedMessage: callingData),
            externalData: nil,
            messageSenderClientID: "client-sender",
            messageRecipientClientID: "client-1"
        )

        // When
        try await sut.invoke(
            eventBatches: [[.conversation(.proteusMessageAdd(event))]],
            callKitReportingCoordinator: coordinator
        )

        // Then
        XCTAssertEqual(callingService.startCallCount, 1)
        XCTAssertEqual(callingService.processInvocations.count, 1)
        XCTAssertEqual(callingService.endCallCount, 1)
    }

    func test_invoke_throwsCancellationError_whenTaskIsCancelled() async throws {
        // Given
        let task = Task {
            try await self.sut.invoke(
                eventBatches: [[], [], []],
                callKitReportingCoordinator: self.coordinator
            )
        }

        // When
        task.cancel()

        // Then
        do {
            try await task.value
            XCTFail("Expected CancellationError")
        } catch is CancellationError {
            // Expected
        }
    }
}

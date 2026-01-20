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

import WireDataModel
import WireDataModelSupport
import WireTestingPackage
import XCTest

@testable import WireDomain
@testable import WireDomainSupport
@testable import WireNetwork

final class ConversationEventNotificationBuilderValidatorTests: XCTestCase {
    private var sut: ConversationEventNotificationBuilder.Validator!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var userLocalStore: MockUserLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!

    private var stack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        stack.syncContext
    }

    override func setUp() async throws {
        conversationLocalStore = MockConversationLocalStoreProtocol()
        userLocalStore = MockUserLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        stack = try await coreDataStackHelper.createStack()

        sut = ConversationEventNotificationBuilder.Validator(
            userLocalStore: userLocalStore,
            conversationLocalStore: conversationLocalStore,
            messageLocalStore: messageLocalStore
        )
    }

    override func tearDown() async throws {
        stack = nil
        sut = nil
        conversationLocalStore = nil
        userLocalStore = nil
        messageLocalStore = nil
        try coreDataStackHelper.cleanupDirectory()
        modelHelper = nil
        coreDataStackHelper = nil
    }

    // MARK: - Self user

    func test_validate_RejectsSelfUserEventsInGroupConversation() async {
        // Given
        await setupMocks(
            isSenderSelfUser: true,
            isSelfConversation: false
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: Date()
        )

        // Then
        XCTAssertFalse(result)
    }

    func test_validate_AcceptsSelfUserEventsInSelfConversation() async {
        // Given
        await setupMocks(
            isSenderSelfUser: true,
            isSelfConversation: true
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: Date()
        )

        // Then
        XCTAssertTrue(result)
    }

    func test_validate_AcceptsOtherUserEventsInGroupConversation() async {
        // Given
        await setupMocks(
            isSenderSelfUser: false,
            isSelfConversation: false
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: Date()
        )

        // Then
        XCTAssertTrue(result)
    }

    func test_validate_AcceptsOtherUserEventsInSelfConversation() async {
        // Given
        await setupMocks(
            isSenderSelfUser: false,
            isSelfConversation: true
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: Date()
        )

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Muted conversation

    func test_validate_RejectsMutedGroupConversation() async {
        // Given
        await setupMocks(
            isConversationMuted: true
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: Date()
        )

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Last read

    func test_validate_RejectsAlreadyReadEvents() async {
        // Given
        let eventTime = Date(timeIntervalSince1970: 1000)
        let lastReadTime = Date(timeIntervalSince1970: 2000)

        await setupMocks(
            lastReadTimestamp: lastReadTime
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: eventTime
        )

        // Then
        XCTAssertFalse(result)
    }

    func test_validate_AcceptsUnreadEvents() async {
        // Given
        let eventTime = Date(timeIntervalSince1970: 2000)
        let lastReadTime = Date(timeIntervalSince1970: 1000)

        await setupMocks(
            lastReadTimestamp: lastReadTime
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: eventTime
        )

        // Then
        XCTAssertTrue(result)
    }

    func test_validate_AcceptsEventsAtSameTimeAsLastRead() async {
        // Given
        let eventTime = Date(timeIntervalSince1970: 1000)
        let lastReadTime = Date(timeIntervalSince1970: 1000)

        await setupMocks(
            lastReadTimestamp: lastReadTime
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: eventTime
        )

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - Other

    func test_validate_AcceptsEventsWithNoTimestamp() async {
        // Given
        await setupMocks()

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: nil
        )

        // Then
        XCTAssertTrue(result)
    }

    func test_validate_AcceptsEventsWithNoLastReadTimestamp() async {
        // Given
        await setupMocks(
            lastReadTimestamp: nil
        )

        // When
        let result = await sut.validate(
            conversationID: Scaffolding.qualifiedID,
            senderID: Scaffolding.qualifiedID,
            time: Date()
        )

        // Then
        XCTAssertTrue(result)
    }

    // MARK: - Helper Methods

    private func setupMocks(
        isSenderSelfUser: Bool = false,
        isSelfConversation: Bool = false,
        isConversationMuted: Bool = false,
        lastReadTimestamp: Date? = Date()
    ) async {
        let conversation = await context.perform { [modelHelper, context] in
            modelHelper.createGroupConversation(in: context)
        }
        let selfUser = await context.perform { [modelHelper, context] in
            modelHelper.createSelfUser(in: context)
        }
        conversationLocalStore.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationLocalStore.conversationMutedMessageTypesIncludingAvailability_MockMethod = { _ in
            isConversationMuted ? .all : .none
        }
        userLocalStore.isSelfUserIdDomain_MockMethod = { _, _ in
            (selfUser, isSenderSelfUser)
        }
        conversationLocalStore.isSelfConversation_MockMethod = { _ in isSelfConversation }
        conversationLocalStore.lastReadServerTimestamp_MockMethod = { _ in
            lastReadTimestamp
        }
    }

    private enum Scaffolding {
        static let qualifiedID = WireNetwork.QualifiedID(id: .mockID2, domain: "domain.com")
    }
}

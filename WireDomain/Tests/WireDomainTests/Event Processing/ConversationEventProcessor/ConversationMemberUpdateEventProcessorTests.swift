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
import WireDomainSupport
import XCTest
@testable import WireDomain
@testable import WireNetwork

final class ConversationMemberUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationMemberUpdateEventProcessor!
    private var conversationRepository: MockConversationRepositoryProtocol!
    private var userRepository: MockUserRepositoryProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
    private var messageLocalStore: MockMessageLocalStoreProtocol!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var modelHelper: ModelHelper!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        modelHelper = ModelHelper()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        conversationRepository = MockConversationRepositoryProtocol()
        userRepository = MockUserRepositoryProtocol()
        conversationLocalStore = MockConversationLocalStoreProtocol()
        messageLocalStore = MockMessageLocalStoreProtocol()

        sut = ConversationMemberUpdateEventProcessor(
            conversationRepository: conversationRepository,
            userRepository: userRepository,
            localStore: conversationLocalStore,
            messageLocalStore: messageLocalStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelHelper = nil
        conversationRepository = nil
        userRepository = nil
        conversationLocalStore = nil
        messageLocalStore = nil
        sut = nil
        coreDataStack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_WhenSelfUserPromotedToAdmin_AddsSystemMessage() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        userRepository.isSelfUserIdDomain_MockMethod = { _, _ in true }
        conversationRepository.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationRepository
            .addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_MockMethod =
            { _, _, _, _, _ in }
        conversationLocalStore.updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_MockMethod = { _, _, _ in }
        messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_MockMethod = { _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.adminPromotionEvent)

        // Then

        XCTAssertEqual(
            messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations.count,
            1
        )
        let invocation = try XCTUnwrap(
            messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations.first
        )
        guard case .promotedToGroupAdmin = invocation.messageType else {
            return XCTFail("Expected .promotedToGroupAdmin message type")
        }
    }

    func testProcessEvent_WhenOtherUserPromotedToAdmin_DoesNotAddSystemMessage() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        userRepository.isSelfUserIdDomain_MockMethod = { _, _ in false }
        conversationRepository.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationRepository
            .addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_MockMethod =
            { _, _, _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.adminPromotionEvent)

        // Then

        XCTAssertEqual(
            messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations.count,
            0
        )
    }

    func testProcessEvent_WhenSelfUserChangedToMember_DoesNotAddSystemMessage() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        userRepository.isSelfUserIdDomain_MockMethod = { _, _ in true }
        conversationRepository.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationRepository
            .addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_MockMethod =
            { _, _, _, _, _ in }
        conversationLocalStore.updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_MockMethod = { _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.memberRoleEvent)

        // Then

        XCTAssertEqual(
            messageLocalStore.addSystemMessageMessageTypeConversationIDConversationDomain_Invocations.count,
            0
        )
    }

    func testProcessEvent_It_Invokes_Repo_And_Local_Store_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        userRepository.isSelfUserIdDomain_MockMethod = { _, _ in true }
        conversationRepository.fetchOrCreateConversationIdDomain_MockValue = conversation
        conversationRepository
            .addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_MockMethod =
            { _, _, _, _, _ in }
        conversationLocalStore.updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_MockMethod = { _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(userRepository.isSelfUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.fetchOrCreateConversationIdDomain_Invocations.count, 1)
        XCTAssertEqual(
            conversationRepository
                .addOrUpdateParticipantParticipantIDParticipantDomainParticipantRoleConversationIDConversationDomain_Invocations
                .count,
            1
        )
        XCTAssertEqual(
            conversationLocalStore.updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_Invocations.count,
            1
        )
    }

    private enum Scaffolding {
        static let domain = "domain.com"

        static let event = ConversationMemberUpdateEvent(
            conversationID: ConversationID(id: UUID(), domain: domain),
            senderID: UserID(id: UUID(), domain: domain),
            timestamp: .now,
            memberChange: .init(
                id: UserID(id: UUID(), domain: domain),
                newRoleName: "",
                newMuteStatus: nil,
                muteStatusReferenceDate: .now,
                newArchivedStatus: true,
                archivedStatusReferenceDate: .now
            )
        )

        static let adminPromotionEvent = ConversationMemberUpdateEvent(
            conversationID: ConversationID(id: UUID(), domain: domain),
            senderID: UserID(id: UUID(), domain: domain),
            timestamp: .now,
            memberChange: .init(
                id: UserID(id: UUID(), domain: domain),
                newRoleName: ZMConversation.defaultAdminRoleName,
                newMuteStatus: nil,
                muteStatusReferenceDate: .now,
                newArchivedStatus: false,
                archivedStatusReferenceDate: .now
            )
        )

        static let memberRoleEvent = ConversationMemberUpdateEvent(
            conversationID: ConversationID(id: UUID(), domain: domain),
            senderID: UserID(id: UUID(), domain: domain),
            timestamp: .now,
            memberChange: .init(
                id: UserID(id: UUID(), domain: domain),
                newRoleName: ZMConversation.defaultMemberRoleName,
                newMuteStatus: nil,
                muteStatusReferenceDate: .now,
                newArchivedStatus: false,
                archivedStatusReferenceDate: .now
            )
        )
    }
}

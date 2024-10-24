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

@testable import WireAPI
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import WireDomainSupport
import XCTest

final class ConversationMemberUpdateEventProcessorTests: XCTestCase {

    private var sut: ConversationMemberUpdateEventProcessor!
    private var conversationRepository: MockConversationRepositoryProtocol!
    private var userRepository: MockUserRepositoryProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!
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

        sut = ConversationMemberUpdateEventProcessor(
            conversationRepository: conversationRepository,
            userRepository: userRepository,
            localStore: conversationLocalStore
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelHelper = nil
        conversationRepository = nil
        userRepository = nil
        conversationLocalStore = nil
        sut = nil
        coreDataStack = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Invokes_Repo_And_Local_Store_Methods() async throws {
        // Mock

        let conversation = await context.perform { [self] in
            modelHelper.createGroupConversation(in: context)
        }

        userRepository.isSelfUserIdDomain_MockMethod = { _, _ in true }
        conversationRepository.fetchOrCreateConversationWithDomain_MockValue = conversation
        conversationRepository.addParticipantToConversationConversationIDConversationDomainParticipantIDParticipantDomainParticipantRole_MockMethod = { _, _, _, _, _ in }
        conversationLocalStore.updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_MockMethod = { _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(userRepository.isSelfUserIdDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.fetchOrCreateConversationWithDomain_Invocations.count, 1)
        XCTAssertEqual(conversationRepository.addParticipantToConversationConversationIDConversationDomainParticipantIDParticipantDomainParticipantRole_Invocations.count, 1)
        XCTAssertEqual(conversationLocalStore.updateMemberStatusMutedStatusInfoArchivedStatusInfoFor_Invocations.count, 1)
    }

    private enum Scaffolding {
        static let event = ConversationMemberUpdateEvent(
            conversationID: ConversationID(uuid: UUID(), domain: "domain.com"),
            senderID: UserID(uuid: UUID(), domain: "domain.com"),
            timestamp: .now,
            memberChange: .init(
                id: UserID(uuid: UUID(), domain: "domain.com"),
                newRoleName: "",
                newMuteStatus: nil,
                muteStatusReferenceDate: .now,
                newArchivedStatus: true,
                archivedStatusReferenceDate: .now
            )
        )
    }
}

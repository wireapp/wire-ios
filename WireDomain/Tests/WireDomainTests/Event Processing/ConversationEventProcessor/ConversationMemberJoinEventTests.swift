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

final class ConversationMemberJoinEventProcessorTests: XCTestCase {

    private var sut: ConversationMemberJoinEventProcessor!
    private var modelHelper: ModelHelper!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!
    private var conversationRepository: MockConversationRepositoryProtocol!
    private var userRepository: MockUserRepositoryProtocol!
    private var conversationLocalStore: MockConversationLocalStoreProtocol!

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

        sut = ConversationMemberJoinEventProcessor(
            conversationRepository: conversationRepository,
            conversationLocalStore: conversationLocalStore,
            userRepository: userRepository
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        modelHelper = nil
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
        conversationRepository = nil
        userRepository = nil
        conversationLocalStore = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Adds_Participants_To_Conversation() async throws {
        // Mock

        await context.perform { [self] in
            // conversation
            modelHelper.createGroupConversation(
                id: Scaffolding.conversationID.id,
                domain: Scaffolding.conversationID.domain,
                in: context
            )

            // sender
            modelHelper.createUser(
                qualifiedID: Scaffolding.senderID.toDomainModel(),
                in: context
            )

            // addedUser
            modelHelper.createUser(
                qualifiedID: Scaffolding.memberID.toDomainModel(),
                in: context
            )
            // role
            modelHelper.createRole(in: context)
        }

        conversationRepository
            .addParticipantsSenderDateConversationIDConversationDomain_MockMethod = { _, _, _, _, _ in }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        XCTAssertEqual(
            conversationRepository.addParticipantsSenderDateConversationIDConversationDomain_Invocations.count,
            1
        )
    }

    private enum Scaffolding {
        static let domain = "domain.com"
        static let conversationID = ConversationID(id: UUID(), domain: domain)
        static let memberID = WireNetwork.QualifiedID(id: UUID(), domain: domain)
        static let senderID = UserID(id: UUID(), domain: domain)

        static let member = Conversation.Member(
            qualifiedID: memberID,
            id: memberID.id,
            qualifiedTarget: nil,
            target: nil,
            conversationRole: ZMConversation.defaultMemberRoleName,
            service: nil,
            archived: nil,
            archivedReference: nil,
            hidden: nil,
            hiddenReference: nil,
            mutedStatus: nil,
            mutedReference: nil
        )

        static let event = ConversationMemberJoinEvent(
            conversationID: conversationID,
            senderID: senderID,
            timestamp: .now,
            members: [member]
        )
    }

}

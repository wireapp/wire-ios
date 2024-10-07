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

import WireAPI
import WireDataModel
import WireDataModelSupport
@testable import WireDomain
import XCTest

final class FederationDeleteEventProcessorTests: XCTestCase {

    private var sut: FederationDeleteEventProcessor!
    private var coreDataStack: CoreDataStack!
    private var coreDataStackHelper: CoreDataStackHelper!

    private var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        try await super.setUp()
        coreDataStackHelper = CoreDataStackHelper()
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = FederationDeleteEventProcessor(
            context: context
        )
    }

    override func tearDown() async throws {
        try await super.tearDown()
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        coreDataStackHelper = nil
    }

    // MARK: - Tests

    func testProcessEvent_It_Marks_One_To_One_Conversation_As_Read_Only() async throws {
        // Given

        try await context.perform { [self] in

            let conversation = makeGroupConversation()
            let otherUser = try XCTUnwrap(ZMUser.fetch(
                with: Scaffolding.otherUserID,
                in: context
            ))

            let oneOnOneConversation = try XCTUnwrap(otherUser.oneOnOneConversation)

            XCTAssertEqual(oneOnOneConversation.isForcedReadOnly, false)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let otherUser = try XCTUnwrap(ZMUser.fetch(
                with: Scaffolding.otherUserID,
                in: context
            ))

            let oneOnOneConversation = try XCTUnwrap(otherUser.oneOnOneConversation)
            let lastMessage = try XCTUnwrap(oneOnOneConversation.lastMessage?.systemMessageData)

            XCTAssertEqual(oneOnOneConversation.isReadOnly, true)
            XCTAssertEqual(oneOnOneConversation.isForcedReadOnly, true)
            XCTAssertEqual(lastMessage.systemMessageType, .domainsStoppedFederating)
        }
    }

    func testProcessEvent_It_Removes_Pending_Connection_Request() async throws {
        // Given

        try await context.perform { [self] in
            let conversation = makeGroupConversation()

            let otherUser = try XCTUnwrap(ZMUser.fetch(
                with: Scaffolding.otherUserID,
                in: context
            ))

            otherUser.connection?.status = .pending

            XCTAssertEqual(conversation.remoteIdentifier, Scaffolding.groupConversationID)
            XCTAssertEqual(otherUser.connection?.status, .pending)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let otherUser = try XCTUnwrap(ZMUser.fetch(
                with: Scaffolding.otherUserID,
                in: context
            ))

            let otherUserConnection = try XCTUnwrap(otherUser.connection)

            XCTAssertEqual(otherUserConnection.status, .ignored)
        }
    }

    func testProcessEvent_It_Cancels_Sent_Connection_Request() async throws {
        // Given

        try await context.perform { [self] in
            let conversation = makeGroupConversation()

            let otherUser = try XCTUnwrap(ZMUser.fetch(
                with: Scaffolding.otherUserID,
                in: context
            ))

            otherUser.connection?.status = .sent

            XCTAssertEqual(conversation.remoteIdentifier, Scaffolding.groupConversationID)
            XCTAssertEqual(otherUser.connection?.status, .sent)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let otherUser = try XCTUnwrap(ZMUser.fetch(
                with: Scaffolding.otherUserID,
                in: context
            ))

            let otherUserConnection = try XCTUnwrap(otherUser.connection)

            XCTAssertEqual(otherUserConnection.status, .cancelled)
        }
    }

    func testProcessEvent_It_Removes_Connection_For_Connected_Users() async throws {
        // Given

        try await context.perform { [self] in
            let conversation = makeGroupConversation()

            let otherUser = try XCTUnwrap(ZMUser.fetch(
                with: Scaffolding.otherUserID,
                in: context
            ))

            XCTAssertEqual(conversation.remoteIdentifier, Scaffolding.groupConversationID)
            XCTAssertNotNil(otherUser.connection)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        await context.perform { [context] in
            let otherUser = ZMUser.fetchOrCreate(
                with: Scaffolding.otherUserID,
                domain: nil,
                in: context
            )

            XCTAssertEqual(otherUser.connection, nil)
        }
    }

    func testProcessEvent_It_Removes_Self_User_From_Conversation_Hosted_By_Defederated_Domains() async throws {
        // Given

        try await context.perform { [self] in

            let conversation = makeGroupConversation(
                selfUserDomain: Scaffolding.defederatedDomain
            )

            let selfUser = try XCTUnwrap(
                ZMUser.fetch(with: Scaffolding.selfUserID, in: context)
            )

            let user = try XCTUnwrap(
                ZMUser.fetch(with: Scaffolding.userID, in: context)
            )

            XCTAssertTrue(conversation.localParticipants.contains(user))
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.groupConversationID,
                    domain: Scaffolding.defederatedDomain,
                    in: context
                )
            )

            let selfUser = ZMUser.selfUser(in: context)

            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.userID,
                    in: context
                )
            )

            XCTAssertEqual(conversation.localParticipants.contains(selfUser), false)
            XCTAssertEqual(conversation.localParticipants.contains(user), true)

            let lastMessages = conversation.lastMessages(limit: 2)

            XCTAssertEqual(lastMessages.first?.systemMessageData?.systemMessageType, .participantsRemoved)
            XCTAssertEqual(lastMessages.last?.systemMessageData?.systemMessageType, .domainsStoppedFederating)
        }
    }

    func testProcessEvent_It_Removes_Other_User_From_Conversation_Hosted_By_Self_Domain() async throws {
        // Given

        try await context.perform { [self] in

            let conversation = makeGroupConversation(
                hostedByDomain: Scaffolding.firstDomain,
                selfUserDomain: Scaffolding.firstDomain,
                userDomain: Scaffolding.defederatedDomain
            )

            let selfUser = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.selfUserID,
                    in: context
                )
            )

            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.userID,
                    in: context
                )
            )

            XCTAssertTrue(conversation.localParticipants.contains(user))
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.groupConversationID,
                    domain: Scaffolding.defederatedDomain,
                    in: context
                )
            )

            let selfUser = ZMUser.selfUser(in: context)
            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.userID,
                    in: context
                )
            )

            XCTAssertEqual(conversation.localParticipants.contains(selfUser), true)
            XCTAssertEqual(conversation.localParticipants.contains(user), false)

            let lastMessages = conversation.lastMessages(limit: 2)

            XCTAssertEqual(lastMessages.first?.systemMessageData?.systemMessageType, .participantsRemoved)
            XCTAssertEqual(lastMessages.last?.systemMessageData?.systemMessageType, .domainsStoppedFederating)
        }
    }

    func testProcessEvent_It_Removes_Self_User_And_Another_User_From_Conversation_Hosted_By_Other_Domain() async throws {
        // Given

        try await context.perform { [self] in

            let conversation = makeGroupConversation(
                hostedByDomain: Scaffolding.defederatedDomain,
                selfUserDomain: Scaffolding.defederatedDomain,
                userDomain: Scaffolding.defederatedDomain,
                otherUserDomain: Scaffolding.firstDomain
            )

            let selfUser = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.selfUserID,
                    in: context
                )
            )

            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.userID,
                    in: context
                )
            )

            let otherUser = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.otherUserID,
                    in: context
                )
            )

            XCTAssertTrue(conversation.localParticipants.contains(user))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))
            XCTAssertTrue(conversation.localParticipants.contains(selfUser))
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.groupConversationID,
                    domain: Scaffolding.defederatedDomain,
                    in: context
                )
            )

            let selfUser = ZMUser.selfUser(in: context)

            let user = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.userID,
                    in: context
                )
            )

            let otherUser = try XCTUnwrap(
                ZMUser.fetch(
                    with: Scaffolding.otherUserID,
                    in: context
                )
            )

            XCTAssertFalse(conversation.localParticipants.contains(selfUser))
            XCTAssertFalse(conversation.localParticipants.contains(user))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))

            let lastMessages = conversation.lastMessages(limit: 2)

            XCTAssertEqual(lastMessages.first?.systemMessageData?.systemMessageType, .participantsRemoved)
            XCTAssertEqual(lastMessages.last?.systemMessageData?.systemMessageType, .domainsStoppedFederating)
        }
    }

    private func makeGroupConversation(
        hostedByDomain domain: String = Scaffolding.defederatedDomain,
        selfUserDomain: String = Scaffolding.firstDomain,
        userDomain: String = Scaffolding.secondDomain,
        otherUserDomain: String = Scaffolding.defederatedDomain
    ) -> ZMConversation {
        var created = false

        let selfUser = ZMUser.selfUser(in: context)
        selfUser.remoteIdentifier = Scaffolding.selfUserID
        selfUser.domain = selfUserDomain

        let user = ZMUser.fetchOrCreate(
            with: Scaffolding.userID,
            domain: nil,
            in: context
        )

        user.domain = userDomain

        let otherUser = ZMUser.fetchOrCreate(
            with: Scaffolding.otherUserID,
            domain: nil,
            in: context
        )

        otherUser.domain = otherUserDomain
        otherUser.connection = ZMConnection.insertNewObject(in: context)
        otherUser.connection?.status = .accepted

        let oneOnOneConversation = ZMConversation.fetchOrCreate(
            with: Scaffolding.oneOnOneConversationID,
            domain: nil,
            in: context
        )

        oneOnOneConversation.domain = Scaffolding.defederatedDomain
        oneOnOneConversation.conversationType = .oneOnOne
        oneOnOneConversation.remoteIdentifier = Scaffolding.oneOnOneConversationID
        oneOnOneConversation.addParticipantAndUpdateConversationState(user: otherUser, role: nil)

        otherUser.oneOnOneConversation = oneOnOneConversation

        let groupConversation = ZMConversation.fetchOrCreate(
            with: Scaffolding.groupConversationID,
            domain: domain,
            in: context,
            created: &created
        )

        groupConversation.remoteIdentifier = Scaffolding.groupConversationID
        groupConversation.conversationType = .group
        groupConversation.domain = domain

        let selfUserRole = ParticipantRole.create(
            managedObjectContext: context,
            user: selfUser,
            conversation: groupConversation
        )

        let userRole = ParticipantRole.create(
            managedObjectContext: context,
            user: user,
            conversation: groupConversation
        )

        let otherUserRole = ParticipantRole.create(
            managedObjectContext: context,
            user: otherUser,
            conversation: groupConversation
        )

        userRole.conversation = groupConversation
        otherUserRole.conversation = groupConversation
        selfUserRole.conversation = groupConversation

        user.participantRoles = [userRole]
        otherUser.participantRoles = [otherUserRole]
        selfUser.participantRoles = [selfUserRole]

        groupConversation.addParticipantsAndUpdateConversationState(
            users: [selfUser, user, otherUser]
        )

        return groupConversation
    }

    private enum Scaffolding {

        /// UUIDs
        static let selfUserID = UUID()
        static let userID = UUID()
        static let otherUserID = UUID()
        static let groupConversationID = UUID()
        static let oneOnOneConversationID = UUID()

        /// Domains
        static let firstDomain = "domain.com"
        static let secondDomain = "domain2.com"
        static let defederatedDomain = "domain3.com"

        static let event = FederationDeleteEvent(
            domain: defederatedDomain
        )

    }

}

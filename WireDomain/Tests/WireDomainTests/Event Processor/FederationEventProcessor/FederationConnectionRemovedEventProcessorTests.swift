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

import Foundation
import WireAPI
import WireAPISupport
import WireDataModel
import WireDataModelSupport
import XCTest

@testable import WireDomain

final class FederationConnectionRemovedEventProcessorTests: XCTestCase {

    var sut: FederationConnectionRemovedEventProcessor!

    var coreDataStack: CoreDataStack!
    let coreDataStackHelper = CoreDataStackHelper()
    let modelHelper = ModelHelper()
    let mockAPI = MockUsersAPI()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = FederationConnectionRemovedEventProcessor(
            repository: UserRepository(context: context, usersAPI: mockAPI)
        )
        try await super.setUp()
    }

    override func tearDown() async throws {
        coreDataStack = nil
        sut = nil
        try coreDataStackHelper.cleanupDirectory()
        try await super.tearDown()
    }

    // MARK: - Tests

    func testProcessEvent_It_Removes_Participants_From_Group_Conversations_On_Specified_Not_Hosted_Domains() async throws {
        // Given

        await context.perform { [self] in

            let conversation = makeNotHostedConversation()

            XCTAssertEqual(conversation.remoteIdentifier, Scaffolding.groupConversationID)
            XCTAssertEqual(conversation.localParticipants.count, 2)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.groupConversationID,
                    domain: Scaffolding.firstDomain,
                    in: context
                )
            )

            XCTAssertEqual(conversation.remoteIdentifier, Scaffolding.groupConversationID)
            XCTAssertEqual(conversation.localParticipants.count, 0) /// All participants were removed from the conversation with domain name "domain.com".
            XCTAssertEqual(conversation.allMessages.count, 2) /// A federation termination system message and a participant removed anonymously system message.
        }
    }

    func testProcessEvent_It_Removes_Participants_From_Group_Conversations_On_Specified_Hosted_Domains() async throws {
        // Given

        await context.perform { [self] in

            let conversation = makeHostedConversation()

            XCTAssertEqual(conversation.remoteIdentifier, Scaffolding.groupConversationID)
            XCTAssertEqual(conversation.localParticipants.count, 2)
        }

        // When

        try await sut.processEvent(Scaffolding.event)

        // Then

        try await context.perform { [context] in
            let conversation = try XCTUnwrap(
                ZMConversation.fetch(
                    with: Scaffolding.groupConversationID,
                    domain: Scaffolding.firstDomain,
                    in: context
                )
            )

            XCTAssertEqual(conversation.remoteIdentifier, Scaffolding.groupConversationID)
            XCTAssertEqual(conversation.localParticipants.count, 1) /// The user not part of the specified domain was removed from the conversation, the one remaining is part of the specified domain.
            XCTAssertEqual(conversation.allMessages.count, 2) /// A federation termination system message and a participant removed anonymously system message.
        }
    }

    /// Creates a conversation with domain "domain.com" with participants of "domain3.com" and "domain4.com",
    /// The federation event domains are "domain3.com" and "domain4.com".
    /// It enables testing that the participants are all removed from the conversation that is not hosted on these domains.
    private func makeNotHostedConversation() -> ZMConversation {
        var created = false

        let user = ZMUser.fetchOrCreate(
            with: Scaffolding.userID,
            domain: nil,
            in: context
        )

        let otherUser = ZMUser.fetchOrCreate(
            with: Scaffolding.otherUserID,
            domain: nil,
            in: context
        )

        user.domain = Scaffolding.thirdDomain
        otherUser.domain = Scaffolding.fourthDomain

        let conversation = ZMConversation.fetchOrCreate(
            with: Scaffolding.groupConversationID,
            domain: Scaffolding.firstDomain,
            in: context,
            created: &created
        )

        conversation.conversationType = .group
        conversation.domain = Scaffolding.firstDomain

        let userRole = ParticipantRole.create(
            managedObjectContext: context,
            user: user,
            conversation: conversation
        )

        let otherUserRole = ParticipantRole.create(
            managedObjectContext: context,
            user: otherUser,
            conversation: conversation
        )

        userRole.conversation = conversation
        otherUserRole.conversation = conversation

        user.participantRoles = [userRole]
        otherUser.participantRoles = [otherUserRole]

        conversation.addParticipantsAndUpdateConversationState(
            users: [user, otherUser]
        )

        return conversation
    }

    /// Creates a conversation with domain "domain4.com" with participants of "domain3.com" and "domain4.com",
    /// The federation event domains are "domain3.com" and "domain4.com".
    /// It enables testing that the participant with domain "domain3.com" is removed from the conversation that is hosted on "domain4.com"
    private func makeHostedConversation() -> ZMConversation {
        let user = ZMUser.fetchOrCreate(
            with: Scaffolding.userID,
            domain: nil,
            in: context
        )

        let otherUser = ZMUser.fetchOrCreate(
            with: Scaffolding.otherUserID,
            domain: nil,
            in: context
        )

        user.domain = Scaffolding.thirdDomain
        otherUser.domain = Scaffolding.fourthDomain

        var created = false

        let conversation = ZMConversation.fetchOrCreate(
            with: Scaffolding.groupConversationID,
            domain: Scaffolding.fourthDomain,
            in: context,
            created: &created
        )

        conversation.domain = Scaffolding.fourthDomain
        conversation.conversationType = .group

        let userRole = ParticipantRole.create(
            managedObjectContext: context,
            user: user,
            conversation: conversation
        )

        let otherUserRole = ParticipantRole.create(
            managedObjectContext: context,
            user: otherUser,
            conversation: conversation
        )

        userRole.conversation = conversation
        otherUserRole.conversation = conversation

        user.participantRoles = [userRole]
        otherUser.participantRoles = [otherUserRole]

        conversation.addParticipantsAndUpdateConversationState(
            users: [user, otherUser]
        )

        return conversation
    }

}

// MARK: - Scaffolding

private enum Scaffolding {

    static let userID = UUID()
    static let otherUserID = UUID()
    static let groupConversationID = UUID()
    static let firstDomain = "domain.com"
    static let secondDomain = "domain2.com"
    static let thirdDomain = "domain3.com"
    static let fourthDomain = "domain4.com"

    static let event = FederationConnectionRemovedEvent(
        domains: Set([thirdDomain, fourthDomain])
    )

}

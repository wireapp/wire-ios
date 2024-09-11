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
    let mockAPI = MockConnectionsAPI()

    var context: NSManagedObjectContext {
        coreDataStack.syncContext
    }

    override func setUp() async throws {
        coreDataStack = try await coreDataStackHelper.createStack()
        sut = FederationConnectionRemovedEventProcessor(
            repository: ConnectionsRepository(connectionsAPI: mockAPI, context: context)
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

    func testProcessEvent_It_Removes_Participants_From_A_Group_Conversation_That_Is_Not_Hosted_On_Specified_Domains() async throws {
        // Given

        await context.perform { [self] in

            let conversation = makeGroupConversation(hostedBy: Scaffolding.firstDomain)

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

            XCTAssertFalse(conversation.localParticipants.contains(user))
            XCTAssertFalse(conversation.localParticipants.contains(otherUser))

            let lastMessages = conversation.lastMessages(limit: 2)

            XCTAssertEqual(lastMessages.first?.systemMessageData?.systemMessageType, ZMSystemMessageType.participantsRemoved)
            XCTAssertEqual(lastMessages.last?.systemMessageData?.systemMessageType, ZMSystemMessageType.domainsStoppedFederating)
        }
    }

    func testProcessEvent_It_Removes_Participant_On_A_Domain_From_A_Group_Conversation_That_Is_Hosted_On_Another_Domain() async throws {
        // Given

        await context.perform { [self] in

            let conversation = makeGroupConversation(hostedBy: Scaffolding.thirdDomain)

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

            XCTAssertFalse(conversation.localParticipants.contains(user))
            XCTAssertTrue(conversation.localParticipants.contains(otherUser))

            let lastMessages = conversation.lastMessages(limit: 2)

            XCTAssertEqual(lastMessages.first?.systemMessageData?.systemMessageType, ZMSystemMessageType.participantsRemoved)
            XCTAssertEqual(lastMessages.last?.systemMessageData?.systemMessageType, ZMSystemMessageType.domainsStoppedFederating)
        }
    }

    private func makeGroupConversation(
        hostedBy domain: String
    ) -> ZMConversation {
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

        user.domain = Scaffolding.secondDomain
        otherUser.domain = Scaffolding.thirdDomain

        let conversation = ZMConversation.fetchOrCreate(
            with: Scaffolding.groupConversationID,
            domain: Scaffolding.firstDomain,
            in: context,
            created: &created
        )

        conversation.conversationType = .group
        conversation.domain = domain

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

    /// UUIDs

    static let userID = UUID()
    static let otherUserID = UUID()
    static let groupConversationID = UUID()

    /// Domains

    static let firstDomain = "domain.com"
    static let secondDomain = "domain2.com"
    static let thirdDomain = "domain3.com"

    static let event = FederationConnectionRemovedEvent(
        domains: Set([secondDomain, thirdDomain])
    )

}

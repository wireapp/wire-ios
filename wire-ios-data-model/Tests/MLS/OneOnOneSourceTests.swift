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

import WireDataModelSupport
import WireTesting
import XCTest

@testable import WireDataModel

private enum OneOnOneSourceTestsError: Error {
    case invalidUUID
}

final class OneOnOneSourceTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var context: NSManagedObjectContext { coreDataStack.syncContext }
    private var sut: OneOnOneSource!

    private var team: Team!
    private var selfUser: ZMUser!
    private var userA: ZMUser!
    private var userB: ZMUser!

    override func setUp() async throws{
        coreDataStack = try await CoreDataStackHelper().createStack()
        sut = OneOnOneSource(context: context)

        try await context.perform { [self] in
            // Team
            team = Team.fetchOrCreate(with: UUID(), in: context)

            // Self User
            selfUser = ZMUser.selfUser(in: context)
            selfUser.remoteIdentifier = UUID()
            selfUser.domain = nil
            selfUser.teamIdentifier = team.remoteIdentifier
            let member = Member.insertNewObject(in: context)
            member.user = selfUser
            member.team = team

            // UserA
            userA = ZMUser.fetchOrCreate(with: UUID(), domain: nil, in: context)

            // UserB
            userB = ZMUser.fetchOrCreate(with: UUID(), domain: nil, in: context)

            try context.save()
        }
    }

    override func tearDown() {
        coreDataStack = nil
        sut = nil
        team = nil
        selfUser = nil
        userA = nil
        userB = nil
    }

    // MARK: - fetchOneOnOne

    func testFetchOneOnOnes_mls() async throws {
        // Given
        let allConversations = try await createConversations([
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userA], name: nil), // <- 1:1 MLS with UserA
            .init(.group, .mls, team: nil, users: [selfUser, userA], name: nil),
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil),
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userA, userB], name: nil),
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userB], name: nil),
        ])

        try await context.perform { [self] in
            // When
            let conversations = try sut.fetchOneOnOnes(user: userA, types: [.mls])

            // Then
            XCTAssertEqual(conversations.count, 1)
            XCTAssertEqual(conversations[0], allConversations[0])
        }
    }

    func testFetchOneOnOnes_fake() async throws {
        // Given
        let otherTeam = await context.perform { [context] in
            Team.fetchOrCreate(with: UUID(), in: context)
        }

        let allConversations = try await createConversations([
            .init(.group, .proteus, team: team, users: [selfUser, userA], name: nil), // <- 1:1 proteus fake with UserA
            .init(.group, .proteus, team: otherTeam, users: [selfUser, userA], name: nil),
            .init(.oneOnOne, .proteus, team: team, users: [selfUser, userA], name: nil),
            .init(.group, .proteus, team: team, users: [selfUser, userA], name: "name"),
            .init(.group, .proteus, team: team, users: [selfUser, userA, userB], name: nil),
            .init(.group, .proteus, team: team, users: [selfUser, userB], name: nil),
            .init(.group, .proteus, team: team, users: [userB, userA], name: nil),
        ])

        try await context.perform { [self] in
            // When
            let conversations = try sut.fetchOneOnOnes(user: userA, types: [.fake])

            // Then
            XCTAssertEqual(conversations.count, 1)
            XCTAssertEqual(conversations[0], allConversations[0])
        }
    }

    // MARK: - Helpers

    private func createConversations(_ data: [ConversationData]) async throws -> [ZMConversation] {
        try await context.perform { [context] in
            let conversations = data.map { $0.create(in: context) }
            try context.save()
            return conversations
        }
    }

}

// MARK: Helpers

private struct ConversationData {
    let conversationType: ZMConversationType
    let messageProtocol: MessageProtocol
    let team: Team?
    let users: [ZMUser]
    let name: String?

    init(
        _ conversationType: ZMConversationType,
        _ messageProtocol: MessageProtocol,
        team: Team?,
        users: [ZMUser],
        name: String?
    ) {
        self.conversationType = conversationType
        self.messageProtocol = messageProtocol
        self.team = team
        self.users = users
        self.name = name
    }

    func create(in context: NSManagedObjectContext) -> ZMConversation {
        let conversation = ZMConversation(context: context)
        conversation.conversationType = conversationType
        conversation.messageProtocol = messageProtocol
        conversation.team = team
        conversation.userDefinedName = name

        for user in users {
            ParticipantRole.create(managedObjectContext: context, user: user, conversation: conversation)
        }

        return conversation
    }
}

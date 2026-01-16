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

import WireDataModelSupport
import WireTesting
import XCTest

@testable import WireDataModel

final class OneOnOneSourceTests: XCTestCase {

    private var coreDataStack: CoreDataStack!
    private var context: NSManagedObjectContext { coreDataStack.syncContext }
    private var sut: OneOnOneSource!

    private var team: Team!
    private var selfUser: ZMUser!
    private var userA: ZMUser!
    private var userB: ZMUser!

    override func setUp() async throws {
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
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userB], name: nil)
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
            .init(.group, .proteus, team: team, users: [userB, userA], name: nil)
        ])

        try await context.perform { [self] in
            // When
            let conversations = try sut.fetchOneOnOnes(user: userA, types: [.fake])

            // Then
            XCTAssertEqual(conversations.count, 1)
            XCTAssertEqual(conversations[0], allConversations[0])
        }
    }

    func testFetchOneOnOnes_proteus() async throws {
        // Given
        let allConversations = try await createConversations([
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil), // <- 1:1 proteus with UserA
            .init(.group, .proteus, team: nil, users: [selfUser, userA], name: nil),
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userA], name: nil),
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userA, userB], name: nil),
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userB], name: nil)
        ])

        try await context.perform { [self] in
            // When
            let conversations = try sut.fetchOneOnOnes(user: userA, types: [.proteus])

            // Then
            XCTAssertEqual(conversations.count, 1)
            XCTAssertEqual(conversations[0], allConversations[0])
        }
    }

    func testFetchOneOnOnes_proteusPending() async throws {
        // Given
        let allConversations = try await createConversations([
            .init(.connection, .proteus, team: nil, users: [selfUser, userA], name: nil), // <- 1:1 prot. pending UserA
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil),
            .init(.connection, .mls, team: nil, users: [selfUser, userA], name: nil),
            .init(.connection, .proteus, team: nil, users: [selfUser, userB], name: nil)
        ])

        try await context.perform { [self] in
            // When
            let conversations = try sut.fetchOneOnOnes(user: userA, types: [.proteusPending])

            // Then
            XCTAssertEqual(conversations.count, 1)
            XCTAssertEqual(conversations[0], allConversations[0])
        }
    }

    func testFetchOneOnOnes_allTypes() async throws {
        // Given all valid 1:1 conversations
        _ = try await createConversations([
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userA], name: nil), // <- 1:1 MLS with UserA
            .init(.group, .proteus, team: team, users: [selfUser, userA], name: nil), // <- 1:1 proteus fake with UserA
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil), // <- 1:1 proteus with UserA
            .init(.connection, .proteus, team: nil, users: [selfUser, userA], name: nil) // <- 1:1 prot. pending UserA
        ])

        try await context.perform { [self] in
            // When fetching all types of 1:1 conversations
            let conversations = try sut.fetchOneOnOnes(user: userA, types: [.mls, .fake, .proteus, .proteusPending])

            // Then all conversations are fetched
            XCTAssertEqual(conversations.count, 4)
        }
    }

    // MARK: - fetchOneOnOnesWithCandidate

    func testFetchOneOnOnesWithCandidate_whenNoMatchingConversations() async throws {
        // Given a 1:1 conversations with UserB
        _ = try await createConversations([
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userB], name: nil) // <- 1:1 MLS with UserB
        ])

        try await context.perform { [self] in
            // When fetching all types of 1:1 conversations with UserA
            let result = try sut.fetchOneOnOnesWithCandidate(
                user: userA,
                types: [.mls, .fake, .proteus, .proteusPending]
            )

            // Then
            XCTAssertNil(result)
        }
    }

    func testFetchOneOnOnesWithCandidate_whenConversationsOfEveryType() async throws {
        // Given a mix of all 1:1 conversation types with UserA & UserB
        let userAConversations = try await createConversations([
            // 1:1 MLS with UserA
            .init(id: UUID(suffix: "8"), .oneOnOne, .mls, team: nil, users: [selfUser, userA], name: nil),
            .init(id: UUID(suffix: "7"), .oneOnOne, .mls, team: nil, users: [selfUser, userA], name: nil),
            // 1:1 proteus fake with UserA
            .init(id: UUID(suffix: "6"), .group, .proteus, team: team, users: [selfUser, userA], name: nil),
            .init(id: UUID(suffix: "5"), .group, .proteus, team: team, users: [selfUser, userA], name: nil),
            // 1:1 proteus with UserA
            .init(id: UUID(suffix: "4"), .oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil),
            .init(id: UUID(suffix: "3"), .oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil),
            // 1:1 proteus pending UserA
            .init(id: UUID(suffix: "2"), .connection, .proteus, team: nil, users: [selfUser, userA], name: nil),
            .init(id: UUID(suffix: "1"), .connection, .proteus, team: nil, users: [selfUser, userA], name: nil)
        ])
        _ = try await createConversations([
            // 1:1s with UserB
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userB], name: nil),
            .init(.group, .proteus, team: team, users: [selfUser, userB], name: nil),
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userB], name: nil),
            .init(.connection, .proteus, team: nil, users: [selfUser, userB], name: nil)
        ])

        try await context.perform { [self] in
            // When fetching all types of 1:1 conversations for `userA` with `mls` as a priority
            let result = try XCTUnwrap(
                sut.fetchOneOnOnesWithCandidate(user: userA, types: [.mls, .fake, .proteus, .proteusPending])
            )

            // Then the candidate is the matching 1:1 MLS conversation with the lowest UUID
            let expectedCandidate = userAConversations[1]
            XCTAssertEqual(result.candidate, expectedCandidate)

            // Then the other conversations are all matching conversations minus the candidate.
            let expectedOthers = userAConversations.filter { $0 != expectedCandidate }
            XCTAssertEqual(Set(result.others), Set(expectedOthers))
        }
    }

    func testFetchOneOnOnesWithCandidate_whenConversationsOfSomeTypes() async throws {
        // Given 1:1 conversation of `proteus` and `proteusPending` types
        let conversations = try await createConversations([
            // 1:1 proteus with UserA
            .init(id: UUID(suffix: "4"), .oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil),
            .init(id: UUID(suffix: "3"), .oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil),
            // 1:1 proteus pending UserA
            .init(id: UUID(suffix: "2"), .connection, .proteus, team: nil, users: [selfUser, userA], name: nil),
            .init(id: UUID(suffix: "1"), .connection, .proteus, team: nil, users: [selfUser, userA], name: nil)
        ])

        try await context.perform { [self] in
            // When fetching `all` types of 1:1s with `proteus` given greater priority than `proteusPending`
            let result = try XCTUnwrap(
                sut.fetchOneOnOnesWithCandidate(user: userA, types: [.mls, .fake, .proteus, .proteusPending])
            )

            // Then the candidate is the matching proteus 1:1 with the lowest UUID
            let expectedCandidate = conversations[1]
            XCTAssertEqual(result.candidate, expectedCandidate)

            // Then the other conversations are all matching conversations minus the candidate.
            let expectedOthers = conversations.filter { $0 != expectedCandidate }
            XCTAssertEqual(Set(result.others), Set(expectedOthers))
        }
    }

    func testFetchOneOnOnesWithCandidate_respectsOrderOfTypes() async throws {
        // Given 1:1 conversations of each type
        let conversations = try await createConversations([
            .init(.oneOnOne, .mls, team: nil, users: [selfUser, userA], name: nil), // <- 1:1 MLS with UserA
            .init(.group, .proteus, team: team, users: [selfUser, userA], name: nil), // <- 1:1 proteus fake with UserA
            .init(.oneOnOne, .proteus, team: nil, users: [selfUser, userA], name: nil), // <- 1:1 proteus with UserA
            .init(.connection, .proteus, team: nil, users: [selfUser, userA], name: nil) // <- 1:1 prot. pending UserA
        ])

        let testCases: [(types: [OneOnOneType], expectedCandidate: ZMConversation)] = [
            ([.mls, .fake, .proteus, .proteusPending], expectedCandidate: conversations[0]),
            ([.fake, .proteus, .proteusPending, .mls], expectedCandidate: conversations[1]),
            ([.proteus, .proteusPending, .mls, .fake], expectedCandidate: conversations[2]),
            ([.proteusPending, .mls, .fake, .proteus], expectedCandidate: conversations[3])
        ]

        try await context.perform { [self] in
            for testCase in testCases {
                // When
                let result = try XCTUnwrap(
                    sut.fetchOneOnOnesWithCandidate(user: userA, types: testCase.types)
                )

                // Then
                XCTAssertEqual(result.candidate, testCase.expectedCandidate)
            }
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
    let id: UUID
    let conversationType: ZMConversationType
    let messageProtocol: MessageProtocol
    let team: Team?
    let users: [ZMUser]
    let name: String?

    init(
        id: UUID = .init(),
        _ conversationType: ZMConversationType,
        _ messageProtocol: MessageProtocol,
        team: Team?,
        users: [ZMUser],
        name: String?
    ) {
        self.id = id
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
        conversation.remoteIdentifier = id

        for user in users {
            ParticipantRole.create(managedObjectContext: context, user: user, conversation: conversation)
        }

        return conversation
    }
}

private extension UUID {
    init(suffix: String) {
        var uuidString = "00000000-0000-0000-0000-000000000000"
        let replacementRange = uuidString.index(uuidString.endIndex, offsetBy: -suffix.count) ..< uuidString.endIndex
        uuidString.replaceSubrange(replacementRange, with: suffix)

        self = UUID(uuidString: uuidString)!
    }
}
